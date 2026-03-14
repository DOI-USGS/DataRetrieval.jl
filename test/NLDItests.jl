# Testing the NLDI functions
include("TestUtils.jl")

# ──────────────────────────────────────────────────────────────────────────────
# Offline parsing tests — deterministic, no network required
# ──────────────────────────────────────────────────────────────────────────────
@testset "NLDI Parsing (offline)" begin

    @testset "basin GeoJSON parsing" begin
        fixture_path = joinpath(@__DIR__, "fixtures", "nldi_basin.json")
        data = JSON.parsefile(fixture_path)
        df = DataRetrieval._nldi_features_to_df(data)

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
        df = DataRetrieval._nldi_features_to_df(data)

        @test nrow(df) > 0
        @test "geometry_type" in names(df)
        @test occursin("LineString", string(df.geometry_type[1]))
    end

    @testset "features GeoJSON parsing (lat/long)" begin
        fixture_path = joinpath(@__DIR__, "fixtures", "nldi_features.json")
        data = JSON.parsefile(fixture_path)
        df = DataRetrieval._nldi_features_to_df(data)

        @test nrow(df) >= 1
        @test "geometry_type" in names(df)
        @test "feature_type" in names(df)
    end

    @testset "features GeoJSON parsing (feature source)" begin
        fixture_path = joinpath(@__DIR__, "fixtures", "nldi_features_source.json")
        data = JSON.parsefile(fixture_path)
        df = DataRetrieval._nldi_features_to_df(data)

        @test nrow(df) >= 1
        @test "feature_type" in names(df)
    end
end

# ──────────────────────────────────────────────────────────────────────────────
# Validation tests — argument constraints (offline)
# ──────────────────────────────────────────────────────────────────────────────
@testset "NLDI Validation" begin
    # invalid navigation mode
    @test_throws ArgumentError readNLDIflowlines("BAD", comid=13294314)

    # lat without long
    @test_throws ArgumentError readNLDIfeatures(lat=43.087)

    # feature_source without feature_id
    @test_throws ArgumentError readNLDIfeatures(feature_source="WQP")

    # invalid find value
    @test_throws ArgumentError searchNLDI(find="bad")

    # comid + basin (not supported)
    @test_throws ArgumentError searchNLDI(find="basin", comid=13294314)

    # feature_source + comid (mutually exclusive)
    @test_throws ArgumentError readNLDIflowlines("UM",
        feature_source="WQP", feature_id="USGS-054279485", comid=13294314)

    # comid without navigation_mode
    @test_throws ArgumentError readNLDIfeatures(comid=13294314)
end

# ──────────────────────────────────────────────────────────────────────────────
# Live endpoint tests — confirm APIs are reachable and return valid data
# ──────────────────────────────────────────────────────────────────────────────
@testset "NLDI Live Endpoint" begin

    # basin query
    df, response = _try_live(service_name="NLDI") do
        readNLDIbasin("WQP", "USGS-054279485")
    end
    if df !== nothing
        @test response.status == 200
        @test nrow(df) > 0
        @test occursin("Polygon", string(df.geometry_type[1]))
    end

    # flowlines query using comid
    df, response = _try_live(service_name="NLDI") do
        readNLDIflowlines("UM", comid=13294314, distance=50)
    end
    if df !== nothing
        @test response.status == 200
        @test nrow(df) > 0
        @test occursin("LineString", string(df.geometry_type[1]))
    end

    # features by feature source (no navigation)
    df, response = _try_live(service_name="NLDI") do
        readNLDIfeatures(feature_source="WQP", feature_id="USGS-054279485")
    end
    if df !== nothing
        @test response.status == 200
        @test nrow(df) > 0
    end

    # features by lat/long
    df, response = _try_live(service_name="NLDI") do
        readNLDIfeatures(lat=43.087, long=-89.509)
    end
    if df !== nothing
        @test response.status == 200
        @test nrow(df) > 0
    end

    # searchNLDI — basin
    result, response = _try_live(service_name="NLDI") do
        searchNLDI(feature_source="WQP", feature_id="USGS-054279485", find="basin")
    end
    if result !== nothing
        @test response.status == 200
        @test isa(result, AbstractDict)
        @test haskey(result, "features")
        @test length(result["features"]) > 0
    end

    # searchNLDI — flowlines
    result, response = _try_live(service_name="NLDI") do
        searchNLDI(feature_source="WQP",
                                  feature_id="USGS-054279485",
                                  navigation_mode="UM",
                                  find="flowlines")
    end
    if result !== nothing
        @test response.status == 200
        @test isa(result, AbstractDict)
        @test haskey(result, "features")
    end

    # searchNLDI — features by lat/long
    result, response = _try_live(service_name="NLDI") do
        searchNLDI(lat=43.087, long=-89.509, find="features")
    end
    if result !== nothing
        @test response.status == 200
        @test isa(result, AbstractDict)
        @test haskey(result, "features")
    end
end
