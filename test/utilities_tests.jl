# Testing utilities functions
isdefined(Main, :_try_live) || include("test_utils.jl")

@testset "Utilities Testing" begin

    # test the custom get function (wrapper around HTTP.request)

    # no query params - use a local mock server to avoid network dependency
    let
        mock_server = HTTP.serve!("127.0.0.1", 0; listenany=true, verbose=-1) do req
            HTTP.Response(200, "mock")
        end
        mock_port = HTTP.port(mock_server)
        try
            url = "http://127.0.0.1:$mock_port/"
            response = DataRetrieval._custom_get(url)
            @test response.status == 200
            @test isa(response, HTTP.Messages.Response)
            @test response.request.headers[1][1] == "user-agent"
        finally
            close(mock_server)
        end
    end

    # with query params
    url = WQP.url("ActivityMetric");
    query_params = Dict("statecode"=>"US:38",
                        "startDateLo"=>"07-01-2006",
                        "startDateHi"=>"07-01-2007");
    response_qp, _ = _try_live(service_name="WQP") do
        (DataRetrieval._custom_get(url, query_params=query_params), nothing)
    end
    if response_qp !== nothing
        @test response_qp.status == 200
        @test isa(response_qp, HTTP.Messages.Response)
        @test response_qp.request.headers[1][1] == "user-agent"
    end

    # API token wiring: ENV fallback and runtime override.
    previous_env = get(ENV, "API_USGS_PAT", nothing)
    try
        # --- Case 1: no token at all ---
        pop!(ENV, "API_USGS_PAT", nothing)
        clear_token!()
        headers_none = Dict(DataRetrieval._default_headers())
        @test get(headers_none, "X-Api-Key", nothing) === nothing
        @test haskey(headers_none, "user-agent")

        # --- Case 2: ENV token ---
        ENV["API_USGS_PAT"] = "env-token"
        headers_env = Dict(DataRetrieval._default_headers())
        @test get(headers_env, "X-Api-Key", nothing) == "env-token"

        # --- Case 3: runtime override takes priority ---
        set_token!("runtime-token")
        headers_runtime = Dict(DataRetrieval._default_headers())
        @test get(headers_runtime, "X-Api-Key", nothing) == "runtime-token"

        # --- Case 4: clear runtime, fall back to ENV ---
        clear_token!()
        headers_cleared = Dict(DataRetrieval._default_headers())
        @test get(headers_cleared, "X-Api-Key", nothing) == "env-token"
    finally
        clear_token!()
        if previous_env === nothing
            pop!(ENV, "API_USGS_PAT", nothing)
        else
            ENV["API_USGS_PAT"] = previous_env
        end
    end

end