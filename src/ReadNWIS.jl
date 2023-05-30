# Functions to go from NWIS URL to data
struct FunctionNotDefinedException <: Exception
    var::String
end

"""
    readNWISdv(siteNumbers, parameterCd;
               startDate="", endDate="", statCd="00003", format="rdb")

Function to obtain daily value data from the NWIS web service.

# Examples
```jldoctest
julia> df, response = readNWISdv("01646500", "00060",
                                 startDate="2010-10-01", endDate="2010-10-01");

julia> df  # df contains the formatted data as a DataFrame
1×5 DataFrame
 Row │ agency_cd  site_no   datetime    68478_00060_00003  68478_00060_00003_c ⋯
     │ String7    String15  String15    String7            String3             ⋯
─────┼──────────────────────────────────────────────────────────────────────────
   1 │ USGS       01646500  2010-10-01  13100              A                   ⋯
                                                                1 column omitted
julia> typeof(response)  # response is the unmodified HTTP GET response object
HTTP.Messages.Response
```
"""
function readNWISdv(siteNumbers, parameterCd;
                    startDate="", endDate="", statCd="00003", format="rdb")
    # construct the query URL
    url = constructNWISURL(
        siteNumbers,
        parameterCd = parameterCd,
        startDate = startDate,
        endDate = endDate,
        service = "dv",
        statCd = statCd,
        format = format,
        expanded = true,
        ratingType = "base",
        statReportType = "daily",
        statType = "mean"
    )
    # use the readNWIS function to query and return the data
    df, response = readNWIS(url)
    return df, response
end

"""
    readNWISpCode(parameterCd)

Function to obtain parameter code information from the NWIS web service.
As currently implemented, support for multiple parameter codes is not included.

# Examples
```jldoctest
julia> df, response = readNWISpCode("00060");

julia> df  # df contains the formatted data as a DataFrame
1×13 DataFrame
 Row │ parameter_cd  group     parm_nm                           epa_equivalen ⋯
     │ String7       String15  String                            String15      ⋯
─────┼──────────────────────────────────────────────────────────────────────────
   1 │ 00060         Physical  Discharge, cubic feet per second  Not checked   ⋯
                                                              10 columns omitted

julia> typeof(response)  # response is the unmodified HTTP GET response object
HTTP.Messages.Response
```
"""
function readNWISpCode(parameterCd)
    # construct the query URL
    url = constructNWISURL(
        "",
        parameterCd = parameterCd,
        startDate = "",
        endDate = "",
        service = "pCode",
        statCd = "",
        format = "rdb",
        expanded = true,
        ratingType = "",
        statReportType = "",
        statType = ""
    )
    # use the readNWIS function to query and return the data
    df, response = readNWIS(url)
    return df, response
end

"""
    readNWISqw(siteNumbers;
               startDate="", endDate="", format="rdb", expanded=true)

Function to obtain water quality data from the NWIS web service.
"""
function readNWISqw(siteNumbers;
                    startDate="", endDate="", format="rdb", expanded=true)
    # throw error as functionality doesn't work yet...
    throw(FunctionNotDefinedException(
        "qwdata service querying functionality has not been developed yet."))
    # construct the query URL
    url = constructNWISURL(
        siteNumbers,
        parameterCd = "",
        startDate = startDate,
        endDate = endDate,
        service = "qw",
        statCd = "",
        format = format,
        expanded = expanded,
        ratingType = "",
        statReportType = "",
        statType = ""
    )
    # use the readNWIS function to query and return the data
    df, response = readNWIS(url)
    return df, response
end

"""
    readNWISqwdata(siteNumbers;
                   startDate="", endDate="", format="rdb", expanded=true)

Alias to `readNWISqw()`.
"""
function readNWISqwdata(siteNumbers;
                        startDate="", endDate="", format="rdb", expanded=true)
    return readNWISqw(siteNumbers;
                      startDate=startDate, endDate=endDate, format=format,
                      expanded=expanded)
end

"""
    readNWISsite(siteNumbers)

Function to obtain site information from the NWIS web service.

# Examples
```jldoctest
julia> df, response = readNWISsite("05114000");

julia> df  # df contains the formatted data as a DataFrame
1×12 DataFrame
 Row │ agency_cd  site_no   station_nm                    site_tp_cd  dec_lat_ ⋯
     │ String7    String15  String31                      String3     String15 ⋯
─────┼──────────────────────────────────────────────────────────────────────────
   1 │ USGS       05114000  SOURIS RIVER NR SHERWOOD, ND  ST          48.99001 ⋯
                                                               8 columns omitted

julia> typeof(response)  # response is the unmodified HTTP GET response object
HTTP.Messages.Response
```
"""
function readNWISsite(siteNumbers)
    # construct the query URL
    url = constructNWISURL(
        siteNumbers,
        parameterCd = "",
        startDate = "",
        endDate = "",
        service = "site",
        statCd = "",
        format = "rdb",
        expanded = true,
        ratingType = "",
        statReportType = "",
        statType = ""
    )
    # use the readNWIS function to query and return the data
    df, response = readNWIS(url)
    return df, response
end

"""
    readNWISunit(siteNumbers, parameterCd;
                 startDate="", endDate="", format="rdb")

Function to obtain instantaneous value data from the NWIS web service.

# Examples
```jldoctest
julia> df, response = readNWISunit("01646500", "00060",
                                   startDate="2022-12-29",
                                   endDate="2022-12-29");

julia> first(df)  # df contains the formatted data as a DataFrame
DataFrameRow
 Row │ agency_cd  site_no   datetime          tz_cd    69928_00060  69928_0006 ⋯
     │ String7    String15  String31          String3  String7      String3    ⋯
─────┼──────────────────────────────────────────────────────────────────────────
   1 │ USGS       01646500  2022-12-29 00:00  EST      12700        P          ⋯
                                                                1 column omitted

julia> typeof(response)  # response is the unmodified HTTP GET response object
HTTP.Messages.Response
```
"""
function readNWISunit(siteNumbers, parameterCd;
                      startDate="", endDate="", format="rdb")
    # construct the query URL
    url = constructNWISURL(
        siteNumbers,
        parameterCd = parameterCd,
        startDate = startDate,
        endDate = endDate,
        service = "uv",
        statCd = "",
        format = format,
        expanded = true,
        ratingType = "",
        statReportType = "",
        statType = ""
    )
    # use the readNWIS function to query and return the data
    df, response = readNWIS(url)
    return df, response
end

"""
    readNWISuv(siteNumbers, parameterCd;
               startDate="", endDate="", format="rdb")

Alias for `readNWISunit()`.
"""
function readNWISuv(siteNumbers, parameterCd;
                    startDate="", endDate="", format="rdb")
    return readNWISunit(siteNumbers, parameterCd;
                        startDate=startDate, endDate=endDate, format=format)
end

"""
    readNWISiv(siteNumbers, parameterCd;
               startDate="", endDate="", format="rdb")

Alias for `readNWISunit()`.
"""
function readNWISiv(siteNumbers, parameterCd;
                    startDate="", endDate="", format="rdb")
    return readNWISunit(siteNumbers, parameterCd;
                        startDate=startDate, endDate=endDate, format=format)
end

"""
    readNWIS(obs_url)

Function to take an NWIS url (typically constructed using the
`constructNWISURL()` function) and return the associated data.
"""
function readNWIS(obs_url)
    # do the API GET query
    response = _custom_get(obs_url)
    # then, depending on the URL, do different things
    if occursin("rdb", obs_url) == true
        df = _readRDB(response)
    elseif occursin("json", obs_url) == true
        df = _readJSON(response)
    elseif occursin("waterml", obs_url) == true
        df = _readWaterML(response)
    else
        # get portion of URL associated with return format
        fmt_str = split(split(obs_url, "format")[2], "&")[1]
        # throw the associated informative error
        throw(ArgumentError(
            "Format, $fmt_str, is not currently recognized or handled by DataRetrieval.jl"
        ))
    end
    return df, response
end

"""
    _readRDB(response)

Private function to parse the API response from an RDB query.

R has additional functionality of being able to specify a timezone when
data is that granular, could add this too.
"""
function _readRDB(response)
    # read the response body into a dataframe
    df = DataFrame(CSV.File(response.body; comment="#"))
    if "datetime" in names(df)
        # filter based on date-time column
        df = filter(:datetime => x -> length(x) >= 10, df)
    elseif "dec_lat_va" in names(df)
        # filter based on some latitude length expectation
        df = filter(:dec_lat_va => x -> length(x) >= 4, df)
    elseif "parameter_cd" in names(df)
        # filter based on some parameter code length expectation
        df = filter(:parameter_cd => x -> length(x) >= 4, df)
    else
        println("no datetime, latitude, or parameter_cd column found, returning all data")
    end
    # return the data frame
    return df
end

"""
    _readWaterML(response)

Private function to parse the response body buffer object from a WaterML query.
"""
function _readWaterML(response)
    # throw error as functionality doesn't work yet...
    throw(FunctionNotDefinedException("WaterML format not yet supported."))

    body = String(response.body)
    # parse xml content
    data = parsexml(body)
    # need to write intelligent code to parse the xml content into a data frame
end

"""
    _readJSON(response)

Private function to parse the response body buffer object from a JSON query.
"""
function _readJSON(response)
    # read JSON
    dict = JSON.parse(String(response.body))

    # get and munge the data into a data frame
    merged_df = DataFrame()

    for timeseries in dict["value"]["timeSeries"]
        site_no = timeseries["sourceInfo"]["siteCode"][1]["value"]
        param_cd = timeseries["variable"]["variableCode"][1]["value"]

        for parameter in timeseries["values"]
            col_name = param_cd
            record_json = parameter["value"]

            if record_json == ""
                continue
            end

            record_df = DataFrame(record_json)

            # assign the site number
            record_df.site_no .= site_no

            # adjust qualifiers to be the string
            record_df.qualifiers .= [join(x, ",") for x in record_df.qualifiers]

            # convert the values to floats
            record_df.value .= [parse(Float64, x) for x in record_df.value]

            # rename the columns
            rename!(record_df, :value => col_name)
            rename!(record_df, :dateTime => :datetime)

            merged_df = vcat(merged_df, record_df)
        end
    end

    # return the data frame
    return merged_df
end