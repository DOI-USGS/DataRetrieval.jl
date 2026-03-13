# Functions to go from WQP URLs to data
"""
    readWQPdata(service; kwargs...)

Flexible querying of the WQP. See other functions for specific queries.

# Arguments
- `service::String`: The WQP service to query. One of "Result", "Station",
  "Organization", "Project", "Activity", "ResultDetectionQuantitationLimit",
  "BiologicalMetric", "ProjectMonitoringLocationWeighting", or
  "ActivityMetric".

# Keyword Arguments
- `siteid::String`: Concatenate an agency code, a hyphen ("-"), and a
  site-identification number.
- `statecode::String`: State code to search within. Concatenate 'US', a
  colon (":"), and a FIPS numeric code (Example: Illinois is US:17).
- `countycode::String`: FIPS county code to search within.
- `huc::String`: One or more eight-digit HUC codes, delimited by semicolons.
- `bBox::String`: Bounding box to search within. Format is
  "minx,miny,maxx,maxy" (Example: bBox="-92.8,44.2,-88.9,46.0").
- `lat::String`: Latitude for radial search in decimal degrees, WGS84.
- `long::String`: Longitude for radial search in decimal degrees, WGS84.
- `within::String`: Distance for radial search in decimal miles.
- `pCode::String`: One or more five-digit USGS parameter codes, delimited by
  semicolons.
- `startDateLo::String`: Start date for search in MM-DD-YYYY format.
- `startDateHi::String`: End date for search in MM-DD-YYYY format.
- `characteristicName::String`: One or more characteristic names, delimited by
  semicolons. (See https://www.waterqualitydata.us/public_srsnames/
  for available characteristic names).

# Examples
```julia
julia> df, response = readWQPdata("Result",
                                  lat="44.2", long="-88.9", within="0.5");

julia> first(df)[1:3]
DataFrameRow
 Row │ OrganizationIdentifier  OrganizationFormalName             ActivityIdentifier
     │ InlineStrings.String15  String                             String31
─────┼───────────────────────────────────────────────────────────────────────────────
   1 │ WIDNR_WQX               Wisconsin Department of Natural …  WIDNR_WQX-35940585

julia> typeof(response)  # response is the unmodified HTTP GET response object
HTTP.Messages.Response
```
"""
function readWQPdata(service; legacy=true, ssl_check=true, kwargs...)
    df, response = _genericWQPcall(service, Dict(kwargs...); legacy=legacy, ssl_check=ssl_check)
    # return the data frame
    return df, response
end

"""
    readWQPresults(; kwargs...)

Query the WQP for results.

# Examples
```julia
julia> df, response = readWQPresults(lat="44.2", long="-88.9", within="0.5");

julia> first(df)[1:3]
DataFrameRow
 Row │ OrganizationIdentifier  OrganizationFormalName             ActivityIdentifier
     │ InlineStrings.String15  String                             String31
─────┼───────────────────────────────────────────────────────────────────────────────
   1 │ WIDNR_WQX               Wisconsin Department of Natural …  WIDNR_WQX-35940585

julia> typeof(response)  # response is the unmodified HTTP GET response object
HTTP.Messages.Response
```
"""
function readWQPresults(; legacy=true, ssl_check=true, kwargs...)
    df, response = _genericWQPcall("Result", Dict(kwargs...); legacy=legacy, ssl_check=ssl_check)
    # return the data frame
    return df, response
end

"""
    whatWQPsites(; kwargs...)

Function to search WQP for sites within a region with specific data.

# Examples
```julia
julia> df, response = whatWQPsites(lat="44.2", long="-88.9", within="2.5");

julia> first(df)[1:3]
DataFrameRow
 Row │ OrganizationIdentifier  OrganizationFormalName             MonitoringLocationIdentifier
     │ InlineStrings.String15  String                             InlineStrings.String31
─────┼─────────────────────────────────────────────────────────────────────────────────────────
   1 │ USGS-WI                 USGS Wisconsin Water Science Cen…  USGS-441159088505801

julia> typeof(response)  # response is the unmodified HTTP GET response object
HTTP.Messages.Response
```
"""
function whatWQPsites(; legacy=true, ssl_check=true, kwargs...)
    df, response = _genericWQPcall("Station", Dict(kwargs...); legacy=legacy, ssl_check=ssl_check)
    # return the data frame
    return df, response
end

"""
    whatWQPorganizations(; kwargs...)

Function to search WQP for organizations within a region with specific data.

# Examples
```julia
julia> df, response = whatWQPorganizations(huc="12");

julia> first(df)[1:3]
DataFrameRow
 Row │ OrganizationIdentifier  OrganizationFormalName         OrganizationDescriptionText
     │ InlineStrings.String31  String                         Union{Missing, String}
─────┼────────────────────────────────────────────────────────────────────────────────────
   1 │ ARS                     Agricultural Research Service  missing

julia> typeof(response)  # response is the unmodified HTTP GET response object
HTTP.Messages.Response
```
"""
function whatWQPorganizations(; legacy=true, ssl_check=true, kwargs...)
    df, response = _genericWQPcall("Organization", Dict(kwargs...); legacy=legacy, ssl_check=ssl_check)
    # return the data frame
    return df, response
end

"""
    whatWQPprojects(; kwargs...)

Function to search WQP for projects within a region with specific data.

# Examples
```julia
julia> df, response = whatWQPprojects(huc="19");

julia> first(df)[1:3]
DataFrameRow
 Row │ OrganizationIdentifier  OrganizationFormalName             ProjectIdentifier
     │ InlineStrings.String31  String                             String
─────┼──────────────────────────────────────────────────────────────────────────────
   1 │ 21AKBCH                 Alaska Department of Environment…  AK164406

julia> typeof(response)  # response is the unmodified HTTP GET response object
HTTP.Messages.Response
```
"""
function whatWQPprojects(; legacy=true, ssl_check=true, kwargs...)
    df, response = _genericWQPcall("Project", Dict(kwargs...); legacy=legacy, ssl_check=ssl_check)
    # return the data frame
    return df, response
end

"""
    whatWQPactivities(; kwargs...)

Function to search WQP for activities within a region with specific data.

# Examples
```julia
julia> df, response = whatWQPactivities(statecode="US:11",
                                        startDateLo="12-30-2019",
                                        startDateHi="01-01-2020");

julia> first(df)[1:3]
DataFrameRow
 Row │ OrganizationIdentifier  OrganizationFormalName             ActivityIdentifier
     │ InlineStrings.String7   String                             String31
─────┼───────────────────────────────────────────────────────────────────────────────
   1 │ USGS-MD                 USGS Maryland Water Science Cent…  nwismd.01.02000322

julia> typeof(response)  # response is the unmodified HTTP GET response object
HTTP.Messages.Response
```
"""
function whatWQPactivities(; legacy=true, ssl_check=true, kwargs...)
    df, response = _genericWQPcall("Activity", Dict(kwargs...); legacy=legacy, ssl_check=ssl_check)
    # return the data frame
    return df, response
end

"""
    whatWQPdetectionLimits(; kwargs...)

Function to search WQP for detection limits within a region with specific data.

# Examples
```julia
julia> df, response = whatWQPdetectionLimits(statecode="US:44",
                                             characteristicName="Nitrite",
                                             startDateLo="01-01-2021",
                                             startDateHi="02-20-2021");

julia> first(df)[1:3]
DataFrameRow
 Row │ OrganizationIdentifier  OrganizationFormalName             ActivityIdentifier
     │ InlineStrings.String7   String                             String31
─────┼───────────────────────────────────────────────────────────────────────────────
   1 │ USGS-MA                 USGS Massachusetts Water Science…  nwisma.01.02100548

julia> typeof(response)  # response is the unmodified HTTP GET response object
HTTP.Messages.Response
```
"""
function whatWQPdetectionLimits(; legacy=true, ssl_check=true, kwargs...)
    df, response = _genericWQPcall("ResultDetectionQuantitationLimit",
                                   Dict(kwargs...); legacy=legacy, ssl_check=ssl_check)
    # return the data frame
    return df, response
end

"""
    whatWQPhabitatMetrics(; kwargs...)

Function to search WQP for habitat metrics within a region with specific data.

# Examples
```julia
julia> df, response = whatWQPhabitatMetrics(statecode="US:44");

julia> first(df)[1:3]
DataFrameRow
 Row │ OrganizationIdentifier  MonitoringLocationIdentifier  IndexIdentifier
     │ InlineStrings.String15  InlineStrings.String31        String
─────┼───────────────────────────────────────────────────────────────────────────────
   1 │ NARS_WQX                NARS_WQX-NEWS04-4201          PH:NEWS04-4201:1:BKA_Q3

julia> typeof(response)  # response is the unmodified HTTP GET response object
HTTP.Messages.Response
```
"""
function whatWQPhabitatMetrics(; legacy=true, ssl_check=true, kwargs...)
    df, response = _genericWQPcall("BiologicalMetric", Dict(kwargs...); legacy=legacy, ssl_check=ssl_check)
    # return the data frame
    return df, response
end

"""
    whatWQPprojectWeights(; kwargs...)

Function to search WQP for project weights within a region with specific data.

# Examples
```julia
julia> df, response = whatWQPprojectWeights(statecode="US:38",
                                            startDateLo="01-01-2006",
                                            startDateHi="01-01-2008");

julia> first(df)[1:3]
DataFrameRow
 Row │ OrganizationIdentifier  OrganizationFormalName             ProjectIdentifier
     │ InlineStrings.String15  String                             String31
─────┼───────────────────────────────────────────────────────────────────────────────────────
   1 │ NARS_WQX                EPA National Aquatic Resources S…  NARS_NLA2007_ECOREGION_NPL

julia> typeof(response)  # response is the unmodified HTTP GET response object
HTTP.Messages.Response
```
"""
function whatWQPprojectWeights(; legacy=true, ssl_check=true, kwargs...)
    df, response = _genericWQPcall("ProjectMonitoringLocationWeighting",
                                   Dict(kwargs...); legacy=legacy, ssl_check=ssl_check)
    # return the data frame
    return df, response
end

"""
    whatWQPactivityMetrics(; kwargs...)

Function to search WQP for activity metrics within a region with specific data.

# Examples
```julia
julia> df, response = whatWQPactivityMetrics(statecode="US:38",
                                             startDateLo="07-01-2006",
                                             startDateHi="12-01-2006");

julia> first(df)[1:3]
DataFrameRow
 Row │ OrganizationIdentifier  OrganizationFormalName        MonitoringLocationIdentifier
     │ InlineStrings.String15  InlineStrings.String31        InlineStrings.String31
─────┼────────────────────────────────────────────────────────────────────────────────────
   1 │ EMAP_GRE                EMAP-Great Rivers Ecosystems  EMAP_GRE-GRE06604-1268

julia> typeof(response)  # response is the unmodified HTTP GET response object
HTTP.Messages.Response
```
"""
function whatWQPactivityMetrics(; legacy=true, ssl_check=true, kwargs...)
    df, response = _genericWQPcall("ActivityMetric", Dict(kwargs...); legacy=legacy, ssl_check=ssl_check)
    # return the data frame
    return df, response
end

"""
    _generic_call(service; kwargs...)

Private function to be called by the other wrapper WQP functions.
"""
function _genericWQPcall(service, query_params; legacy=true, ssl_check=true)
    normalized_query = Dict{String, Any}()
    for (k, v) in query_params
        normalized_query[String(k)] = v
    end

    if haskey(normalized_query, "mimeType")
        mime = lowercase(String(normalized_query["mimeType"]))
        if mime == "geojson"
            throw(ArgumentError("GeoJSON is not yet supported. Set mimeType=csv."))
        elseif mime != "csv"
            throw(ArgumentError("Invalid mimeType. Set mimeType=csv."))
        end
    end
    normalized_query["mimeType"] = "csv"

    # construct the base query URL
    url = constructWQPURL(service; legacy=legacy)
    # do the GET request
    response = _custom_get(url, query_params=normalized_query, ssl_check=ssl_check)
    # parse the Response
    content_type = HTTP.header(response, "Content-Type", "")
    if occursin("text/html", content_type)
        throw(ArgumentError("Received an HTML response instead of CSV data from WQP. This typically indicates an error page or a service issue."))
    end
    df = DataFrame(CSV.File(response.body; comment="#", ignoreemptyrows=true))
    # return the data frame
    return df, response
end
