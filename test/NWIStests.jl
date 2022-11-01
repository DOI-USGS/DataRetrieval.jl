# Tests of NWIS functionality

@testset "NWIS URL Construction" begin
    # URLs are generated using the R dataRetrieval package
    # Julia generated URLs are then compared to those results from R
    # Parameters are based on those in the tests_imports.R and the
    # tests_userFriendly_fxns.R scripts from the R dataRetrieval package
    # Order of the query parameters is not important, so their presence is
    # tested by splitting the URLs at the "&" character so the exact logic
    # for the URL construction does not have to match the R implementation

    # single pCode
    siteNumber = "02177000"
    startDate = "2012-09-01"
    endDate = "2012-10-01"
    offering = "00003"
    property = "00060"
    obs_url = constructNWISURL(siteNumber, parameterCd=property,
                               startDate=startDate, endDate=endDate,
                               service="dv", format="rdb")
    exp_url = "https://waterservices.usgs.gov/nwis/dv/?site=02177000&format=rdb,1.0&ParameterCd=00060&StatCd=00003&startDT=2012-09-01&endDT=2012-10-01"
    obs_list = split(obs_url, "&")
    exp_list = split(exp_url, "&")
    for obs in obs_list
        @test obs in exp_list
    end
    for exp in exp_list
        @test exp in obs_list
    end

    # multiple pCodes
    urlMultiPcodes = constructNWISURL("04085427", parameterCd=["00060", "00010"],
                                      startDate=startDate, endDate=endDate,
                                      service="dv",
                                      statCd=["00003", "00001"], format="tsv")
    exp_url = "https://waterservices.usgs.gov/nwis/dv/?site=04085427&format=rdb,1.0&ParameterCd=00060,00010&StatCd=00003,00001&startDT=2012-09-01&endDT=2012-10-01"
    obs_list = split(urlMultiPcodes, "&")
    exp_list = split(exp_url, "&")
    for obs in obs_list
        @test obs in exp_list
    end
    for exp in exp_list
        @test exp in obs_list
    end

    # unit data
    unitDataURL = constructNWISURL(siteNumber, parameterCd=property,
                                   startDate="2013-11-03", endDate="2013-11-03",
                                   service="uv",
                                   format = "tsv")  # includes timezone switch
    exp_url = "https://nwis.waterservices.usgs.gov/nwis/iv/?site=02177000&format=rdb,1.0&ParameterCd=00060&startDT=2013-11-03&endDT=2013-11-03"
    obs_list = split(unitDataURL, "&")
    exp_list = split(exp_url, "&")
    for obs in obs_list
        @test obs in exp_list
    end
    for exp in exp_list
        @test exp in obs_list
    end

    # qw data
    qwURL = constructNWISURL(["04024430", "04024000"],
                             parameterCd=["34247", "30234", "32104", "34220"],
                             startDate="2010-11-03", endDate="",
                             service="qw", format = "rdb")
    exp_url = "https://nwis.waterdata.usgs.gov/nwis/qwdata?multiple_site_no=04024430,04024000&multiple_parameter_cds=34247,30234,32104,34220&param_cd_operator=OR&list_of_search_criteria=multiple_site_no,multiple_parameter_cds&group_key=NONE&sitefile_output_format=html_table&column_name=agency_cd&column_name=site_no&column_name=station_nm&inventory_output=0&rdb_inventory_output=file&TZoutput=0&pm_cd_compare=Greater%20than&radio_parm_cds=previous_parm_cds&qw_attributes=0&format=rdb&rdb_qw_attributes=expanded&date_format=YYYY-MM-DD&rdb_compression=value&qw_sample_wide=0&begin_date=2010-11-03"
    obs_list = split(qwURL, "&")
    exp_list = split(exp_url, "&")
    for obs in obs_list
        @test obs in exp_list
    end
    for exp in exp_list
        @test exp in obs_list
    end

    # bad stat parameter
    site = "05427850"
    url = constructNWISURL(site, parameterCd="00060", startDate="2015-01-01",
                           endDate="", service="dv",
                           format = "tsv", statCd = "laksjd")
    exp_url = "https://waterservices.usgs.gov/nwis/dv/?site=05427850&format=rdb,1.0&ParameterCd=00060&StatCd=laksjd&startDT=2015-01-01"
    obs_list = split(url, "&")
    exp_list = split(exp_url, "&")
    for obs in obs_list
        @test obs in exp_list
    end
    for exp in exp_list
        @test exp in obs_list
    end

    # daily values
    siteNumber = "02177000"
    startDate = "2012-09-01"
    endDate = "2012-10-01"
    offering = "00003"
    property = "00060"
    obs_url = constructNWISURL(siteNumber, parameterCd=property,
                               startDate=startDate, endDate=endDate,
                               service="dv")
    exp_url = "https://waterservices.usgs.gov/nwis/dv/?site=02177000&format=waterml,1.1&ParameterCd=00060&StatCd=00003&startDT=2012-09-01&endDT=2012-10-01"
    obs_list = split(obs_url, "&")
    exp_list = split(exp_url, "&")
    for obs in obs_list
        @test obs in exp_list
    end
    for exp in exp_list
        @test exp in obs_list
    end

    # ground water URL
    groundWaterSite = "431049071324301"
    startGW = "2013-10-01"
    endGW = "2014-06-30"
    groundwaterExampleURL = constructNWISURL(groundWaterSite,
                                             parameterCd="",
                                             startDate=startGW, endDate=endGW,
                                             service = "gwlevels")
    exp_url = "https://waterservices.usgs.gov/nwis/gwlevels/?site=431049071324301&format=waterml&startDT=2013-10-01&endDT=2014-06-30"
    obs_list = split(groundwaterExampleURL, "&")
    exp_list = split(exp_url, "&")
    for obs in obs_list
        @test obs in exp_list
    end
    for exp in exp_list
        @test exp in obs_list
    end

    # two sites and two pcodes
    siteNumber = ["01480015", "04085427"] # one site seems to have lost it"s 2nd dd
    obs_url = constructNWISURL(siteNumber, parameterCd=["00060", "00010"],
                               startDate=startDate, endDate=endDate,
                               service="dv")
    exp_url = "https://waterservices.usgs.gov/nwis/dv/?site=01480015,04085427&format=waterml,1.1&ParameterCd=00060,00010&StatCd=00003&startDT=2012-09-01&endDT=2012-10-01"
    obs_list = split(obs_url, "&")
    exp_list = split(exp_url, "&")
    for obs in obs_list
        @test obs in exp_list
    end
    for exp in exp_list
        @test exp in obs_list
    end

    # inactive site URL
    inactiveSite = "05212700"
    inactiveSite = constructNWISURL(inactiveSite, parameterCd="00060",
                                    startDate="2014-01-01", endDate="2014-01-10",
                                    service="dv")
    exp_url = "https://waterservices.usgs.gov/nwis/dv/?site=05212700&format=waterml,1.1&ParameterCd=00060&StatCd=00003&startDT=2014-01-01&endDT=2014-01-10"
    obs_list = split(inactiveSite, "&")
    exp_list = split(exp_url, "&")
    for obs in obs_list
        @test obs in exp_list
    end
    for exp in exp_list
        @test exp in obs_list
    end

    # combo inactive / active sites
    inactiveAndActive = ["07334200", "05212700"]
    inactiveAndActive = constructNWISURL(inactiveAndActive, parameterCd="00060",
                                         startDate="2014-01-01",
                                        endDate="2014-12-31", service="dv")
    exp_url = "https://waterservices.usgs.gov/nwis/dv/?site=07334200,05212700&format=waterml,1.1&ParameterCd=00060&StatCd=00003&startDT=2014-01-01&endDT=2014-12-31"
    obs_list = split(inactiveAndActive, "&")
    exp_list = split(exp_url, "&")
    for obs in obs_list
        @test obs in exp_list
    end
    for exp in exp_list
        @test exp in obs_list
    end

    # XML URL
    url = constructNWISURL("02319300",
        service = "dv", parameterCd = "00060",
        startDate = "2014-01-01", endDate = "2014-01-01")
    exp_url = "https://waterservices.usgs.gov/nwis/dv/?site=02319300&format=waterml,1.1&ParameterCd=00060&StatCd=00003&startDT=2014-01-01&endDT=2014-01-01"
    obs_list = split(url, "&")
    exp_list = split(exp_url, "&")
    for obs in obs_list
        @test obs in exp_list
    end
    for exp in exp_list
        @test exp in obs_list
    end

    # no data URLs
    url = constructNWISURL("05212700", parameterCd="00060", startDate="2014-01-01",
                           endDate="2014-01-10", service="dv", statCd = "00001")
    exp_url = "https://waterservices.usgs.gov/nwis/dv/?site=05212700&format=waterml,1.1&ParameterCd=00060&StatCd=00001&startDT=2014-01-01&endDT=2014-01-10"
    obs_list = split(url, "&")
    exp_list = split(exp_url, "&")
    for obs in obs_list
        @test obs in exp_list
    end
    for exp in exp_list
        @test exp in obs_list
    end

    url = constructNWISURL(["02319300", "02171500"],
        service = "iv",
        startDate = "2015-04-04", endDate = "2015-04-05")
    exp_url = "https://nwis.waterservices.usgs.gov/nwis/iv/?site=02319300,02171500&format=waterml,1.1&ParameterCd=00060&startDT=2015-04-04&endDT=2015-04-05"
    obs_list = split(url, "&")
    exp_list = split(exp_url, "&")
    for obs in obs_list
        @test obs in exp_list
    end
    for exp in exp_list
        @test exp in obs_list
    end

    # over daylight savings
    tzURL = constructNWISURL(
        "04027000", parameterCd=["00300", "63680"],
        startDate="2011-11-05", endDate="2011-11-07", service="uv")
    exp_url = "https://nwis.waterservices.usgs.gov/nwis/iv/?site=04027000&format=waterml,1.1&ParameterCd=00300,63680&startDT=2011-11-05&endDT=2011-11-07"
    obs_list = split(tzURL, "&")
    exp_list = split(exp_url, "&")
    for obs in obs_list
        @test obs in exp_list
    end
    for exp in exp_list
        @test exp in obs_list
    end

    # daily URL
    siteNumber = "01594440"
    startDate = "1985-01-01"
    endDate = ""
    pCode = ["00060", "00010"]
    url_daily = constructNWISURL(siteNumber, parameterCd=pCode,
      startDate=startDate, endDate=endDate, service="dv",
      statCd = ["00003", "00001"])
    exp_url = "https://waterservices.usgs.gov/nwis/dv/?site=01594440&format=waterml,1.1&ParameterCd=00060,00010&StatCd=00003,00001&startDT=1985-01-01"
    obs_list = split(url_daily, "&")
    exp_list = split(exp_url, "&")
    for obs in obs_list
        @test obs in exp_list
    end
    for exp in exp_list
        @test exp in obs_list
    end

    # unit URL
    url_unit = constructNWISURL(siteNumber, parameterCd=pCode,
        startDate="2012-06-28", endDate="2012-06-30", service="iv")
    exp_url = "https://nwis.waterservices.usgs.gov/nwis/iv/?site=01594440&format=waterml,1.1&ParameterCd=00060,00010&startDT=2012-06-28&endDT=2012-06-30"
    obs_list = split(url_unit, "&")
    exp_list = split(exp_url, "&")
    for obs in obs_list
        @test obs in exp_list
    end
    for exp in exp_list
        @test exp in obs_list
    end

    # URL qw single
    url_qw_single = constructNWISURL(siteNumber, parameterCd="01075",
        startDate=startDate, endDate=endDate, service="qw")
    exp_url = "https://nwis.waterdata.usgs.gov/nwis/qwdata?search_site_no=01594440&search_site_no_match_type=exact&multiple_parameter_cds=01075&param_cd_operator=AND&list_of_search_criteria=search_site_no,multiple_parameter_cds&group_key=NONE&sitefile_output_format=html_table&column_name=agency_cd&column_name=site_no&column_name=station_nm&inventory_output=0&rdb_inventory_output=file&TZoutput=0&pm_cd_compare=Greater%20than&radio_parm_cds=previous_parm_cds&qw_attributes=0&format=rdb&rdb_qw_attributes=expanded&date_format=YYYY-MM-DD&rdb_compression=value&qw_sample_wide=0&begin_date=1985-01-01"
    obs_list = split(url_qw_single, "&")
    exp_list = split(exp_url, "&")
    for obs in obs_list
        @test obs in exp_list
    end
    for exp in exp_list
        @test exp in obs_list
    end

    # URL qw
    url_qw = constructNWISURL(
        siteNumber, parameterCd=["01075", "00029", "00453"],
        startDate=startDate, endDate=endDate, service="qw"
      )
    exp_url = "https://nwis.waterdata.usgs.gov/nwis/qwdata?search_site_no=01594440&search_site_no_match_type=exact&multiple_parameter_cds=01075,00029,00453&param_cd_operator=OR&list_of_search_criteria=search_site_no,multiple_parameter_cds&group_key=NONE&sitefile_output_format=html_table&column_name=agency_cd&column_name=site_no&column_name=station_nm&inventory_output=0&rdb_inventory_output=file&TZoutput=0&pm_cd_compare=Greater%20than&radio_parm_cds=previous_parm_cds&qw_attributes=0&format=rdb&rdb_qw_attributes=expanded&date_format=YYYY-MM-DD&rdb_compression=value&qw_sample_wide=0&begin_date=1985-01-01"
    obs_list = split(url_qw, "&")
    exp_list = split(exp_url, "&")
    for obs in obs_list
        @test obs in exp_list
    end
    for exp in exp_list
        @test exp in obs_list
    end

    # URL daily tsv
    url_daily_tsv = constructNWISURL(siteNumber, parameterCd=pCode,
        startDate=startDate, endDate=endDate, service="dv",
        statCd = ["00003", "00001"], format = "tsv")
    exp_url = "https://waterservices.usgs.gov/nwis/dv/?site=01594440&format=rdb,1.0&ParameterCd=00060,00010&StatCd=00003,00001&startDT=1985-01-01"
    obs_list = split(url_daily_tsv, "&")
    exp_list = split(exp_url, "&")
    for obs in obs_list
        @test obs in exp_list
    end
    for exp in exp_list
        @test exp in obs_list
    end

    # URL rating
    url_rating = constructNWISURL(siteNumber, service = "rating", ratingType = "base")
    exp_url = "https://waterdata.usgs.gov/nwisweb/get_ratings/?site_no=01594440&file_type=base"
    obs_list = split(url_rating, "&")
    exp_list = split(exp_url, "&")
    for obs in obs_list
        @test obs in exp_list
    end
    for exp in exp_list
        @test exp in obs_list
    end

    # URL peak
    url_peak = constructNWISURL(siteNumber, service = "peak")
    exp_url = "https://nwis.waterdata.usgs.gov/usa/nwis/peak/?site_no=01594440&range_selection=date_range&format=rdb"
    obs_list = split(url_peak, "&")
    exp_list = split(exp_url, "&")
    for obs in obs_list
        @test obs in exp_list
    end
    for exp in exp_list
        @test exp in obs_list
    end

    # URL meas
    url_meas = constructNWISURL(siteNumber, service = "meas")
    exp_url = "https://waterdata.usgs.gov/nwis/measurements/?site_no=01594440&range_selection=date_range&format=rdb_expanded"
    obs_list = split(url_meas, "&")
    exp_list = split(exp_url, "&")
    for obs in obs_list
        @test obs in exp_list
    end
    for exp in exp_list
        @test exp in obs_list
    end

    # URL QW
    urlQW = constructNWISURL("450456092225801", parameterCd="70300",
        startDate = "", endDate = "",
        service="qw", expanded = true)
    exp_url = "https://nwis.waterdata.usgs.gov/nwis/qwdata?search_site_no=450456092225801&search_site_no_match_type=exact&multiple_parameter_cds=70300&param_cd_operator=AND&list_of_search_criteria=search_site_no,multiple_parameter_cds&group_key=NONE&sitefile_output_format=html_table&column_name=agency_cd&column_name=site_no&column_name=station_nm&inventory_output=0&rdb_inventory_output=file&TZoutput=0&pm_cd_compare=Greater%20than&radio_parm_cds=previous_parm_cds&qw_attributes=0&format=rdb&rdb_qw_attributes=expanded&date_format=YYYY-MM-DD&rdb_compression=value&qw_sample_wide=0"
    obs_list = split(urlQW, "&")
    exp_list = split(exp_url, "&")
    for obs in obs_list
        @test obs in exp_list
    end
    for exp in exp_list
        @test exp in obs_list
    end

    # URL QW
    urlQW = constructNWISURL("450456092225801", parameterCd="70300",
        startDate = "", endDate = "", service="qw", expanded = true)
    exp_url = "https://nwis.waterdata.usgs.gov/nwis/qwdata?search_site_no=450456092225801&search_site_no_match_type=exact&multiple_parameter_cds=70300&param_cd_operator=AND&list_of_search_criteria=search_site_no,multiple_parameter_cds&group_key=NONE&sitefile_output_format=html_table&column_name=agency_cd&column_name=site_no&column_name=station_nm&inventory_output=0&rdb_inventory_output=file&TZoutput=0&pm_cd_compare=Greater%20than&radio_parm_cds=previous_parm_cds&qw_attributes=0&format=rdb&rdb_qw_attributes=expanded&date_format=YYYY-MM-DD&rdb_compression=value&qw_sample_wide=0"
    obs_list = split(urlQW, "&")
    exp_list = split(exp_url, "&")
    for obs in obs_list
        @test obs in exp_list
    end
    for exp in exp_list
        @test exp in obs_list
    end

    # URL QW
    urlQW = constructNWISURL("450456092225801", parameterCd="70300",
        startDate = "",
        endDate = "", service="qw", expanded = true)
    exp_url = "https://nwis.waterdata.usgs.gov/nwis/qwdata?search_site_no=450456092225801&search_site_no_match_type=exact&multiple_parameter_cds=70300&param_cd_operator=AND&list_of_search_criteria=search_site_no,multiple_parameter_cds&group_key=NONE&sitefile_output_format=html_table&column_name=agency_cd&column_name=site_no&column_name=station_nm&inventory_output=0&rdb_inventory_output=file&TZoutput=0&pm_cd_compare=Greater%20than&radio_parm_cds=previous_parm_cds&qw_attributes=0&format=rdb&rdb_qw_attributes=expanded&date_format=YYYY-MM-DD&rdb_compression=value&qw_sample_wide=0"
    obs_list = split(urlQW, "&")
    exp_list = split(exp_url, "&")
    for obs in obs_list
        @test obs in exp_list
    end
    for exp in exp_list
        @test exp in obs_list
    end

    # URL QW
    urlQW = constructNWISURL("450456092225801", parameterCd="70300",
        startDate = "",
        endDate = "", service="qw", expanded = true)
    exp_url = "https://nwis.waterdata.usgs.gov/nwis/qwdata?search_site_no=450456092225801&search_site_no_match_type=exact&multiple_parameter_cds=70300&param_cd_operator=AND&list_of_search_criteria=search_site_no,multiple_parameter_cds&group_key=NONE&sitefile_output_format=html_table&column_name=agency_cd&column_name=site_no&column_name=station_nm&inventory_output=0&rdb_inventory_output=file&TZoutput=0&pm_cd_compare=Greater%20than&radio_parm_cds=previous_parm_cds&qw_attributes=0&format=rdb&rdb_qw_attributes=expanded&date_format=YYYY-MM-DD&rdb_compression=value&qw_sample_wide=0"
    obs_list = split(urlQW, "&")
    exp_list = split(exp_url, "&")
    for obs in obs_list
        @test obs in exp_list
    end
    for exp in exp_list
        @test exp in obs_list
    end
end
