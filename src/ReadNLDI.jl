# Functions for querying the USGS NLDI API

const NLDI_API_BASE_URL = "https://api.water.usgs.gov/nldi/linked-data"
const _NLDI_CRS = "EPSG:4326"
const _NLDI_AVAILABLE_DATA_SOURCES = Ref{Union{Nothing, Vector{String}}}(nothing)

function _query_nldi(url, query_params, error_message)
    response = try
        _custom_get(url; query_params=query_params)
    catch e
        if e isa HTTP.Exceptions.StatusError
            throw(ArgumentError("$error_message. Error reason: $(e.status)"))
        end
        rethrow(e)
    end

    data = Dict{String, Any}()
    try
        data = JSON.parse(String(response.body))
    catch
        data = Dict{String, Any}()
    end

    return data, response
end

function _validate_navigation_mode(navigation_mode)
    mode = uppercase(String(navigation_mode))
    if (mode in ["UM", "DM", "UT", "DD"]) == false
        throw(ArgumentError("Invalid navigation mode '$navigation_mode'"))
    end
end

function _validate_feature_source_comid(feature_source, feature_id, comid)
    if (feature_source !== nothing) && (feature_id === nothing)
        throw(ArgumentError("feature_id is required if feature_source is provided"))
    end
    if (feature_id !== nothing) && (feature_source === nothing)
        throw(ArgumentError("feature_source is required if feature_id is provided"))
    end
    if (comid !== nothing) && (feature_source !== nothing)
        throw(ArgumentError(
            "Specify only one origin type - comid and feature_source cannot be provided together"
        ))
    end
    if (comid === nothing) && (feature_source === nothing)
        throw(ArgumentError("Specify one origin type - comid or feature_source is required"))
    end
end

function _validate_data_source(data_source)
    if data_source === nothing
        return
    end

    if _NLDI_AVAILABLE_DATA_SOURCES[] === nothing
        url = string(NLDI_API_BASE_URL, "/")
        response = _custom_get(url)
        data = JSON.parse(String(response.body))
        _NLDI_AVAILABLE_DATA_SOURCES[] = [x["source"] for x in data]
    end

    if String(data_source) in _NLDI_AVAILABLE_DATA_SOURCES[]
        return
    end

    throw(ArgumentError(
        "Invalid data source '$data_source'. Available data sources are: $(_NLDI_AVAILABLE_DATA_SOURCES[])"
    ))
end

function _nldi_features_to_df(feature_collection)
    features = get(feature_collection, "features", Any[])
    rows = NamedTuple[]
    for feature in features
        geom = get(feature, "geometry", Dict{String, Any}())
        props = get(feature, "properties", Dict{String, Any}())
        push!(rows, (
            feature_type = get(feature, "type", missing),
            geometry_type = get(geom, "type", missing),
            coordinates = get(geom, "coordinates", missing),
            properties = props,
        ))
    end
    return DataFrame(rows)
end

"""
    readNLDIflowlines(navigation_mode; distance=5, feature_source=nothing,
                      feature_id=nothing, comid=nothing, stop_comid=nothing,
                      trim_start=false, as_json=false)

Get flowlines from NLDI by feature source/ID or comid.

# Arguments
- `navigation_mode::String`: Navigation mode; one of `"UM"`, `"DM"`,
  `"UT"`, or `"DD"`.

# Keyword Arguments
- `distance::Int=5`: Navigation distance in kilometers.
- `feature_source::Union{Nothing,String}=nothing`: Origin feature source.
- `feature_id::Union{Nothing,String}=nothing`: Origin feature identifier.
- `comid::Union{Nothing,Int}=nothing`: Origin NHDPlus comid.
- `stop_comid::Union{Nothing,Int}=nothing`: Optional stopping comid.
- `trim_start::Bool=false`: Whether to trim to the starting flowline.
- `as_json::Bool=false`: Return raw JSON feature collection if `true`.

# Returns
- `df::DataFrame` or `Dict`: Parsed features as a `DataFrame` by default,
  or raw feature collection JSON when `as_json=true`.
- `response::HTTP.Messages.Response`: Raw HTTP response.

# Examples
```julia
julia> df, response = readNLDIflowlines("UM", comid=13294314);

julia> typeof(df)
DataFrame

julia> typeof(response)
HTTP.Messages.Response
```
"""
function readNLDIflowlines(navigation_mode;
                           distance=5,
                           feature_source=nothing,
                           feature_id=nothing,
                           comid=nothing,
                           stop_comid=nothing,
                           trim_start=false,
                           as_json=false)
    _validate_navigation_mode(navigation_mode)
    _validate_feature_source_comid(feature_source, feature_id, comid)

    mode = uppercase(String(navigation_mode))
    query_params = Dict{String, String}("distance" => string(distance))

    if feature_source !== nothing
        _validate_data_source(feature_source)
        query_params["trimStart"] = lowercase(string(trim_start))
        url = string(NLDI_API_BASE_URL, "/", feature_source, "/", feature_id,
                     "/navigation/", mode, "/flowlines")
        err_msg = "Error getting flowlines for feature source '$feature_source' and feature_id '$feature_id'"
    else
        url = string(NLDI_API_BASE_URL, "/comid/", comid,
                     "/navigation/", mode, "/flowlines")
        err_msg = "Error getting flowlines for comid '$comid'"
    end

    if stop_comid !== nothing
        query_params["stopComid"] = string(stop_comid)
    end

    feature_collection, response = _query_nldi(url, query_params, err_msg)
    if as_json
        return feature_collection, response
    end
    return _nldi_features_to_df(feature_collection), response
end

"""
    readNLDIbasin(feature_source, feature_id;
                  simplified=true, split_catchment=false, as_json=false)

Get aggregated basin geometry from NLDI.

# Arguments
- `feature_source::String`: Feature source (for example `"WQP"`).
- `feature_id::String`: Feature identifier.

# Keyword Arguments
- `simplified::Bool=true`: Request simplified basin geometry.
- `split_catchment::Bool=false`: Split catchment output.
- `as_json::Bool=false`: Return raw JSON feature collection if `true`.

# Returns
- `df::DataFrame` or `Dict`: Parsed basin features as a `DataFrame` by
    default, or raw JSON when `as_json=true`.
- `response::HTTP.Messages.Response`: Raw HTTP response.

# Examples
```julia
julia> df, response = readNLDIbasin("WQP", "USGS-054279485");

julia> typeof(df)
DataFrame

julia> typeof(response)
HTTP.Messages.Response
```
"""
function readNLDIbasin(feature_source, feature_id;
                       simplified=true,
                       split_catchment=false,
                       as_json=false)
    _validate_data_source(feature_source)
    if (feature_id === nothing) || (length(String(feature_id)) == 0)
        throw(ArgumentError("feature_id is required"))
    end

    url = string(NLDI_API_BASE_URL, "/", feature_source, "/", feature_id, "/basin")
    query_params = Dict(
        "simplified" => lowercase(string(simplified)),
        "splitCatchment" => lowercase(string(split_catchment)),
    )
    err_msg = "Error getting basin for feature source '$feature_source' and feature_id '$feature_id'"
    feature_collection, response = _query_nldi(url, query_params, err_msg)

    if as_json
        return feature_collection, response
    end
    return _nldi_features_to_df(feature_collection), response
end

"""
    readNLDIfeatures(; data_source=nothing, navigation_mode=nothing, distance=50,
                     feature_source=nothing, feature_id=nothing, comid=nothing,
                     lat=nothing, long=nothing, stop_comid=nothing, as_json=false)

Get NLDI features using feature_source/feature_id, comid, or lat/long origin.

# Keyword Arguments
- `data_source::Union{Nothing,String}=nothing`: Data source to search.
- `navigation_mode::Union{Nothing,String}=nothing`: One of `"UM"`, `"DM"`,
  `"UT"`, or `"DD"` when navigation is used.
- `distance::Int=50`: Navigation distance in kilometers.
- `feature_source::Union{Nothing,String}=nothing`: Origin feature source.
- `feature_id::Union{Nothing,String}=nothing`: Origin feature identifier.
- `comid::Union{Nothing,Int}=nothing`: Origin comid.
- `lat::Union{Nothing,Real}=nothing`: Latitude origin for position lookup.
- `long::Union{Nothing,Real}=nothing`: Longitude origin for position lookup.
- `stop_comid::Union{Nothing,Int}=nothing`: Optional stopping comid.
- `as_json::Bool=false`: Return raw JSON feature collection if `true`.

# Returns
- `df::DataFrame` or `Dict`: Parsed features as a `DataFrame` by default,
  or raw JSON when `as_json=true`.
- `response::HTTP.Messages.Response`: Raw HTTP response.

# Examples
```julia
julia> df, response = readNLDIfeatures(feature_source="WQP",
                                       feature_id="USGS-054279485");

julia> typeof(df)
DataFrames.DataFrame

julia> typeof(response)
HTTP.Messages.Response
```
"""
function readNLDIfeatures(; data_source=nothing,
                          navigation_mode=nothing,
                          distance=50,
                          feature_source=nothing,
                          feature_id=nothing,
                          comid=nothing,
                          lat=nothing,
                          long=nothing,
                          stop_comid=nothing,
                          as_json=false)
    if ((lat !== nothing) && (long === nothing)) || ((long !== nothing) && (lat === nothing))
        throw(ArgumentError("Both lat and long are required"))
    end

    if lat !== nothing
        if comid !== nothing
            throw(ArgumentError("Provide only one origin type - comid cannot be provided with lat or long"))
        end
        if (feature_source !== nothing) || (feature_id !== nothing)
            throw(ArgumentError("Provide only one origin type - feature_source and feature_id cannot be provided with lat or long"))
        end
    else
        if (comid !== nothing) || (data_source !== nothing)
            if navigation_mode === nothing
                throw(ArgumentError("navigation_mode is required if comid or data_source is provided"))
            end
        end

        _validate_feature_source_comid(feature_source, feature_id, comid)
        _validate_data_source(data_source)
        _validate_data_source(feature_source)
        if navigation_mode !== nothing
            _validate_navigation_mode(navigation_mode)
        end
    end

    query_params = Dict{String, String}()
    if lat !== nothing
        url = string(NLDI_API_BASE_URL, "/comid/position")
        query_params["coords"] = string("POINT(", long, " ", lat, ")")
        err_msg = "Error getting features for lat '$lat' and long '$long'"
    else
        if navigation_mode !== nothing
            mode = uppercase(String(navigation_mode))
            if feature_source !== nothing
                url = string(NLDI_API_BASE_URL, "/", feature_source, "/", feature_id,
                             "/navigation/", mode, "/", data_source)
                err_msg = "Error getting features for feature source '$feature_source' and feature_id '$feature_id', and data source '$data_source'"
            else
                url = string(NLDI_API_BASE_URL, "/comid/", comid,
                             "/navigation/", mode, "/", data_source)
                err_msg = "Error getting features for comid '$comid' and data source '$data_source'"
            end

            query_params["distance"] = string(distance)
            if stop_comid !== nothing
                query_params["stopComid"] = string(stop_comid)
            end
        else
            url = string(NLDI_API_BASE_URL, "/", feature_source, "/", feature_id)
            err_msg = "Error getting features for feature source '$feature_source' and feature_id '$feature_id'"
        end
    end

    feature_collection, response = _query_nldi(url, query_params, err_msg)
    if as_json
        return feature_collection, response
    end
    return _nldi_features_to_df(feature_collection), response
end

"""
    searchNLDI(; feature_source=nothing, feature_id=nothing,
               navigation_mode=nothing, data_source=nothing,
               find="features", comid=nothing, lat=nothing,
               long=nothing, distance=50)

Search helper for NLDI feature, basin, or flowline lookups.

# Keyword Arguments
- `feature_source::Union{Nothing,String}=nothing`: Origin feature source.
- `feature_id::Union{Nothing,String}=nothing`: Origin feature identifier.
- `navigation_mode::Union{Nothing,String}=nothing`: Navigation mode.
- `data_source::Union{Nothing,String}=nothing`: Data source filter.
- `find::String="features"`: One of `"features"`, `"basin"`,
  or `"flowlines"`.
- `comid::Union{Nothing,Int}=nothing`: Origin comid.
- `lat::Union{Nothing,Real}=nothing`: Latitude origin.
- `long::Union{Nothing,Real}=nothing`: Longitude origin.
- `distance::Int=50`: Navigation distance in kilometers.

# Returns
- `result::Dict`: Raw JSON feature collection for the requested search mode.
- `response::HTTP.Messages.Response`: Raw HTTP response.

# Examples
```julia
julia> result, response = searchNLDI(feature_source="WQP",
                                     feature_id="USGS-054279485",
                                     find="basin");

julia> result isa AbstractDict
true

julia> typeof(response)
HTTP.Messages.Response
```
"""
function searchNLDI(; feature_source=nothing,
                    feature_id=nothing,
                    navigation_mode=nothing,
                    data_source=nothing,
                    find="features",
                    comid=nothing,
                    lat=nothing,
                    long=nothing,
                    distance=50)
    if ((lat !== nothing) && (long === nothing)) || ((long !== nothing) && (lat === nothing))
        throw(ArgumentError("Both lat and long are required"))
    end

    find_l = lowercase(String(find))
    if (find_l in ["basin", "flowlines", "features"]) == false
        throw(ArgumentError(
            "Invalid value for find: $find - allowed values are: 'basin', 'flowlines', or 'features'"
        ))
    end
    if (lat !== nothing) && (find_l != "features")
        throw(ArgumentError("Invalid value for find: $find - lat/long is to get features not $find"))
    end
    if (comid !== nothing) && (find_l == "basin")
        throw(ArgumentError("Invalid value for find: basin - comid is to get features or flowlines not basin"))
    end

    if lat !== nothing
        return readNLDIfeatures(lat=lat, long=long, as_json=true)
    end
    if find_l == "basin"
        return readNLDIbasin(feature_source, feature_id, as_json=true)
    end
    if find_l == "flowlines"
        return readNLDIflowlines(navigation_mode,
                                 distance=distance,
                                 feature_source=feature_source,
                                 feature_id=feature_id,
                                 comid=comid,
                                 as_json=true)
    end

    return readNLDIfeatures(data_source=data_source,
                            navigation_mode=navigation_mode,
                            distance=distance,
                            feature_source=feature_source,
                            feature_id=feature_id,
                            comid=comid,
                            as_json=true)
end