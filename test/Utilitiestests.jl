# Testing utilities functions

@testset "Utilities Testing" begin

    # test the custom get function (wrapper around HTTP.request)

    # no query params
    url = "https://www.google.com";
    response = DataRetrieval._custom_get(url);
    @test response.status == 200
    @test isa(response, HTTP.Messages.Response)
    @test response.request.headers[1][1] == "user-agent"

    # with query params
    url = constructWQPURL("ActivityMetric");
    query_params = Dict("statecode"=>"US:38",
                        "startDateLo"=>"07-01-2006",
                        "startDateHi"=>"07-01-2007");
    response_qp = DataRetrieval._custom_get(url, query_params=query_params);
    @test response_qp.status == 200
    @test isa(response_qp, HTTP.Messages.Response)
    @test response_qp.request.headers[1][1] == "user-agent"

    # API token wiring: ENV fallback and runtime override.
    previous_env = get(ENV, "API_USGS_PAT", nothing)
    try
        # --- Case 1: no token at all ---
        pop!(ENV, "API_USGS_PAT", nothing)
        clearUSGSAPIToken!()
        headers_none = Dict(DataRetrieval._default_headers())
        @test get(headers_none, "X-Api-Key", nothing) === nothing
        @test haskey(headers_none, "user-agent")

        # --- Case 2: ENV token ---
        ENV["API_USGS_PAT"] = "env-token"
        headers_env = Dict(DataRetrieval._default_headers())
        @test get(headers_env, "X-Api-Key", nothing) == "env-token"

        # --- Case 3: runtime override takes priority ---
        setUSGSAPIToken!("runtime-token")
        headers_runtime = Dict(DataRetrieval._default_headers())
        @test get(headers_runtime, "X-Api-Key", nothing) == "runtime-token"

        # --- Case 4: clear runtime, fall back to ENV ---
        clearUSGSAPIToken!()
        headers_cleared = Dict(DataRetrieval._default_headers())
        @test get(headers_cleared, "X-Api-Key", nothing) == "env-token"
    finally
        clearUSGSAPIToken!()
        if previous_env === nothing
            pop!(ENV, "API_USGS_PAT", nothing)
        else
            ENV["API_USGS_PAT"] = previous_env
        end
    end

end