module WQP

using HTTP
using DataFrames
using CSV

# Import internal utilities from the parent module
import .._custom_get, .._default_headers, .._query_value

"""
    url(service; legacy=true)

Function to construct the URL for the Wqp service.
"""
function url(service; legacy=true)
    svc = String(service)

    legacy_services = Set([
        "Activity",
        "ActivityMetric",
        "BiologicalMetric",
        "Organization",
        "Project",
        "ProjectMonitoringLocationWeighting",
        "Result",
        "ResultDetectionQuantitationLimit",
        "Station",
    ])
    wqx3_services = Set(["Activity", "Result", "Station"])

    if legacy
        _warn_legacy_once!()
        if svc ∉ legacy_services
            throw(ArgumentError(
                "Legacy WQP service not recognized: $svc. Valid options are $(collect(legacy_services))."
            ))
        end
        return string("https://www.waterqualitydata.us/data/", svc, "/search?")
    end

    _warn_wqx3_once!()
    if svc ∉ wqx3_services
        @warn "WQX3.0 profile is not available for service '$svc'; using legacy endpoint."
        return url(svc; legacy=true)
    end
    return string("https://www.waterqualitydata.us/wqx3/", svc, "/search?")
end

"""
    data(service; legacy=true, ssl_check=true, kwargs...)
"""
function data(service; legacy=true, ssl_check=true, kwargs...)
    df, response = _generic_call(service, Dict(kwargs...); legacy=legacy, ssl_check=ssl_check)
    return df, response
end

"""
    results(; legacy=true, ssl_check=true, kwargs...)
"""
function results(; legacy=true, ssl_check=true, kwargs...)
    return data("Result"; legacy=legacy, ssl_check=ssl_check, kwargs...)
end

"""
    sites(; legacy=true, ssl_check=true, kwargs...)
"""
function sites(; legacy=true, ssl_check=true, kwargs...)
    return data("Station"; legacy=legacy, ssl_check=ssl_check, kwargs...)
end

"""
    organizations(; legacy=true, ssl_check=true, kwargs...)
"""
function organizations(; legacy=true, ssl_check=true, kwargs...)
    return data("Organization"; legacy=legacy, ssl_check=ssl_check, kwargs...)
end

"""
    projects(; legacy=true, ssl_check=true, kwargs...)
"""
function projects(; legacy=true, ssl_check=true, kwargs...)
    return data("Project"; legacy=legacy, ssl_check=ssl_check, kwargs...)
end

"""
    activities(; legacy=true, ssl_check=true, kwargs...)
"""
function activities(; legacy=true, ssl_check=true, kwargs...)
    return data("Activity"; legacy=legacy, ssl_check=ssl_check, kwargs...)
end

"""
    detection_limits(; legacy=true, ssl_check=true, kwargs...)
"""
function detection_limits(; legacy=true, ssl_check=true, kwargs...)
    return data("ResultDetectionQuantitationLimit"; legacy=legacy, ssl_check=ssl_check, kwargs...)
end

"""
    habitat_metrics(; legacy=true, ssl_check=true, kwargs...)
"""
function habitat_metrics(; legacy=true, ssl_check=true, kwargs...)
    return data("BiologicalMetric"; legacy=legacy, ssl_check=ssl_check, kwargs...)
end

"""
    project_weights(; legacy=true, ssl_check=true, kwargs...)
"""
function project_weights(; legacy=true, ssl_check=true, kwargs...)
    return data("ProjectMonitoringLocationWeighting"; legacy=legacy, ssl_check=ssl_check, kwargs...)
end

"""
    activity_metrics(; legacy=true, ssl_check=true, kwargs...)
"""
function activity_metrics(; legacy=true, ssl_check=true, kwargs...)
    return data("ActivityMetric"; legacy=legacy, ssl_check=ssl_check, kwargs...)
end

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

function _generic_call(service, query_params; legacy=true, ssl_check=true)
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

    # Handle some common snake_case to Wqp camelCase mappings if they occur
    # Wqp usually uses camelCase for parameters like statecode, pCode, startDateLo
    # We will support both for convenience but prioritize what Wqp expects.
    _map_key!(normalized_query, "state_code", "statecode")
    _map_key!(normalized_query, "county_code", "countycode")
    _map_key!(normalized_query, "site_id", "siteid")
    _map_key!(normalized_query, "p_code", "pCode")
    _map_key!(normalized_query, "start_date_lo", "startDateLo")
    _map_key!(normalized_query, "start_date_hi", "startDateHi")
    _map_key!(normalized_query, "characteristic_name", "characteristicName")
    _map_key!(normalized_query, "b_box", "bBox")

    # construct the base query URL
    request_url = url(service; legacy=legacy)
    # do the GET request
    response = _custom_get(request_url, query_params=normalized_query, ssl_check=ssl_check)
    
    content_type = HTTP.header(response, "Content-Type", "")
    if occursin("text/html", content_type)
        throw(ArgumentError("Received an HTML response instead of CSV data from Wqp. This typically indicates an error page or a service issue."))
    end
    df = DataFrame(CSV.File(response.body; comment="#", ignoreemptyrows=true))
    return df, response
end

function _map_key!(d, old, new)
    if haskey(d, old) && !haskey(d, new)
        d[new] = d[old]
        delete!(d, old)
    end
end

const LEGACY_WARNING_SHOWN = Ref(false)
const WQX3_WARNING_SHOWN = Ref(false)

function _warn_legacy_once!()
    if !LEGACY_WARNING_SHOWN[]
        @warn "WQP legacy format is deprecated and USGS legacy data may be stale. Prefer WQX3.0 where available by using legacy=false."
        LEGACY_WARNING_SHOWN[] = true
    end
end

function _warn_wqx3_once!()
    if !WQX3_WARNING_SHOWN[]
        @warn "WQX3.0 support is experimental and queries may be slow or intermittent."
        WQX3_WARNING_SHOWN[] = true
    end
end

end
