# Testing the WaterData (USGS Samples) API functions

# Helper: run a live WaterData test, skipping gracefully on 429 rate limits.
# Returns (df, response) on success or (nothing, nothing) on 429.
function _try_waterdata(f)
    try
        return f()
    catch e
        if e isa HTTP.Exceptions.StatusError && e.status == 429
            @warn "WaterData API rate limit (429). Skipping this test."
            return nothing, nothing
        end
        rethrow(e)
    end
end

# ──────────────────────────────────────────────────────────────────────────────
# Offline parsing tests — deterministic, no network required
# ──────────────────────────────────────────────────────────────────────────────
@testset "WaterData Parsing (offline)" begin

    @testset "OGC JSON flattening (daily)" begin
        fixture_path = joinpath(@__DIR__, "fixtures", "waterdata_daily.json")
        parsed = JSON.parsefile(fixture_path)
        df = DataRetrieval._waterdata_flatten_ogc_features(parsed)

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
        df = DataRetrieval._waterdata_flatten_ogc_features(parsed)
        DataRetrieval._waterdata_rename_id!(df, "daily_id")

        @test "daily_id" in string.(names(df))
        @test !("id" in string.(names(df)))

        DataRetrieval._waterdata_cast_columns!(df)
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
        @test_throws ArgumentError readWaterDataSamples(service="foo", profile="bar")
        @test_throws ArgumentError readWaterDataSamples(service="results", profile="foo")
        @test_throws ArgumentError readWaterDataCodes("invalid_service")
        @test_throws ArgumentError readWaterDataReferenceTable("agency-cod")
    end
end

# ──────────────────────────────────────────────────────────────────────────────
# Live endpoint tests — each group handles 429 independently
# ──────────────────────────────────────────────────────────────────────────────
@testset "WaterData OGC Live" begin
    df, response = _try_waterdata() do
        getWaterDataOGCParams("daily")
    end
    if df !== nothing
        @test response.status == 200
        @test haskey(df, "monitoring_location_id")
    end

    df, response = _try_waterdata() do
        checkWaterDataOGCRequests(endpoint="daily", request_type="queryables")
    end
    if df !== nothing
        @test response.status == 200
        @test isa(df, AbstractDict)
    end

    df, response = _try_waterdata() do
        readWaterData("daily",
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
    df, response = _try_waterdata() do
        readWaterDataCodes("states")
    end
    if df !== nothing
        @test response.status == 200
        @test nrow(df) > 0
    end

    df, response = _try_waterdata() do
        readWaterDataCodes("characteristicgroup")
    end
    if df !== nothing
        @test response.status == 200
        @test nrow(df) > 0
    end
end

@testset "WaterData Samples Live" begin
    df, response = _try_waterdata() do
        readWaterDataResults(
            profile="narrow",
            monitoringLocationIdentifier="USGS-05288705",
            activityStartDateLower="2024-10-01",
            activityStartDateUpper="2025-04-24")
    end
    if df !== nothing
        @test response.status == 200
        @test nrow(df) > 0
        @test "Location_Identifier" in names(df)
        @test "Activity_ActivityIdentifier" in names(df)
    end

    df, response = _try_waterdata() do
        whatWaterDataLocations(
            stateFips="US:55",
            usgsPCode="00010",
            activityStartDateLower="2024-10-01",
            activityStartDateUpper="2025-04-24")
    end
    if df !== nothing
        @test response.status == 200
        @test nrow(df) > 0
        @test "Location_Identifier" in names(df)
        @test "Location_Latitude" in names(df)
    end

    df, response = _try_waterdata() do
        whatWaterDataActivities(
            monitoringLocationIdentifier="USGS-06719505")
    end
    if df !== nothing
        @test response.status == 200
        @test nrow(df) > 0
    end

    df, response = _try_waterdata() do
        whatWaterDataProjects(
            stateFips="US:15",
            activityStartDateLower="2024-10-01",
            activityStartDateUpper="2025-04-24")
    end
    if df !== nothing
        @test response.status == 200
        @test nrow(df) > 0
        @test "Project_Identifier" in names(df)
    end

    df, response = _try_waterdata() do
        whatWaterDataOrganizations(
            profile="count",
            stateFips="US:01")
    end
    if df !== nothing
        @test response.status == 200
        @test nrow(df) >= 1
    end

    df, response = _try_waterdata() do
        readWaterDataSamples(
            service="locations",
            profile="count",
            boundingBox=[-89.65, 43.06, -89.33, 43.18],
            stateFips="US:55")
    end
    if df !== nothing
        @test response.status == 200
        @test nrow(df) >= 1
    end
end

@testset "WaterData OGC Convenience Live" begin
    df, response = _try_waterdata() do
        readWaterDataDaily(
            monitoring_location_id="USGS-05427718",
            parameter_code="00060",
            time="2025-01-01/2025-01-07",
            limit=200)
    end
    if df !== nothing
        @test response.status == 200
        @test "daily_id" ∉ string.(names(df))  # daily_id should be dropped
    end

    df, response = _try_waterdata() do
        readWaterDataContinuous(
            monitoring_location_id="USGS-06904500",
            parameter_code="00065",
            time="2025-01-01/2025-01-03",
            limit=200)
    end
    if df !== nothing
        @test response.status == 200
        @test "continuous_id" in string.(names(df))
    end

    df, response = _try_waterdata() do
        whatWaterDataMonitoringLocations(
            state_name="Connecticut",
            site_type_code="GW",
            limit=500)
    end
    if df !== nothing
        @test response.status == 200
        @test nrow(df) > 0
    end

    df, response = _try_waterdata() do
        readWaterDataLatestContinuous(
            monitoring_location_id=["USGS-05427718", "USGS-05427719"],
            parameter_code=["00060", "00065"],
            limit=200)
    end
    if df !== nothing
        @test response.status == 200
        @test "latest_continuous_id" in string.(names(df))
    end

    df, response = _try_waterdata() do
        readWaterDataLatestDaily(
            monitoring_location_id=["USGS-05427718", "USGS-05427719"],
            parameter_code=["00060", "00065"],
            limit=200)
    end
    if df !== nothing
        @test response.status == 200
        @test "latest_daily_id" in string.(names(df))
    end

    df, response = _try_waterdata() do
        readWaterDataFieldMeasurements(
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

    df, response = _try_waterdata() do
        readWaterDataChannelMeasurements(
            monitoring_location_id="USGS-02238500",
            limit=200,
            skip_geometry=true)
    end
    if df !== nothing
        @test response.status == 200
    end

    df, response = _try_waterdata() do
        readWaterDataFieldMetadata(
            monitoring_location_id="USGS-02238500",
            limit=200,
            skip_geometry=true)
    end
    if df !== nothing
        @test response.status == 200
    end

    df, response = _try_waterdata() do
        readWaterDataCombinedMetadata(
            monitoring_location_id="USGS-05407000",
            limit=200,
            skip_geometry=true)
    end
    if df !== nothing
        @test response.status == 200
    end

    df, response = _try_waterdata() do
        readWaterDataTimeSeriesMetadata(
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
    df, response = _try_waterdata() do
        readWaterDataReferenceTable("agency-codes")
    end
    if df !== nothing
        @test response.status == 200
        @test nrow(df) > 0
    end

    df, response = _try_waterdata() do
        readWaterDataReferenceTable("agency-codes";
                                    query=Dict("id" => "AK001,AK008", "limit" => "20"))
    end
    if df !== nothing
        @test response.status == 200
        @test nrow(df) >= 1
    end
end

@testset "WaterData Stats Live" begin
    df, response = _try_waterdata() do
        readWaterDataStatsPOR(
            monitoring_location_id="USGS-12451000",
            parameter_code="00060",
            start_date="01-01",
            end_date="01-01")
    end
    if df !== nothing
        @test response.status == 200
        @test nrow(df) > 0
    end

    df, response = _try_waterdata() do
        readWaterDataStatsDateRange(
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