# Utility functions that are used in the package

const _USGS_API_TOKEN_OVERRIDE = Ref{Union{Nothing,String}}(nothing)

"""
    set_token!(token::AbstractString)

Set a USGS WaterData API token for this Julia session. The token is attached
to requests as the `X-Api-Key` header and takes precedence over the
`API_USGS_PAT` environment variable.
"""
function set_token!(token::AbstractString)
    token_str = strip(String(token))
    isempty(token_str) && throw(ArgumentError("token must not be empty"))
    _USGS_API_TOKEN_OVERRIDE[] = token_str
    return nothing
end

"""
    clear_token!()

Clear the session token set by `set_token!`. If `API_USGS_PAT` is
present in the environment, requests will continue to use that value.
"""
function clear_token!()
    _USGS_API_TOKEN_OVERRIDE[] = nothing
    return nothing
end

function _resolve_usgs_api_token()
    if _USGS_API_TOKEN_OVERRIDE[] !== nothing
        return _USGS_API_TOKEN_OVERRIDE[]
    end
    token = get(ENV, "API_USGS_PAT", "")
    token = strip(String(token))
    return isempty(token) ? nothing : token
end

function _default_headers()
    jdr_version = "v0.1.0"
    jdr_user_agent = string("julia-dataretrieval/", jdr_version)
    headers = ["user-agent" => jdr_user_agent]

    token = _resolve_usgs_api_token()
    if token !== nothing
        push!(headers, "X-Api-Key" => token)
    end
    return headers
end

function _custom_get(url; query_params=nothing, ssl_check=true)
    headers = _default_headers()
    
    # Select kwargs based on whether query_params is provided
    kwargs = (connect_timeout=30, retry=true, retry_limit=5, require_ssl_verification=ssl_check)
    if query_params !== nothing
        kwargs = merge(kwargs, (query=query_params,))
    end

    return HTTP.request("GET", url, headers; kwargs...)
end

function _query_value(v)
    v isa AbstractVector ? join(string.(v), ",") : string(v)
end