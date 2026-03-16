module WaterData

using HTTP
using JSON
using DataFrames
using CSV
using Dates

# Import internal utilities from the parent module
import .._custom_get, .._default_headers, .._query_value

const BASE_URL = "https://api.waterdata.usgs.gov/samples-data"
const OGC_BASE_URL = "https://api.waterdata.usgs.gov/ogcapi/v0"
const STATS_BASE_URL = "https://api.waterdata.usgs.gov/statistics/v0"

const OGC_COLLECTIONS = Set([
  "daily",
  "continuous",
  "monitoring-locations",
  "time-series-metadata",
  "latest-continuous",
  "latest-daily",
  "field-measurements",
  "field-measurements-metadata",
  "combined-metadata",
  "channel-measurements",
])

const CODE_SERVICES = Set([
    "characteristicgroup",
    "characteristics",
    "counties",
    "countries",
    "observedproperty",
    "samplemedia",
    "sitetype",
    "states",
])

const SERVICES = Set([
    "activities",
    "locations",
    "organizations",
    "projects",
    "results",
])

const PROFILE_LOOKUP = Dict(
    "activities"    => Set(["sampact", "actmetric", "actgroup", "count"]),
    "locations"     => Set(["site", "count"]),
    "organizations" => Set(["organization", "count"]),
    "projects"      => Set(["project", "projectmonitoringlocationweight"]),
    "results"       => Set([
        "fullphyschem",
        "basicphyschem",
        "fullbio",
        "basicbio",
        "narrow",
        "resultdetectionquantitationlimit",
        "labsampleprep",
        "count",
    ]),
)

const METADATA_COLLECTIONS = Set([
  "agency-codes",
  "altitude-datums",
  "aquifer-codes",
  "aquifer-types",
  "coordinate-accuracy-codes",
  "coordinate-datum-codes",
  "coordinate-method-codes",
  "counties",
  "hydrologic-unit-codes",
  "medium-codes",
  "national-aquifer-codes",
  "parameter-codes",
  "reliability-codes",
  "site-types",
  "states",
  "statistic-codes",
  "topographic-codes",
  "time-zone-codes",
])

# ---------------------------------------------------------------------------
# Primary public API
# ---------------------------------------------------------------------------

"""
  data(service; cql=nothing, ssl_check=true, kwargs...)

Generalized USGS Waterdata OGC retrieval for any supported collection.
"""
function data(service; cql=nothing, ssl_check=true, kwargs...)
  svc = lowercase(String(service))
  if svc ∉ OGC_COLLECTIONS
    throw(ArgumentError(
      "Invalid Waterdata service: '$svc'. " *
      "Valid options are: $(sort(collect(OGC_COLLECTIONS)))"
    ))
  end

  output_id = _output_id(svc)
  url = string(OGC_BASE_URL, "/collections/", svc, "/items")

  query_params, no_paging = _prepare_ogc_query(kwargs, svc)

  if cql === nothing
    df, response = _ogc_get(svc, output_id;
                      ssl_check=ssl_check,
                      _extra_query=query_params,
                      no_paging=no_paging)
    return df, response
  end

  cql_body = cql isa AbstractDict ? JSON.json(cql) : String(cql)
  headers = _default_headers()
  push!(headers, "Content-Type" => "application/query-cql-json")

  response = HTTP.request("POST", url, headers, cql_body,
              query=query_params,
              connect_timeout=30,
              retry=true,
              retry_limit=5,
              require_ssl_verification=ssl_check)

  parsed = JSON.parse(String(response.body))
  parsed_pages = Any[parsed]
  if no_paging == false
    next_url = _next_link(parsed)
    while next_url !== nothing
      page_response = _custom_get(next_url; ssl_check=ssl_check)
      page_parsed = JSON.parse(String(page_response.body))
      push!(parsed_pages, page_parsed)
      next_url = _next_link(page_parsed)
    end
  end

  dfs = DataFrame[]
  for page in parsed_pages
    push!(dfs, _flatten_ogc_features(page))
  end
  df = isempty(dfs) ? DataFrame() : reduce((a, b) -> vcat(a, b; cols=:union), dfs)
  _rename_id!(df, output_id)
  _cast_columns!(df)
  return df, response
end

"""
  check_ogc_requests(; endpoint="daily", request_type="queryables", ssl_check=true)

Request OGC collection metadata (`queryables` or `schema`) for a Waterdata
collection.
"""
function ogc_requests(; endpoint="daily", request_type="queryables", ssl_check=true)
  svc = lowercase(String(endpoint))
  req_type = lowercase(String(request_type))

  if svc ∉ OGC_COLLECTIONS && svc ∉ METADATA_COLLECTIONS
    throw(ArgumentError(
      "Invalid endpoint '$svc'. " *
      "Valid options include OGC collections and metadata collections."
    ))
  end
  if req_type != "queryables" && req_type != "schema"
    throw(ArgumentError("request_type must be either 'queryables' or 'schema'"))
  end

  url = string(OGC_BASE_URL, "/collections/", svc, "/", req_type)
  response = _custom_get(url; ssl_check=ssl_check)
  payload = JSON.parse(String(response.body))
  return payload, response
end

"""
  ogc_params(service; ssl_check=true)

Get parameter descriptions for a Waterdata OGC collection using the collection
schema endpoint.
"""
function ogc_params(service; ssl_check=true)
  schema, response = ogc_requests(endpoint=service,
                         request_type="schema",
                         ssl_check=ssl_check)
  props = get(schema, "properties", Dict{String,Any}())
  params = Dict{String,Any}()
  if props isa AbstractDict
    for (k, v) in props
      if v isa AbstractDict
        params[String(k)] = get(v, "description", missing)
      else
        params[String(k)] = missing
      end
    end
  end
  return params, response
end

"""
    codes(code_service; ssl_check=true)

Return code values from a USGS Samples code-service endpoint.
"""
function codes(code_service; ssl_check=true)
    svc = lowercase(String(code_service))
    if svc ∉ CODE_SERVICES
        throw(ArgumentError(
            "Invalid code service: '$svc'. " *
            "Valid options are: $(sort(collect(CODE_SERVICES)))"
        ))
    end

    url = string(BASE_URL, "/codeservice/", svc)
    response = _custom_get(url;
                           query_params=Dict("mimeType" => "application/json"),
                           ssl_check=ssl_check)

    parsed = JSON.parse(String(response.body))
    data = get(parsed, "data", Any[])
    return DataFrame(data), response
end

"""
    samples(; ssl_check=true, service="results", profile="fullphyschem", kwargs...)

Flexible query of the USGS Samples database.
"""
function samples(;
        ssl_check=true,
        service="results",
        profile="fullphyschem",
        activity_media_name=nothing,
        activity_start_date_lower=nothing,
        activity_start_date_upper=nothing,
        activity_type_code=nothing,
        characteristic_group=nothing,
        characteristic=nothing,
        characteristic_user_supplied=nothing,
        bounding_box=nothing,
        country_fips=nothing,
        state_fips=nothing,
        county_fips=nothing,
        site_type_code=nothing,
        site_type_name=nothing,
        usgs_p_code=nothing,
        hydrologic_unit=nothing,
        monitoring_location_identifier=nothing,
        organization_identifier=nothing,
        point_location_latitude=nothing,
        point_location_longitude=nothing,
        point_location_within_miles=nothing,
        project_identifier=nothing,
        record_identifier_user_supplied=nothing)

    svc  = lowercase(String(service))
    prof = lowercase(String(profile))
    _check_profiles(svc, prof)

    query_params = Dict{String,String}("mimeType" => "text/csv")
    possible_params = Dict(
        "activityMediaName"            => activity_media_name,
        "activityStartDateLower"       => activity_start_date_lower,
        "activityStartDateUpper"       => activity_start_date_upper,
        "activityTypeCode"             => activity_type_code,
        "characteristicGroup"          => characteristic_group,
        "characteristic"               => characteristic,
        "characteristicUserSupplied"   => characteristic_user_supplied,
        "boundingBox"                  => bounding_box,
        "countryFips"                  => country_fips,
        "stateFips"                    => state_fips,
        "countyFips"                   => county_fips,
        "siteTypeCode"                 => site_type_code,
        "siteTypeName"                 => site_type_name,
        "usgsPCode"                    => usgs_p_code,
        "hydrologicUnit"               => hydrologic_unit,
        "monitoringLocationIdentifier" => monitoring_location_identifier,
        "organizationIdentifier"       => organization_identifier,
        "pointLocationLatitude"        => point_location_latitude,
        "pointLocationLongitude"       => point_location_longitude,
        "pointLocationWithinMiles"     => point_location_within_miles,
        "projectIdentifier"            => project_identifier,
        "recordIdentifierUserSupplied" => record_identifier_user_supplied,
    )

    for (k, v) in possible_params
        v === nothing && continue
        query_params[k] = _query_value(v)
    end

    url      = string(BASE_URL, "/", svc, "/", prof)
    response = _custom_get(url; query_params=query_params, ssl_check=ssl_check)
    content_type = HTTP.header(response, "Content-Type", "")
    if occursin("text/html", content_type)
        throw(ArgumentError("Received an HTML response instead of CSV data from Waterdata. This typically indicates an error page or a service issue."))
    end
    df       = DataFrame(CSV.File(IOBuffer(response.body); comment="#", ignoreemptyrows=true))
    return df, response
end

"""
    results(; profile="fullphyschem", kwargs...)

Query the USGS Samples database for **measurement results**.
"""
function results(; profile="fullphyschem", kwargs...)
    return samples(; service="results", profile=profile, kwargs...)
end

"""
    locations(; profile="site", kwargs...)

Query the USGS Samples database for **monitoring locations**.
"""
function locations(; profile="site", kwargs...)
    return samples(; service="locations", profile=profile, kwargs...)
end

"""
    activities(; profile="sampact", kwargs...)

Query the USGS Samples database for **field activities**.
"""
function activities(; profile="sampact", kwargs...)
    return samples(; service="activities", profile=profile, kwargs...)
end

"""
    projects(; profile="project", kwargs...)

Query the USGS Samples database for **monitoring projects**.
"""
function projects(; profile="project", kwargs...)
    return samples(; service="projects", profile=profile, kwargs...)
end

"""
    organizations(; profile="organization", kwargs...)

Query the USGS Samples database for **organizations**.
"""
function organizations(; profile="organization", kwargs...)
    return samples(; service="organizations", profile=profile, kwargs...)
end

"""
    daily(; ssl_check=true, kwargs...)

Get daily observations from the USGS Waterdata OGC API (`daily` collection).
"""
function daily(; ssl_check=true, kwargs...)
  df, response = _ogc_get("daily", "daily_id"; ssl_check=ssl_check, kwargs...)
  _drop_column!(df, "daily_id")
  return df, response
end

"""
    continuous(; ssl_check=true, kwargs...)

Get continuous observations from the USGS Waterdata OGC API (`continuous`
collection).
"""
function continuous(; ssl_check=true, kwargs...)
  return _ogc_get("continuous", "continuous_id"; ssl_check=ssl_check, kwargs...)
end

"""
    monitoring_locations(; ssl_check=true, kwargs...)

Query monitoring-location metadata from the USGS Waterdata OGC API.
"""
function monitoring_locations(; ssl_check=true, kwargs...)
  return _ogc_get("monitoring-locations", "monitoring_location_id"; ssl_check=ssl_check, kwargs...)
end

"""
    series_metadata(; ssl_check=true, kwargs...)

Query time-series metadata from the USGS Waterdata OGC API.
"""
function series_metadata(; ssl_check=true, kwargs...)
  return _ogc_get("time-series-metadata", "time_series_id"; ssl_check=ssl_check, kwargs...)
end

"""
    latest_continuous(; ssl_check=true, kwargs...)

Query the most recent continuous observation for each matching time series.
"""
function latest_continuous(; ssl_check=true, kwargs...)
  return _ogc_get("latest-continuous", "latest_continuous_id"; ssl_check=ssl_check, kwargs...)
end

"""
    latest_daily(; ssl_check=true, kwargs...)

Query the most recent daily observation for each matching time series.
"""
function latest_daily(; ssl_check=true, kwargs...)
  return _ogc_get("latest-daily", "latest_daily_id"; ssl_check=ssl_check, kwargs...)
end

"""
    field_measurements(; ssl_check=true, kwargs...)

Query field-measurement observations from the USGS Waterdata OGC API.
"""
function field_measurements(; ssl_check=true, kwargs...)
  return _ogc_get("field-measurements", "field_measurement_id"; ssl_check=ssl_check, kwargs...)
end

"""
    channel_measurements(; ssl_check=true, kwargs...)

Query channel-measurement observations from the USGS Waterdata OGC API.
"""
function channel_measurements(; ssl_check=true, kwargs...)
  return _ogc_get("channel-measurements", "channel_measurements_id"; ssl_check=ssl_check, kwargs...)
end

"""
    field_metadata(; ssl_check=true, kwargs...)

Query field-measurement metadata from the USGS Waterdata OGC API.
"""
function field_metadata(; ssl_check=true, kwargs...)
  return _ogc_get("field-measurements-metadata", "field_series_id"; ssl_check=ssl_check, kwargs...)
end

"""
    combined_metadata(; ssl_check=true, kwargs...)

Query combined site and time-series metadata from the USGS Waterdata OGC API.
"""
function combined_metadata(; ssl_check=true, kwargs...)
  return _ogc_get("combined-metadata", "combined_meta_id"; ssl_check=ssl_check, kwargs...)
end

"""
    reference_table(collection; query=Dict(), ssl_check=true)

Fetch a Waterdata metadata reference table from the OGC API.
"""
function reference_table(collection; query=Dict{String,Any}(), ssl_check=true)
  c = lowercase(String(collection))
  if c ∉ METADATA_COLLECTIONS
    throw(ArgumentError(
      "Invalid collection: '$c'. " *
      "Valid options are: $(sort(collect(METADATA_COLLECTIONS)))"
    ))
  end

  output_id = if endswith(c, "s") && c != "counties"
    replace(chop(c), "-" => "_")
  elseif c == "counties"
    "county"
  else
    replace(c, "-" => "_")
  end

  return _ogc_get(c, output_id; ssl_check=ssl_check, _extra_query=query)
end

"""
    stats_por(; ssl_check=true, expand_percentiles=true, kwargs...)

Query period-of-record statistics from the Waterdata statistics API.
"""
function stats_por(; ssl_check=true, expand_percentiles=true, kwargs...)
  return _stats_get("observationNormals";
                 ssl_check=ssl_check,
                 expand_percentiles=expand_percentiles,
                 kwargs...)
end

"""
    stats_date_range(; ssl_check=true, expand_percentiles=true, kwargs...)

Query interval-based statistics from the Waterdata statistics API.
"""
function stats_date_range(; ssl_check=true, expand_percentiles=true, kwargs...)
  return _stats_get("observationIntervals";
                 ssl_check=ssl_check,
                 expand_percentiles=expand_percentiles,
                 kwargs...)
end

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

function _ogc_get(service::String, output_id::String; ssl_check=true, kwargs...)
  url = string(OGC_BASE_URL, "/collections/", service, "/items")
  query_params, no_paging = _prepare_ogc_query(kwargs, service)
  parsed_pages, response = _collect_ogc_pages(url, query_params, ssl_check;
                                                no_paging=no_paging)

  dfs = DataFrame[]
  for parsed in parsed_pages
    push!(dfs, _flatten_ogc_features(parsed))
  end
  df = isempty(dfs) ? DataFrame() : reduce((a, b) -> vcat(a, b; cols=:union), dfs)

  _rename_id!(df, output_id)
  _cast_columns!(df)
  return df, response
end

function _collect_ogc_pages(url::String,
                             query_params::Dict{String,String},
                             ssl_check::Bool;
                             no_paging::Bool=false)
  response = _custom_get(url; query_params=query_params, ssl_check=ssl_check)
  parsed = JSON.parse(String(response.body))
  pages = Any[parsed]

  if no_paging == false
    next_url = _next_link(parsed)
    while next_url !== nothing
      page_response = _custom_get(next_url; ssl_check=ssl_check)
      page_parsed = JSON.parse(String(page_response.body))
      push!(pages, page_parsed)
      next_url = _next_link(page_parsed)
    end
  end

  return pages, response
end

function _prepare_ogc_query(kwargs, service="")
  query_params = Dict{String,String}()
  no_paging = get(kwargs, :no_paging, false)
  extra_query = get(kwargs, :_extra_query, nothing)

  for (k, v) in kwargs
    k in (:_extra_query, :no_paging) && continue
    v === nothing && continue
    key = String(k)

    # R parity: the primary output ID of the service (daily_id, time_series_id, etc.) 
    # maps to the 'id' query parameter.
    output_id = _output_id(service)
    if key == output_id
      key = "id"
    end

    if key == "bbox" && v isa AbstractVector
      query_params[key] = join(string.(v), ",")
    elseif key == "properties" && v isa AbstractVector
      # R parity: strip 'id' and output_id from properties if present
      props = filter(p -> lowercase(string(p)) ∉ ["id", lowercase(output_id)], v)
      query_params[key] = isempty(props) ? "id" : join(string.(props), ",")
    elseif key == "skip_geometry"
      query_params["skipGeometry"] = lowercase(string(v))
    else
      query_params[key] = _query_value(v)
    end
  end

  # Default limit if not provided
  get!(query_params, "limit", "50000")

  if extra_query isa AbstractDict
    for (k, v) in extra_query
      query_params[String(k)] = _query_value(v)
    end
  end

  return query_params, no_paging
end

function _next_link(parsed)
  links = get(parsed, "links", Any[])
  for link in links
    if link isa AbstractDict
      rel = lowercase(string(get(link, "rel", "")))
      href = get(link, "href", nothing)
      if rel == "next" && href !== nothing
        href_str = String(href)
        if startswith(href_str, "http://") || startswith(href_str, "https://")
          return href_str
        elseif startswith(href_str, "/")
          return string("https://api.waterdata.usgs.gov", href_str)
        else
          return string(OGC_BASE_URL, "/", href_str)
        end
      end
    end
  end
  return nothing
end

function _flatten_ogc_features(parsed)
  features = get(parsed, "features", Any[])
  rows = Dict{Symbol,Any}[]
  for feat in features
    row = Dict{Symbol,Any}()
    props = get(feat, "properties", Dict{String,Any}())
    for (k, v) in props
      row[Symbol(replace(String(k), "-" => "_"))] = v
    end
    if haskey(feat, "id")
      row[:id] = feat["id"]
    end
    if get(feat, "geometry", nothing) !== nothing
      row[:geometry] = feat["geometry"]
    end
    push!(rows, row)
  end

  return isempty(rows) ? DataFrame() : DataFrame(rows)
end

function _rename_id!(df::DataFrame, output_id::String)
  if :id in names(df)
    rename!(df, :id => Symbol(output_id))
  elseif "id" in names(df)
    rename!(df, "id" => output_id)
  end
  return df
end

function _cast_columns!(df::DataFrame)
  isempty(df) && return df

  numeric_cols = Set([
    "altitude",
    "altitude_accuracy",
    "contributing_drainage_area",
    "drainage_area",
    "hole_constructed_depth",
    "value",
    "well_constructed_depth",
  ])
  date_cols = Set([
    "begin",
    "begin_utc",
    "construction_date",
    "end",
    "end_utc",
    "last_modified",
    "time",
  ])

  for c in names(df)
    col_name = lowercase(string(c))
    if col_name in numeric_cols
      df[!, c] = map(x -> tryparse(Float64, string(x)), df[!, c])
    elseif col_name in date_cols
      df[!, c] = map(x -> _try_datetime(x), df[!, c])
    end
  end
  return df
end

function _try_datetime(x)
  x === missing && return missing
  s = string(x)
  for fmt in (dateformat"yyyy-mm-ddTHH:MM:SSZ", dateformat"yyyy-mm-ddTHH:MM:SS", dateformat"yyyy-mm-dd")
    dt = tryparse(DateTime, s, fmt)
    dt === nothing || return dt
  end
  return missing
end

function _stats_get(endpoint::String; ssl_check=true, expand_percentiles=true, kwargs...)
  url = string(STATS_BASE_URL, "/", endpoint)
  query_params = Dict{String,String}()
  no_paging = false
  for (k, v) in kwargs
    if k == :no_paging
      no_paging = Bool(v)
      continue
    end
    v === nothing && continue
    query_params[String(k)] = _query_value(v)
  end

  response = _custom_get(url; query_params=query_params, ssl_check=ssl_check)
  parsed = JSON.parse(String(response.body))

  all_features = Any[]
  append!(all_features, get(parsed, "features", Any[]))

  if no_paging == false
    next_token = get(parsed, "next", nothing)
    while next_token !== nothing && string(next_token) != ""
      query_params["next"] = string(next_token)
      page_response = _custom_get(url; query_params=query_params, ssl_check=ssl_check)
      page_parsed = JSON.parse(String(page_response.body))
      append!(all_features, get(page_parsed, "features", Any[]))
      next_token = get(page_parsed, "next", nothing)
    end
  end

  parsed_all = Dict("features" => all_features)
  df = _flatten_stats(parsed_all)

  if expand_percentiles
    computation_col = _find_column(df, "computation")
    if computation_col !== nothing
      percentile_col = _find_column(df, "percentile")
      if percentile_col === nothing
        df[!, "percentile"] = Vector{Union{Missing,Float64}}(missing, nrow(df))
        percentile_col = "percentile"
      end

      for i in 1:nrow(df)
        comp = lowercase(string(df[i, computation_col]))
        if comp == "minimum"
          df[i, percentile_col] = 0.0
        elseif comp == "median"
          df[i, percentile_col] = 50.0
        elseif comp == "maximum"
          df[i, percentile_col] = 100.0
        end
      end
    end
  end

  return df, response
end

function _drop_column!(df::DataFrame, col::String)
  if col in string.(names(df))
    select!(df, Not([c for c in names(df) if string(c) == col]))
  end
  return df
end

function _output_id(service::String)
  svc = lowercase(String(service))
  if svc == "daily"
    return "daily_id"
  elseif svc == "latest-daily"
    return "latest_daily_id"
  elseif svc == "latest-continuous"
    return "latest_continuous_id"
  elseif svc == "continuous"
    return "continuous_id"
  elseif svc == "monitoring-locations"
    return "monitoring_location_id"
  elseif svc == "time-series-metadata"
    return "time_series_id"
  elseif svc == "field-measurements"
    return "field_measurement_id"
  elseif svc == "field-measurements-metadata"
    return "field_series_id"
  elseif svc == "combined-metadata"
    return "combined_meta_id"
  elseif svc == "channel-measurements"
    return "channel_measurements_id"
  elseif svc in METADATA_COLLECTIONS
    if endswith(svc, "s") && svc != "counties"
      return replace(chop(svc), "-" => "_")
    elseif svc == "counties"
      return "county"
    else
      return replace(svc, "-" => "_")
    end
  end
  return replace(svc, "-" => "_")
end

function _find_column(df::DataFrame, target::String)
  target_lower = lowercase(target)
  for c in names(df)
    if lowercase(string(c)) == target_lower
      return c
    end
  end
  return nothing
end

function _flatten_stats(parsed)
  features = get(parsed, "features", Any[])
  rows = Vector{Dict{Symbol,Any}}()

  for feat in features
    props = get(feat, "properties", Dict{String,Any}())
    geom = get(feat, "geometry", nothing)
    data_entries = get(props, "data", Any[])

    if isempty(data_entries)
      row = Dict{Symbol,Any}()
      for (k, v) in props
        if k == "data"
          continue
        end
        row[Symbol(replace(String(k), "-" => "_"))] = v
      end
      if geom !== nothing
        row[:geometry] = geom
      end
      push!(rows, row)
      continue
    end

    for item in data_entries
      item_vals = get(item, "values", Any[])
      percentiles = get(item, "percentiles", Any[])

      if item_vals isa AbstractVector && !isempty(item_vals)
        for (j, val) in enumerate(item_vals)
          row = Dict{Symbol,Any}()
          for (k, v) in props
            if k == "data"
              continue
            end
            row[Symbol(replace(String(k), "-" => "_"))] = v
          end
          for (k, v) in item
            if k in ("values", "percentiles")
              continue
            end
            row[Symbol(replace(String(k), "-" => "_"))] = v
          end
          row[:value] = val
          if percentiles isa AbstractVector && j <= length(percentiles)
            row[:percentile] = percentiles[j]
          end
          if geom !== nothing
            row[:geometry] = geom
          end
          push!(rows, row)
        end
      else
        row = Dict{Symbol,Any}()
        for (k, v) in props
          if k == "data"
            continue
          end
          row[Symbol(replace(String(k), "-" => "_"))] = v
        end
        for (k, v) in item
          row[Symbol(replace(String(k), "-" => "_"))] = v
        end
        if geom !== nothing
          row[:geometry] = geom
        end
        push!(rows, row)
      end
    end
  end

  return isempty(rows) ? DataFrame() : DataFrame(rows)
end

function _check_profiles(service, profile)
    if service ∉ SERVICES
        throw(ArgumentError(
            "Invalid service: '$service'. " *
            "Valid options are: $(sort(collect(SERVICES)))"
        ))
    end
    valid_profiles = PROFILE_LOOKUP[service]
    if profile ∉ valid_profiles
        throw(ArgumentError(
            "Invalid profile: '$profile' for service '$service'. " *
            "Valid options are: $(sort(collect(valid_profiles)))"
        ))
    end
end



end
