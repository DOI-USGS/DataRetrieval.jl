module NLDI

using HTTP
using JSON
using DataFrames

# Import internal utilities from the parent module
import .._custom_get, .._query_value

const API_BASE_URL = "https://api.water.usgs.gov/nldi/linked-data"
const CRS = "EPSG:4326"
const AVAILABLE_DATA_SOURCES = Ref{Union{Nothing, Vector{String}}}(nothing)

function _fetch_data_sources_once!()
    if isnothing(AVAILABLE_DATA_SOURCES[])
        url = string(API_BASE_URL, "/")
        try
            response = _custom_get(url)
            parsed = JSON.parse(String(response.body))
            sources = get(parsed, "sources", Any[])
            AVAILABLE_DATA_SOURCES[] = [String(get(s, "source", "")) for s in sources]
        catch
            # fallback if API is down
            AVAILABLE_DATA_SOURCES[] = ["comid", "huc12pp", "nwissite", "wqp", "usgs_nwis_iv", "usgs_nwis_dv"]
        end
    end
end

function _validate_navigation_mode(navigation_mode)
    mode = uppercase(String(navigation_mode))
    if mode ∉ ("UM", "DM", "UT", "DD")
        throw(ArgumentError("Invalid navigation mode '$navigation_mode'"))
    end
end

function _validate_data_source(data_source)
    _fetch_data_sources_once!()
    if isnothing(data_source)
        return
    end
    if lowercase(String(data_source)) in (lowercase.(AVAILABLE_DATA_SOURCES[]))
        return
    end

    throw(ArgumentError(
        "Invalid data source '$data_source'. Available data sources are: $(AVAILABLE_DATA_SOURCES[])"
    ))
end

"""
    flowlines(navigation_mode; comid=nothing, distance=5, feature_source=nothing, feature_id=nothing, stop_comid=nothing, trim_start=false, as_json=false)
"""
function flowlines(navigation_mode;
                   distance=5,
                   feature_source=nothing,
                   feature_id=nothing,
                   comid=nothing,
                   stop_comid=nothing,
                   trim_start=false,
                   as_json=false)
    _validate_navigation_mode(navigation_mode)

    if comid !== nothing && feature_source !== nothing
        throw(ArgumentError("comid and feature_source are mutually exclusive."))
    end

    if comid !== nothing
        url = string(API_BASE_URL, "/comid/", comid, "/navigation/", navigation_mode, "/flowlines")
        err_msg = "Error getting flowlines for comid '$comid' and mode '$navigation_mode'"
    elseif feature_source !== nothing && feature_id !== nothing
        _validate_data_source(feature_source)
        url = string(API_BASE_URL, "/", feature_source, "/", feature_id, "/navigation/", navigation_mode, "/flowlines")
        err_msg = "Error getting flowlines for feature source '$feature_source', feature_id '$feature_id', and mode '$navigation_mode'"
    else
        throw(ArgumentError("Either comid or (feature_source and feature_id) must be provided."))
    end

    query_params = Dict{String, String}("distance" => string(distance))
    if stop_comid !== nothing
        query_params["stopComid"] = string(stop_comid)
    end
    if trim_start
        query_params["trimStart"] = "true"
    end

    feature_collection, response = _query_nldi(url, query_params, err_msg)
    if as_json
        return feature_collection, response
    end
    return _features_to_df(feature_collection), response
end

"""
    basin(feature_source, feature_id; simplified=true, split_catchment=false, as_json=false)
"""
function basin(feature_source, feature_id;
               simplified=true,
               split_catchment=false,
               as_json=false)
    if isnothing(feature_source) || isnothing(feature_id)
        throw(ArgumentError("feature_source and feature_id must be provided."))
    end
    _validate_data_source(feature_source)
    url = string(API_BASE_URL, "/", feature_source, "/", feature_id, "/basin")
    err_msg = "Error getting basin for feature source '$feature_source' and feature_id '$feature_id'"

    query_params = Dict{String, String}()
    if !simplified
        query_params["simplified"] = "false"
    end
    if split_catchment
        query_params["splitCatchment"] = "true"
    end

    feature_collection, response = _query_nldi(url, query_params, err_msg)
    if as_json
        return feature_collection, response
    end
    return _features_to_df(feature_collection), response
end

"""
    features(; data_source=nothing, navigation_mode=nothing, distance=50, feature_source=nothing, feature_id=nothing, comid=nothing, lat=nothing, long=nothing, as_json=false)
"""
function features(; data_source=nothing,
                  navigation_mode=nothing,
                  distance=50,
                  feature_source=nothing,
                  feature_id=nothing,
                  comid=nothing,
                  lat=nothing,
                  long=nothing,
                  as_json=false)

    url = ""
    err_msg = ""
    if feature_source !== nothing && feature_id !== nothing
        _validate_data_source(feature_source)
        if navigation_mode !== nothing
            _validate_navigation_mode(navigation_mode)
            _validate_data_source(data_source)
            url = string(API_BASE_URL, "/", feature_source, "/", feature_id, "/navigation/", navigation_mode, "/", data_source)
            err_msg = "Error getting navigated features for source '$feature_source', id '$feature_id', mode '$navigation_mode', and target '$data_source'"
        else
            url = string(API_BASE_URL, "/", feature_source, "/", feature_id)
            err_msg = "Error getting features for feature source '$feature_source' and feature_id '$feature_id'"
        end
    elseif feature_source !== nothing || feature_id !== nothing
        throw(ArgumentError("Both feature_source and feature_id must be provided."))
    elseif comid !== nothing
        if navigation_mode !== nothing
            _validate_navigation_mode(navigation_mode)
            _validate_data_source(data_source)
            url = string(API_BASE_URL, "/comid/", comid, "/navigation/", navigation_mode, "/", data_source)
            err_msg = "Error getting navigated features for comid '$comid', mode '$navigation_mode', and target '$data_source'"
        else
            throw(ArgumentError("navigation_mode must be provided when searching by comid."))
        end
    elseif lat !== nothing || long !== nothing
        if lat === nothing || long === nothing
            throw(ArgumentError("Both lat and long must be provided."))
        end
        url = string(API_BASE_URL, "/comid/position")
    else
        throw(ArgumentError("Insufficient arguments provided for features query."))
    end

    query_params = Dict{String, String}()
    if lat !== nothing && long !== nothing
        query_params["coords"] = string("POINT(", long, " ", lat, ")")
    end
    if navigation_mode !== nothing
        query_params["distance"] = string(distance)
    end

    feature_collection, response = _query_nldi(url, query_params, err_msg)
    if as_json
        return feature_collection, response
    end
    return _features_to_df(feature_collection), response
end

"""
    search(; feature_source=nothing, feature_id=nothing, navigation_mode=nothing, data_source=nothing, find="features", comid=nothing, lat=nothing, long=nothing, distance=50)
"""
function search(; feature_source=nothing,
                feature_id=nothing,
                navigation_mode=nothing,
                data_source=nothing,
                find="features",
                comid=nothing,
                lat=nothing,
                long=nothing,
                distance=50,
                as_json=false)
    
    find = lowercase(String(find))
    if find == "features"
        return features(data_source=data_source,
                        navigation_mode=navigation_mode,
                        distance=distance,
                        feature_source=feature_source,
                        feature_id=feature_id,
                        comid=comid,
                        lat=lat,
                        long=long,
                        as_json=as_json)
    elseif find == "flowlines"
        return flowlines(navigation_mode,
                         distance=distance,
                         feature_source=feature_source,
                         feature_id=feature_id,
                         comid=comid,
                         as_json=as_json)
    elseif find == "basin"
        return basin(feature_source, feature_id, as_json=as_json)
    else
        throw(ArgumentError("find must be one of 'features', 'flowlines', or 'basin'"))
    end
end

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

function _query_nldi(url, query_params, err_msg)
    response = _custom_get(url, query_params=query_params)
    if response.status != 200
        throw(ErrorException(string(err_msg, ". API returned status ", response.status)))
    end
    return JSON.parse(String(response.body)), response
end

function _features_to_df(feature_collection)
    features_list = get(feature_collection, "features", Any[])
    rows = Dict{Symbol, Any}[]
    for feature in features_list
        geom = get(feature, "geometry", Dict{String, Any}())
        props = get(feature, "properties", Dict{String, Any}())
        row_dict = Dict{Symbol, Any}()
        for (k, v) in props
            row_dict[Symbol(replace(String(k), "-" => "_"))] = v
        end
        # Include specific GeoJSON fields expected by tests
        row_dict[:geometry] = geom
        row_dict[:geometry_type] = get(geom, "type", missing)
        row_dict[:coordinates] = get(geom, "coordinates", missing)
        row_dict[:feature_type] = get(feature, "type", missing)
        
        push!(rows, row_dict)
    end
    return isempty(rows) ? DataFrame() : DataFrame(rows)
end

end
