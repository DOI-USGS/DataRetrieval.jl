# Functions to go from NWIS URL to data
using Infiltrator
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
    response_body = IOBuffer(String(response.body))
    # then, depending on the URL, do different things
    if occursin("rdb", obs_url) == true
        df = _readRDB(response_body)
    elseif occursin("waterml", obs_url) == true
        df = _readWaterML(response_body)
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
    _readRDB(response_body)

Private function to parse the response body buffer object from an RDB query.
"""
function _readRDB(response_body)
    # init header and content
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
function _readWaterML(response_body)
    throw(FunctionNotDefinedException("Method not developed yet."))
end