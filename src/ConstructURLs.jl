# Functions for constructing URLs to do API queries

"""
    constructNWISURL(siteNumbers; parameterCd="00060",
        startDate="", endDate="", service="site", statCd="00003",
        format="xml", expanded=True, ratingType="base", statReportType="daily",
        statType="mean")

Construct a URL to be used to make an API query to the NWIS service.
"""
function constructNWISURL(siteNumbers;
                          parameterCd="00060",
                          startDate="",
                          endDate="",
                          service="site",
                          statCd="00003",
                          format="xml",
                          expanded=true,
                          ratingType="base",
                          statReportType="daily",
                          statType="mean")
    # define the base NWIS url that is used for the query
    # first handle/substitute some alternative names
    if service == "qw" service = "qwdata" end
    if service == "meas" service = "measurements" end
    if service == "uv" service = "iv" end
    # pCode handling
    if service == "pCode"
        if typeof(parameterCd) == Vector{String} && length(parameterCd) == 1
            service = "pCodeSingle"
        elseif typeof(parameterCd) == String
            service = "pCodeSingle"
        else
            service = "pCode"
        end
    end
    # get the base URL for the query
    baseurl = _getbaseURL(service)
    # if sitenumbers is a list or vector > 0, make comma-separated string
    site_txt = "site"
    if (typeof(siteNumbers) != String) & (length(siteNumbers) > 0)
        siteNumbers = join(siteNumbers, ',')
        if service == "qwdata"
            site_txt = "multiple_site_no"
        end
    elseif (service == "qwdata") & (typeof(siteNumbers) == String)
        site_txt = "search_site_no"
    elseif (service == "measurements") || (service == "peak") || (service == "rating")
        site_txt = "site_no"
    end
    # same for parameterCd or statCd
    param_txt = "ParameterCd"
    multiple_parameters = false
    if (typeof(parameterCd) != String) & (length(parameterCd) > 0)
        parameterCd = join(parameterCd, ',')
        multiple_parameters = true
    end
    if service == "qwdata"
        param_txt = "multiple_parameter_cds"
    end
    if service == "pCode" || service == "pCodeSingle"
        param_txt = "parm_nm_cd"
    end
    if (typeof(statCd) != String) & (length(statCd) > 0)
        statCd = join(statCd, ',')
    end
    if (service in ["pCode", "pCodeSingle"]) == false
        # append site numbers to the URL - ducktyping the siteNumbers now
        url = string(baseurl, "?$site_txt=$siteNumbers")
    end
    # append parameter code
    if (length(parameterCd) > 0) && ((service in ["measurements", "peak", "rating", "pCode", "pCodeSingle"]) == false)
        url = string(url, "&$param_txt=$parameterCd")
    elseif service in ["pCode", "pCodeSingle"]
        url = string(baseurl, "?$param_txt=$parameterCd")
    end
    # append start/end dates
    if length(startDate) > 0
        if service == "qwdata"
            url = string(url, "&begin_date=$startDate")
        else
            url = string(url, "&startDT=$startDate")
        end
    end
    if length(endDate) > 0
        if service == "qwdata"
            url = string(url, "&end_date=$endDate")
        else
            url = string(url, "&endDT=$endDate")
        end
    end
    # append the format
    format = _reformat_format(format, service, expanded)
    if (service in ["rating", "pCode", "pCodeSingle"]) == false
        url = string(url, "&format=$format")
    elseif service in ["pCode", "pCodeSingle"]
        url = string(url, "&fmt=$format")
    end
    # add the stat code
    if service == "dv"
        url = string(url, "&StatCd=$statCd")
    end
    # add qwdata information
    if service == "qwdata"
        url = _qwdata_url(url, site_txt, multiple_parameters)
    end
    # if peak data add "date_range"
    if (service == "peak") || (service == "measurements")
        url = string(url, "&range_selection=date_range")
    end
    # if rating data add type
    if service == "rating"
        url = string(url, "&file_type=$ratingType")
    end
    # return this URL
    return(url)
end

"""
    _getbaseURL(service)

Function to get the base URL string based on the service being queried.
"""
function _getbaseURL(service)
    # create dict with all base URLs
    baseURLs = Dict([
        ("site", "https://waterservices.usgs.gov/nwis/site/"),
        ("iv", "https://nwis.waterservices.usgs.gov/nwis/iv/"),
        ("dv", "https://waterservices.usgs.gov/nwis/dv/"),
        ("gwlevels", "https://waterservices.usgs.gov/nwis/gwlevels/"),
        ("measurements", "https://waterdata.usgs.gov/nwis/measurements/"),
        ("peak", "https://nwis.waterdata.usgs.gov/usa/nwis/peak/"),
        ("rating", "https://waterdata.usgs.gov/nwisweb/get_ratings/"),
        ("qwdata", "https://nwis.waterdata.usgs.gov/nwis/qwdata"),
        ("stat", "https://waterservices.usgs.gov/nwis/stat/"),
        ("useNat", "https://waterdata.usgs.gov/nwis/water_use"),
        ("pCode", "https://help.waterdata.usgs.gov/code/parameter_cd_query"),
        ("pCodeSingle", "https://help.waterdata.usgs.gov/code/parameter_cd_nm_query"),
        ("Result", "https://www.waterqualitydata.us/data/Result/search"),
        ("Station", "https://www.waterqualitydata.us/data/Station/search"),
        ("Activity", "https://www.waterqualitydata.us/data/Activity/search"),
        ("ActivityMetric", "https://www.waterqualitydata.us/data/ActivityMetric/search"),
        ("SiteSummary", "https://www.waterqualitydata.us/data/summary/monitoringLocation/search"),
        ("Project", "https://www.waterqualitydata.us/data/Project/search"),
        ("ProjectMonitoringLocationWeighting", "https://www.waterqualitydata.us/data/ProjectMonitoringLocationWeighting/search"),
        ("ResultDetectionQuantitationLimit", "https://www.waterqualitydata.us/data/ResultDetectionQuantitationLimit/search"),
        ("BiologicalMetric", "https://www.waterqualitydata.us/data/BiologicalMetric/search"),
        ("Organization", "https://www.waterqualitydata.us/data/Organization/search"),
        ("NGWMN", "https://cida.usgs.gov/ngwmn_cache/sos"),
    ])

    # get relevant URL and return it
    return(baseURLs[service])
end

"""
    _reformat_format(format, service)

Function to reformat the format string based on the service queried
"""
function _reformat_format(format, service, expanded)
    if format == "xml"
        if service == "gwlevels"
            format = "waterml"
        elseif service == "peak"
            format = "rdb"
        else
            format = "waterml,1.1"
        end
    end

    if (format == "rdb") && (service != "peak")
        if service == "gwlevels"
            format = "rdb,3.0"
        elseif service in ["pCode", "pCodeSingle"]
            format = "rdb"
        else
            format = "rdb,1.0"
        end
    end

    if format == "tsv"
        if service == "gwlevels"
            format = "rdb"
        else
            format = "rdb,1.0"
        end
    end

    if format == "wml1"
        if service == "gwlevels"
            format = "waterml"
        else
            format = "waterml,1.1"
        end
    end

    if service == "qwdata"
        format = "rdb"
    end

    if (service == "measurements") & (expanded == true)
        format = "rdb_expanded"
    end

    return(format)
end

"""
    _qwdata_url(url)

Function to add additional information for the qwdata query.
"""
function _qwdata_url(url, site_txt, multiple_parameters)
    param_list = [
        "group_key=NONE",
        "sitefile_output_format=html_table",
        "column_name=agency_cd",
        "column_name=site_no",
        "column_name=station_nm",
        "inventory_output=0",
        "rdb_inventory_output=file",
        "TZoutput=0",
        "pm_cd_compare=Greater%20than",
        "radio_parm_cds=previous_parm_cds",
        "qw_attributes=0",
        "rdb_qw_attributes=expanded",
        "date_format=YYYY-MM-DD",
        "rdb_compression=value",
        "qw_sample_wide=0"
    ]
    param_txt = join(param_list, "&")
    add_str = string("&", param_txt)
    url = string(url, add_str)

    search_criteria_txt = "&list_of_search_criteria=multiple_site_no,multiple_parameter_cds"
    param_op_txt = "&param_cd_operator=AND"

    if site_txt == "search_site_no"
        url = string(url, "&search_site_no_match_type=exact")
        search_criteria_txt = "&list_of_search_criteria=search_site_no,multiple_parameter_cds"
    end

    if multiple_parameters == true
        param_op_txt = "&param_cd_operator=OR"
    end

    url = string(url, search_criteria_txt)
    url = string(url, param_op_txt)

    return(url)
end

"""
    constructWQPURL(service)

Function to construct the URL for the WQP service.
"""
function constructWQPURL(service)
    # get base URL
    url = _getbaseURL(service)
    # add ?
    url = string(url, "?")
    # return this URL
    return(url)
end
