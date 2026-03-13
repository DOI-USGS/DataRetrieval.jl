# Utility functions that are used in the package

const _USGS_API_TOKEN_OVERRIDE = Ref{Union{Nothing,String}}(nothing)

"""
    setUSGSAPIToken!(token::AbstractString)

Set a USGS WaterData API token for this Julia session. The token is attached
to requests as the `X-Api-Key` header and takes precedence over the
`API_USGS_PAT` environment variable.
"""
function setUSGSAPIToken!(token::AbstractString)
    token_str = strip(String(token))
    isempty(token_str) && throw(ArgumentError("token must not be empty"))
    _USGS_API_TOKEN_OVERRIDE[] = token_str
    return nothing
end

"""
    clearUSGSAPIToken!()

Clear the session token set by `setUSGSAPIToken!`. If `API_USGS_PAT` is
present in the environment, requests will continue to use that value.
"""
function clearUSGSAPIToken!()
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

"""
    _custom_get(url; query_params="", ssl_check=true)

Function to do a custom GET request that sets the package User-Agent and, when
available, a USGS API token (`X-Api-Key`). It also defines a 30 second
connection timeout and 5 retries when the initial attempt to connect to the web
service fails.
"""
function _custom_get(url; query_params="", ssl_check=true)
    headers = _default_headers()
    # do the GET request itself 2 cases depending on query parameters
    if query_params == ""
        response = HTTP.request("GET", url, headers,
                                connect_timeout=30,
                                retry=true,
                                retry_limit=5,
                                require_ssl_verification=ssl_check)
    else
        response = HTTP.request("GET", url, headers,
                                query=query_params,
                                connect_timeout=30,
                                retry=true,
                                retry_limit=5,
                                require_ssl_verification=ssl_check)
    end
    return response
end