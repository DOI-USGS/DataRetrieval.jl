# Testing the WaterData (USGS Samples) API functions

# Helper: run a live WaterData test, skipping gracefully on connectivity or 429 errors.
isdefined(Main, :_try_live) || include("test_utils.jl")

# ──────────────────────────────────────────────────────────────────────────────
# Offline parsing tests — deterministic, no network required
# ──────────────────────────────────────────────────────────────────────────────
@testset "WaterData Parsing (offline)" begin

    @testset "OGC JSON flattening (daily)" begin
        fixture_path = joinpath(@__DIR__, "fixtures", "waterdata_daily.json")
        parsed = JSON.parsefile(fixture_path)
        df = WaterData._flatten_ogc_features(parsed)

        @test nrow(df) == 3
        @test "monitoring_location_id" in string.(names(df))
        @test "parameter_code" in string.(names(df))
        @test "value" in string.(names(df))
        @test "time" in string.(names(df))

        # check an id column was generated from Feature.id
        @test "id" in string.(names(df))

        # spot-check content
        @test df[1, :monitoring_location_id] == "USGS-05427718"
        @test df[1, :parameter_code] == "00060"
    end

    @testset "OGC rename/cast pipeline" begin
        fixture_path = joinpath(@__DIR__, "fixtures", "waterdata_daily.json")
        parsed = JSON.parsefile(fixture_path)
        df = WaterData._flatten_ogc_features(parsed)
        WaterData._rename_id!(df, "daily_id")

        @test "daily_id" in string.(names(df))
        @test !("id" in string.(names(df)))

        WaterData._cast_columns!(df)
        # value column should be numeric after casting
        @test isa(df[1, :value], Union{Nothing, Float64})
    end

    @testset "Samples CSV parsing" begin
        fixture_path = joinpath(@__DIR__, "fixtures", "waterdata_results.csv")
        df = DataFrame(CSV.File(fixture_path; comment="#", ignoreemptyrows=true))

        @test nrow(df) == 3
        @test "Location_Identifier" in names(df)
        @test "Activity_ActivityIdentifier" in names(df)
        @test "Result_CharacteristicName" in names(df)
        @test "Result_ResultMeasureValue" in names(df)

        @test df[1, Symbol("Location_Identifier")] == "USGS-05288705"
    end

    @testset "Validation checks" begin
        @test_throws ArgumentError WaterData.samples(service="foo", profile="bar")
        @test_throws ArgumentError WaterData.samples(service="results", profile="foo")
        @test_throws ArgumentError WaterData.codes("invalid_service")
        @test_throws ArgumentError WaterData.reference_table("agency-cod")
    end

    @testset "OGC query parameter mapping (parity with R)" begin
        # monitoring_location_id maps to id consistently
        params, nopage = WaterData._prepare_ogc_query(Dict(:monitoring_location_id => "USGS-05427718"), "monitoring-locations")
        @test params["id"] == "USGS-05427718"
        @test !haskey(params, "monitoring_location_number")

        params, nopage = WaterData._prepare_ogc_query(Dict(:monitoring_location_id => "05427718"), "monitoring-locations")
        @test params["id"] == "05427718"

        # monitoring_location_id should NOT map to 'id' for data services (like daily)
        params, nopage = WaterData._prepare_ogc_query(Dict(:monitoring_location_id => "USGS-05427718"), "daily")
        @test params["monitoring_location_id"] == "USGS-05427718"
        @test !haskey(params, "id")

        # service-specific ID maps to 'id'
        params, nopage = WaterData._prepare_ogc_query(Dict(:daily_id => "abc"), "daily")
        @test params["id"] == "abc"

        # properties strip 'id'
        params, nopage = WaterData._prepare_ogc_query(Dict(:properties => ["id", "state_name"]), "monitoring-locations")
        @test params["properties"] == "state_name"

        params, nopage = WaterData._prepare_ogc_query(Dict(:properties => ["monitoring_location_id", "state_name"]), "monitoring-locations")
        @test params["properties"] == "state_name"

        params, nopage = WaterData._prepare_ogc_query(Dict(:properties => ["id"]), "monitoring-locations")
        @test params["properties"] == "id"
    end
end

# ──────────────────────────────────────────────────────────────────────────────
# Live endpoint tests — each group handles 429 independently
# ──────────────────────────────────────────────────────────────────────────────
@testset "WaterData OGC Live" begin
    df, response = _try_live(service_name="WaterData") do
        WaterData.ogc_params("daily")
    end
    if df !== nothing
        @test response.status == 200
        @test haskey(df, "monitoring_location_id")
    end

    df, response = _try_live(service_name="WaterData") do
        WaterData.ogc_requests(endpoint="daily", request_type="queryables")
    end
    if df !== nothing
        @test response.status == 200
        @test isa(df, AbstractDict)
    end

    df, response = _try_live(service_name="WaterData") do
        WaterData.data("daily",
            monitoring_location_id="USGS-05427718",
            parameter_code="00060",
            time="2025-01-01/2025-01-07",
            no_paging=true,
            limit=200)
    end
    if df !== nothing
        @test response.status == 200
        @test nrow(df) > 0
        @test "monitoring_location_id" in string.(names(df))
    end
end

@testset "WaterData Codes Live" begin
    df, response = _try_live(service_name="WaterData") do
        WaterData.codes("states")
    end
    if df !== nothing
        @test response.status == 200
        @test nrow(df) > 0
    end

    df, response = _try_live(service_name="WaterData") do
        WaterData.codes("characteristicgroup")
    end
    if df !== nothing
        @test response.status == 200
        @test nrow(df) > 0
    end
end

@testset "WaterData Samples Live" begin
    df, response = _try_live(service_name="WaterData") do
        WaterData.results(
            profile="narrow",
            monitoring_location_identifier="USGS-05288705",
            activity_start_date_lower="2024-10-01",
            activity_start_date_upper="2025-04-24")
    end
    if df !== nothing
        @test response.status == 200
        @test nrow(df) > 0
        @test "Location_Identifier" in names(df)
        @test "Activity_ActivityIdentifier" in names(df)
    end

    df, response = _try_live(service_name="WaterData") do
        WaterData.locations(
            state_fips="US:55",
            usgs_p_code="00010",
            activity_start_date_lower="2024-10-01",
            activity_start_date_upper="2025-04-24")
    end
    if df !== nothing
        @test response.status == 200
        @test nrow(df) > 0
        @test "Location_Identifier" in names(df)
        @test "Location_Latitude" in names(df)
    end

    df, response = _try_live(service_name="WaterData") do
        WaterData.activities(
            monitoring_location_identifier="USGS-06719505")
    end
    if df !== nothing
        @test response.status == 200
        @test nrow(df) > 0
    end

    df, response = _try_live(service_name="WaterData") do
        WaterData.projects(
            state_fips="US:15",
            activity_start_date_lower="2024-10-01",
            activity_start_date_upper="2025-04-24")
    end
    if df !== nothing
        @test response.status == 200
        @test nrow(df) > 0
        @test "Project_Identifier" in names(df)
    end

    df, response = _try_live(service_name="WaterData") do
        WaterData.organizations(
            profile="count",
            state_fips="US:01")
    end
    if df !== nothing
        @test response.status == 200
        @test nrow(df) >= 1
    end

    df, response = _try_live(service_name="WaterData") do
        WaterData.samples(
            service="locations",
            profile="count",
            bounding_box=[-89.65, 43.06, -89.33, 43.18],
            state_fips="US:55")
    end
    if df !== nothing
        @test response.status == 200
        @test nrow(df) >= 1
    end
end

@testset "WaterData OGC Convenience Live" begin
    df, response = _try_live(service_name="WaterData") do
        WaterData.daily(
            monitoring_location_id="USGS-05427718",
            parameter_code="00060",
            time="2025-01-01/2025-01-07",
            limit=200)
    end
    if df !== nothing
        @test response.status == 200
        @test "daily_id" ∉ string.(names(df))  # daily_id should be dropped
    end

    df, response = _try_live(service_name="WaterData") do
        WaterData.continuous(
            monitoring_location_id="USGS-06904500",
            parameter_code="00065",
            time="2025-01-01/2025-01-03",
            limit=200)
    end
    if df !== nothing
        @test response.status == 200
        @test "continuous_id" in string.(names(df))
    end

    df, response = _try_live(service_name="WaterData") do
        WaterData.monitoring_locations(
            state_name="Connecticut",
            site_type_code="GW",
            limit=500)
    end
    if df !== nothing
        @test response.status == 200
        @test nrow(df) > 0
    end

    df, response = _try_live(service_name="WaterData") do
        WaterData.latest_continuous(
            monitoring_location_id=["USGS-05427718", "USGS-05427719"],
            parameter_code=["00060", "00065"],
            limit=200)
    end
    if df !== nothing
        @test response.status == 200
        @test "latest_continuous_id" in string.(names(df))
    end

    df, response = _try_live(service_name="WaterData") do
        WaterData.latest_daily(
            monitoring_location_id=["USGS-05427718", "USGS-05427719"],
            parameter_code=["00060", "00065"],
            limit=200)
    end
    if df !== nothing
        @test response.status == 200
        @test "latest_daily_id" in string.(names(df))
    end

    df, response = _try_live(service_name="WaterData") do
        WaterData.field_measurements(
            monitoring_location_id="USGS-05427718",
            unit_of_measure="ft^3/s",
            time="2025-01-01/2025-10-01",
            skip_geometry=true,
            limit=200)
    end
    if df !== nothing
        @test response.status == 200
        @test "field_measurement_id" in string.(names(df))
    end

    df, response = _try_live(service_name="WaterData") do
        WaterData.channel_measurements(
            monitoring_location_id="USGS-02238500",
            limit=200,
            skip_geometry=true)
    end
    if df !== nothing
        @test response.status == 200
    end

    df, response = _try_live(service_name="WaterData") do
        WaterData.field_metadata(
            monitoring_location_id="USGS-02238500",
            limit=200,
            skip_geometry=true)
    end
    if df !== nothing
        @test response.status == 200
    end

    df, response = _try_live(service_name="WaterData") do
        WaterData.combined_metadata(
            monitoring_location_id="USGS-05407000",
            limit=200,
            skip_geometry=true)
    end
    if df !== nothing
        @test response.status == 200
    end

    df, response = _try_live(service_name="WaterData") do
        WaterData.series_metadata(
            bbox=[-89.840355, 42.853411, -88.818626, 43.422598],
            parameter_code=["00060", "00065", "72019"],
            skip_geometry=true,
            limit=1000)
    end
    if df !== nothing
        @test response.status == 200
        @test nrow(df) > 0
    end
end

@testset "WaterData Reference Tables Live" begin
    df, response = _try_live(service_name="WaterData") do
        WaterData.reference_table("agency-codes")
    end
    if df !== nothing
        @test response.status == 200
        @test nrow(df) > 0
    end

    df, response = _try_live(service_name="WaterData") do
        WaterData.reference_table("agency-codes";
                                     query=Dict("id" => "AK001,AK008", "limit" => "20"))
    end
    if df !== nothing
        @test response.status == 200
        @test nrow(df) >= 1
    end
end

@testset "WaterData Stats Live" begin
    df, response = _try_live(service_name="WaterData") do
        WaterData.stats_por(
            monitoring_location_id="USGS-12451000",
            parameter_code="00060",
            start_date="01-01",
            end_date="01-01")
    end
    if df !== nothing
        @test response.status == 200
        @test nrow(df) > 0
    end

    df, response = _try_live(service_name="WaterData") do
        WaterData.stats_date_range(
            monitoring_location_id="USGS-12451000",
            parameter_code="00060",
            start_date="2025-01-01",
            end_date="2025-01-01",
            computation_type="maximum")
    end
    if df !== nothing
        @test response.status == 200
        @test nrow(df) > 0
    end
end