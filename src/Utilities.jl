# Utility functions that are used in the package

"""
    _custom_get(url; query_params="")

Function to do a custom GET request that sets the user-agent as a header to
identify the package, and also defines a 30 second connection timeout and 5
retries when the initial attempt to connect to the web service fails.
"""
function _custom_get(url; query_params="")
    # define the package info
    jdr_version = "v0.1.0"
    # define the user-agent
    jdr_user_agent = string("julia-dataretrieval/", jdr_version)
    # assign it to the header
    headers = ["user-agent" => jdr_user_agent]
    # do the GET request itself 2 cases depending on query parameters
    if query_params == ""
        response = HTTP.request("GET", url, headers,
                                connect_timeout=30,
                                retry=true,
                                retry_limit=5)
    else
        response = HTTP.request("GET", url, headers,
                                query=query_params,
                                connect_timeout=30,
                                retry=true,
                                retry_limit=5)
    end
    return response
end