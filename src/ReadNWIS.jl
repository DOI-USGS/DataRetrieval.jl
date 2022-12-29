# Functions to go from NWIS URL to data
using Infiltrator

struct FunctionNotDefinedException <: Exception
    var::String
end

"""
    readNWISdv(siteNumbers, parameterCd;
               startDate="", endDate="", statCd="00003")

Function to obtain daily value data from the NWIS web service.
"""
function readNWISdv(siteNumbers, parameterCd;
                    startDate="", endDate="", statCd="00003")
    # construct the query URL
    url = constructNWISURL(
        siteNumbers,
        parameterCd = parameterCd,
        startDate = startDate,
        endDate = endDate,
        service = "dv",
        statCd = statCd,
        format = "rdb",
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
    readNWIS(obs_url)

Function to take an NWIS url (typically constructed using the
`constructNWISURL()` function) and return the associated data.
"""
function readNWIS(obs_url)
    # do the API GET query
    response = HTTP.get(obs_url)
    # then, depending on the URL, do different things
    if occursin("rdb", obs_url) == true
        df = _readRDB(response)
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
    # filter based on date-time column
    df = filter(:datetime => x -> length(x) >= 10, df)
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