module NLDIGeoDataFramesExt

using DataRetrieval
using GeoDataFrames
import JSON

# Implementation of the optional dependency extension hook
function _to_geodataframe(feature_collection, fallback_df)
    try
        # feature_collection is a Dict representing GeoJSON
        geojson_str = JSON.json(feature_collection)
        path, io = mktemp()
        write(io, geojson_str)
        close(io)
        df = GeoDataFrames.read(path)
        rm(path, force=true)
        return df
    catch e
        # If conversion fails for whatever reason, return the normal DataFrame
        @warn "GeoDataFrames conversion failed: $e"
        return fallback_df
    end
end

end
