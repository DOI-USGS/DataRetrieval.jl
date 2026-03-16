# Testing the NLDI functions
isdefined(Main, :_try_live) || include("test_utils.jl")

# ──────────────────────────────────────────────────────────────────────────────
# Offline parsing tests — deterministic, no network required
# ──────────────────────────────────────────────────────────────────────────────
@testset "NLDI Parsing (offline)" begin

    @testset "basin GeoJSON parsing" begin
        fixture_path = joinpath(@__DIR__, "fixtures", "nldi_basin.json")
        data = JSON.parsefile(fixture_path)
        df = NLDI._features_to_df(data)

        @test nrow(df) >= 1
        @test "geometry_type" in names(df)
        @test "coordinates" in names(df)
        @test "feature_type" in names(df)
        @test occursin("Polygon", string(df.geometry_type[1]))
        @test df.feature_type[1] == "Feature"
        # basin coordinates should be a nested array
        @test isa(df.coordinates[1], AbstractArray)
    end

    @testset "flowlines GeoJSON parsing" begin
        fixture_path = joinpath(@__DIR__, "fixtures", "nldi_flowlines.json")
        data = JSON.parsefile(fixture_path)
        df = NLDI._features_to_df(data)

        @test nrow(df) > 0
        @test "geometry_type" in names(df)
        @test occursin("LineString", string(df.geometry_type[1]))
    end

    @testset "features GeoJSON parsing (lat/long)" begin
        fixture_path = joinpath(@__DIR__, "fixtures", "nldi_features.json")
        data = JSON.parsefile(fixture_path)
        df = NLDI._features_to_df(data)

        @test nrow(df) >= 1
        @test "geometry_type" in names(df)
        @test "feature_type" in names(df)
    end

    @testset "features GeoJSON parsing (feature source)" begin
        fixture_path = joinpath(@__DIR__, "fixtures", "nldi_features_source.json")
        data = JSON.parsefile(fixture_path)
        df = NLDI._features_to_df(data)

        @test nrow(df) >= 1
        @test "feature_type" in names(df)
    end
end

# ──────────────────────────────────────────────────────────────────────────────
# Validation tests — argument constraints (offline)
# ──────────────────────────────────────────────────────────────────────────────
@testset "NLDI Validation" begin
    # invalid navigation mode
    @test_throws ArgumentError NLDI.flowlines("BAD", comid=13294314)

    # lat without long
    @test_throws ArgumentError NLDI.features(lat=43.087)

    # feature_source without feature_id
    @test_throws ArgumentError NLDI.features(feature_source="WQP")

    # invalid find value
    @test_throws ArgumentError NLDI.search(find="bad")

    # comid + basin (not supported)
    @test_throws ArgumentError NLDI.search(find="basin", comid=13294314)

    # feature_source + comid (mutually exclusive)
    @test_throws ArgumentError NLDI.flowlines("UM",
        feature_source="WQP", feature_id="USGS-054279485", comid=13294314)

    # comid without navigation_mode
    @test_throws ArgumentError NLDI.features(comid=13294314)
end

# ──────────────────────────────────────────────────────────────────────────────
# Live endpoint tests — confirm APIs are reachable and return valid data
# ──────────────────────────────────────────────────────────────────────────────
@testset "NLDI Live Endpoint" begin

    # basin query
    df, response = _try_live(service_name="NLDI") do
        NLDI.basin("WQP", "USGS-054279485")
    end
    if df !== nothing
        @test response.status == 200
        @test nrow(df) > 0
        @test occursin("Polygon", string(df.geometry_type[1]))
    end

    # flowlines query using comid
    df, response = _try_live(service_name="NLDI") do
        NLDI.flowlines("UM", comid=13294314, distance=50)
    end
    if df !== nothing
        @test response.status == 200
        @test nrow(df) > 0
        @test occursin("LineString", string(df.geometry_type[1]))
    end

    # features by feature source (no navigation)
    df, response = _try_live(service_name="NLDI") do
        NLDI.features(feature_source="WQP", feature_id="USGS-054279485")
    end
    if df !== nothing
        @test response.status == 200
        @test nrow(df) > 0
    end

    # features by lat/long
    df, response = _try_live(service_name="NLDI") do
        NLDI.features(lat=43.087, long=-89.509)
    end
    if df !== nothing
        @test response.status == 200
        @test nrow(df) > 0
    end

    # searchNLDI — basin
    result, response = _try_live(service_name="NLDI") do
        NLDI.search(feature_source="WQP", feature_id="USGS-054279485", find="basin", as_json=true)
    end
    if result !== nothing
        @test response.status == 200
        @test isa(result, AbstractDict)
        @test haskey(result, "features")
        @test length(result["features"]) > 0
    end

    # searchNLDI — flowlines
    result, response = _try_live(service_name="NLDI") do
        NLDI.search(feature_source="WQP",
                                  feature_id="USGS-054279485",
                                  navigation_mode="UM",
                                  find="flowlines",
                                  as_json=true)
    end
    if result !== nothing
        @test response.status == 200
        @test isa(result, AbstractDict)
        @test haskey(result, "features")
    end

    # searchNLDI — features by lat/long
    result, response = _try_live(service_name="NLDI") do
        NLDI.search(lat=43.087, long=-89.509, find="features", as_json=true)
    end
    if result !== nothing
        @test response.status == 200
        @test isa(result, AbstractDict)
        @test haskey(result, "features")
    end
end
