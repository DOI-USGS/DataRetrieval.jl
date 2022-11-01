# Functions to go from NWIS URL to data
struct FunctionNotDefinedException <: Exception
    var::String
end

"""
    readNWIS(obs_url)

Function to take an NWIS url (typically constructed using the
constructNWISURL() function) and return the associated data.
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
    return(df)
end

"""
    _readRDB(response)

Private function to parse the API response from an RDB query.

Consider padding site number rather than allowing it to be an integer that
loses the preceeding 0s. R version returns site number as string w/ the full
8 digits included preceding 0s. Need to resolve the column names as well,
should be able to read them from the header information somehow.
R has additional functionality of being able to specify a timezone when
data is that granular, could add this too.
"""
function _readRDB(response)
    response_body = IOBuffer(String(response.body))
    # init header
    header = String[]
    # loop through lines and populate header and content
    for line in eachline(response_body)
        startswith(line, "#") ? push!(header, line) : break
    end
    # put content in data frame
    df = DataFrame(CSV.File(response_body))
    # add header information to data frame
    metadata!(df, "header", join(header), style=:note)
    # return the data frame
    return(df)
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