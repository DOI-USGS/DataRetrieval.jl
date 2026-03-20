# Testing the WQP functions
isdefined(Main, :_try_live) || include("test_utils.jl")

# ──────────────────────────────────────────────────────────────────────────────
# Offline parsing tests — deterministic, no network required
# ──────────────────────────────────────────────────────────────────────────────
@testset "WQP Parsing (offline)" begin

    @testset "CSV results parsing" begin
        fixture_path = joinpath(@__DIR__, "fixtures", "wqp_results.csv")
        df = DataFrame(CSV.File(fixture_path; comment="#", ignoreemptyrows=true))

        @test nrow(df) > 0
        @test "OrganizationIdentifier" in names(df)
        @test "OrganizationFormalName" in names(df)
        @test "ActivityIdentifier" in names(df)
        @test "CharacteristicName" in names(df)
        @test "ResultMeasureValue" in names(df)
        @test "MonitoringLocationIdentifier" in names(df)

        # spot-check known content from fixture
        @test df.OrganizationIdentifier[1] == "WIDNR_WQX"
        @test occursin("Wisconsin", df.OrganizationFormalName[1])
    end

    @testset "CSV sites parsing" begin
        fixture_path = joinpath(@__DIR__, "fixtures", "wqp_sites.csv")
        df = DataFrame(CSV.File(fixture_path; comment="#", ignoreemptyrows=true))

        @test nrow(df) > 0
        @test "OrganizationIdentifier" in names(df)
        @test "MonitoringLocationIdentifier" in names(df)
    end

    @testset "URL construction" begin
        # Legacy URL
        @test WQP.url("Result") == "https://www.waterqualitydata.us/data/Result/search?"
        # WQX3 URL
        @test WQP.url("Result"; legacy=false) == "https://www.waterqualitydata.us/wqx3/Result/search?"
        # Service not in WQX3 falls back to legacy
        @test WQP.url("Organization"; legacy=false) == "https://www.waterqualitydata.us/data/Organization/search?"
    end

    @testset "mimeType validation" begin
        @test_throws ArgumentError WQP._generic_call("Result", Dict("mimeType" => "geojson"))
        @test_throws ArgumentError WQP._generic_call("Result", Dict("mimeType" => "xml"))
    end
end

# ──────────────────────────────────────────────────────────────────────────────
# Live endpoint tests — confirm APIs are reachable and return meaningful data
# ──────────────────────────────────────────────────────────────────────────────
@testset "WQP Live Endpoint" begin

    # results query — small radial search
    df, response = _try_live(service_name="WQP") do
        WQP.results(lat="44.2", long="-88.9", within="0.5")
    end
    if df !== nothing && nrow(df) > 0
        @test response.status == 200
        @test nrow(df) > 0
        @test "OrganizationIdentifier" in names(df)
        @test "ActivityIdentifier" in names(df)
        @test "CharacteristicName" in names(df)
    elseif df !== nothing
        @warn "WQP results query returned 0 rows. Skipping assertions."
    end

    # sites query — confirm returns data with expected columns
    df, response = _try_live(service_name="WQP") do
        WQP.sites(lat="44.2", long="-88.9", within="2.5")
    end
    if df !== nothing && nrow(df) > 0
        @test response.status == 200
        @test nrow(df) >= 1
        @test "MonitoringLocationIdentifier" in names(df)
        @test "OrganizationIdentifier" in names(df)
    elseif df !== nothing
        @warn "WQP sites query returned 0 rows. Skipping assertions."
    end

    # generic data function
    df, response = _try_live(service_name="WQP") do
        WQP.data("ActivityMetric", state_code="US:38",
                    start_date_lo="07-01-2006",
                    start_date_hi="07-01-2007")
    end
    if df !== nothing && nrow(df) > 0
        @test response.status == 200
        @test nrow(df) > 0
    end

    # organizations query
    df, response = _try_live(service_name="WQP") do
        WQP.organizations(lat="44.2", long="-88.9", within="2.5")
    end
    if df !== nothing && nrow(df) > 0
        @test response.status == 200
        @test nrow(df) > 0
        @test "OrganizationIdentifier" in names(df)
    end

    # projects query
    df, response = _try_live(service_name="WQP") do
        WQP.projects(lat="44.2", long="-88.9", within="2.5")
    end
    if df !== nothing && nrow(df) > 0
        @test response.status == 200
        @test nrow(df) > 0
    end

    # activities query
    df, response = _try_live(service_name="WQP") do
        WQP.activities(lat="44.2", long="-88.9", within="2.5")
    end
    if df !== nothing && nrow(df) > 0
        @test response.status == 200
        @test nrow(df) > 0
    end

    # detection limits query
    df, response = _try_live(service_name="WQP") do
        WQP.detection_limits(site_id="USGS-01594440")
    end
    if df !== nothing && nrow(df) > 0
        @test response.status == 200
        @test nrow(df) > 0
    end

    # habitat metrics query
    df, response = _try_live(service_name="WQP") do
        WQP.habitat_metrics(state_code="US:38")
    end
    if df !== nothing && nrow(df) > 0
        @test response.status == 200
        @test nrow(df) > 0
    end

    # project weights query
    df, response = _try_live(service_name="WQP") do
        WQP.project_weights(state_code="US:38",
                               start_date_lo="01-01-2006",
                               start_date_hi="01-01-2007")
    end
    if df !== nothing && nrow(df) > 0
        @test response.status == 200
        @test nrow(df) > 0
    elseif df !== nothing
        @warn "WQP project weights query returned 0 rows. Skipping assertions."
    end

    # activity metrics query
    df, response = _try_live(service_name="WQP") do
        WQP.activity_metrics(state_code="US:38",
                                start_date_lo="07-01-2006",
                                start_date_hi="07-01-2007")
    end
    if df !== nothing && nrow(df) > 0
        @test response.status == 200
        @test nrow(df) > 0
    end
end