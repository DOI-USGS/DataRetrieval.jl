using DataRetrieval
using HTTP
using Test
using DataFrames
using JSON
using CSV
using Dates

# Helper: run a live test, skipping gracefully on connectivity or upstream errors.
function _try_live(f; service_name="Upstream")
    try
        return f()
    catch e
        if e isa HTTP.ExceptionRequest.StatusError && (e.status == 503 || e.status == 504 || e.status == 429)
            @warn "$service_name service unavailable ($(e.status)). Skipping test."
            return nothing, nothing
        elseif e isa HTTP.Exceptions.HTTPError
            @warn "$service_name connection/timeout error: $e. Skipping test."
            return nothing, nothing
        end
        rethrow(e)
    end
end
