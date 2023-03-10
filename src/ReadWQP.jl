# Functions to go from WQP URLs to data
"""
    readWQPdata(service; kwargs...)

Flexible querying of the WQP. See other functions for specific queries.

# Examples
```jldoctest
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
function readWQPdata(service; kwargs...)
    df, response = _genericWQPcall(service, Dict(kwargs...))
    # return the data frame
    return df, response
end

"""
    readWQPresults(; kwargs...)

Query the WQP for results.

# Examples
```jldoctest
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
function readWQPresults(; kwargs...)
    df, response = _genericWQPcall("Result", Dict(kwargs...))
    # return the data frame
    return df, response
end

"""
    whatWQPsites(; kwargs...)

Function to search WQP for sites within a region with specific data.

# Examples
```jldoctest
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
function whatWQPsites(; kwargs...)
    df, response = _genericWQPcall("Station", Dict(kwargs...))
    # return the data frame
    return df, response
end

"""
    whatWQPorganizations(; kwargs...)

Function to search WQP for organizations within a region with specific data.

# Examples
```jldoctest
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
function whatWQPorganizations(; kwargs...)
    df, response = _genericWQPcall("Organization", Dict(kwargs...))
    # return the data frame
    return df, response
end

"""
    whatWQPprojects(; kwargs...)

Function to search WQP for projects within a region with specific data.

# Examples
```jldoctest
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
function whatWQPprojects(; kwargs...)
    df, response = _genericWQPcall("Project", Dict(kwargs...))
    # return the data frame
    return df, response
end

"""
    whatWQPactivities(; kwargs...)

Function to search WQP for activities within a region with specific data.

# Examples
```jldoctest
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
function whatWQPactivities(; kwargs...)
    df, response = _genericWQPcall("Activity", Dict(kwargs...))
    # return the data frame
    return df, response
end

"""
    whatWQPdetectionLimits(; kwargs...)

Function to search WQP for detection limits within a region with specific data.

# Examples
```jldoctest
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
function whatWQPdetectionLimits(; kwargs...)
    df, response = _genericWQPcall("ResultDetectionQuantitationLimit",
                                   Dict(kwargs...))
    # return the data frame
    return df, response
end

"""
    whatWQPhabitatMetrics(; kwargs...)

Function to search WQP for habitat metrics within a region with specific data.

# Examples
```jldoctest
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
function whatWQPhabitatMetrics(; kwargs...)
    df, response = _genericWQPcall("BiologicalMetric", Dict(kwargs...))
    # return the data frame
    return df, response
end

"""
    whatWQPprojectWeights(; kwargs...)

Function to search WQP for project weights within a region with specific data.

# Examples
```jldoctest
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
function whatWQPprojectWeights(; kwargs...)
    df, response = _genericWQPcall("ProjectMonitoringLocationWeighting",
                                   Dict(kwargs...))
    # return the data frame
    return df, response
end

"""
    whatWQPactivityMetrics(; kwargs...)

Function to search WQP for activity metrics within a region with specific data.

# Examples
```jldoctest
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
function whatWQPactivityMetrics(; kwargs...)
    df, response = _genericWQPcall("ActivityMetric", Dict(kwargs...))
    # return the data frame
    return df, response
end

"""
    _generic_call(service; kwargs...)

Private function to be called by the other wrapper WQP functions.
"""
function _genericWQPcall(service, query_params)
    # construct the base query URL
    url = constructWQPURL(service)
    # do the GET request
    response = _custom_get(url, query_params=query_params)
    # parse the Response
    df = DataFrame(CSV.File(response.body))
    # return the data frame
    return df, response
end
