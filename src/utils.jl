# Utility functions used across the package

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
    baseurl = getbaseURL(service)
    # if sitenumbers is a list or vector > 0, make comma-separated string
    site_txt = "site"
    if (typeof(siteNumbers) != String) & (length(siteNumbers) > 0)
        siteNumbers = join(siteNumbers, ',')
        if service == "qwdata"
            site_txt = "multiple_site_no"
        end
    end
    # same for parameterCd or statCd
    param_txt = "ParameterCd"
    if (typeof(parameterCd) != String) & (length(parameterCd) > 0)
        parameterCd = join(parameterCd, ',')
        if service == "qwdata"
            param_txt = "multiple_parameter_cds"
        end
    end
    if (typeof(statCd) != String) & (length(statCd) > 0)
        statCd = join(statCd, ',')
    end
    # append site numbers to the URL - ducktyping the siteNumbers now
    url = string(baseurl, "?$site_txt=$siteNumbers")
    # append parameter code
    if length(parameterCd) > 0
        url = string(url, "&$param_txt=$parameterCd")
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
    format = reformat_format(format, service)
    url = string(url, "&format=$format")
    # add the stat code
    if service == "dv"
        url = string(url, "&StatCd=$statCd")
    end
    # add qwdata information
    if service == "qwdata"
        url = qwdata_url(url)
    end
    # return this URL
    return(url)
end

"""
    getbaseURL(service)

Function to get the base URL string based on the service being queried.
"""
function getbaseURL(service)
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
    reformat_format(format, service)

Function to reformat the format string based on the service queried
"""
function reformat_format(format, service)
    if format == "xml"
        if service == "gwlevels"
            format = "waterml"
        else
            format = "waterml,1.1"
        end
    end

    if format == "rdb"
        if service == "gwlevels"
            format = "rdb,3.0"
        elseif service == "qwdata"
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

    return(format)
end

"""
    query(url, parameters)

Performs an API query given a URL and a struct of query parameters.
"""
function query(url, parameters)
    # want to write more sophisticated try/except with some error passing
    # and additional information/functionality

    # need to read docstring for HTTP.get to handle the parameters
    response = HTTP.get(url, parameters)

    # return the parsed JSON body (probably also want header & meta info)
    return(JSON.parse(String(response.body)))
end

"""
    qwdata_url(url)

Function to add additional information for the qwdata query.
"""
function qwdata_url(url)
    param_list = [
        "param_cd_operator=OR",
        "list_of_search_criteria=multiple_site_no,multiple_parameter_cds",
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

    return(url)
end