# Testing the WQP functions

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
        @test constructWQPURL("Result") == "https://www.waterqualitydata.us/data/Result/search?"
        # WQX3 URL
        @test constructWQPURL("Result"; legacy=false) == "https://www.waterqualitydata.us/wqx3/Result/search?"
        # Service not in WQX3 falls back to legacy
        @test constructWQPURL("Organization"; legacy=false) == "https://www.waterqualitydata.us/data/Organization/search?"
    end

    @testset "mimeType validation" begin
        @test_throws ArgumentError DataRetrieval._genericWQPcall("Result", Dict("mimeType" => "geojson"))
        @test_throws ArgumentError DataRetrieval._genericWQPcall("Result", Dict("mimeType" => "xml"))
    end
end

# ──────────────────────────────────────────────────────────────────────────────
# Live endpoint tests — confirm APIs are reachable and return meaningful data
# ──────────────────────────────────────────────────────────────────────────────
@testset "WQP Live Endpoint" begin

    # results query — small radial search
    df, response = readWQPresults(lat="44.2", long="-88.9", within="0.5")
    @test response.status == 200
    @test nrow(df) > 0
    @test "OrganizationIdentifier" in names(df)
    @test "ActivityIdentifier" in names(df)
    @test "CharacteristicName" in names(df)

    # sites query — confirm returns data with expected columns
    df, response = whatWQPsites(lat="44.2", long="-88.9", within="2.5")
    @test response.status == 200
    @test nrow(df) >= 1
    @test "MonitoringLocationIdentifier" in names(df)
    @test "OrganizationIdentifier" in names(df)

    # generic data function
    df, response = readWQPdata("ActivityMetric", statecode="US:38",
                               startDateLo="07-01-2006",
                               startDateHi="07-01-2007")
    @test response.status == 200
    @test nrow(df) > 0

    # organizations query
    df, response = whatWQPorganizations(lat="44.2", long="-88.9", within="2.5")
    @test response.status == 200
    @test nrow(df) > 0
    @test "OrganizationIdentifier" in names(df)

    # projects query
    df, response = whatWQPprojects(lat="44.2", long="-88.9", within="2.5")
    @test response.status == 200
    @test nrow(df) > 0

    # activities query
    df, response = whatWQPactivities(lat="44.2", long="-88.9", within="2.5")
    @test response.status == 200
    @test nrow(df) > 0

    # detection limits query
    df, response = whatWQPdetectionLimits(siteid="USGS-01594440")
    @test response.status == 200
    @test nrow(df) > 0

    # habitat metrics query
    df, response = whatWQPhabitatMetrics(statecode="US:38")
    @test response.status == 200
    @test nrow(df) > 0

    # project weights query
    df, response = whatWQPprojectWeights(statecode="US:38",
                                         startDateLo="07-01-2006",
                                         startDateHi="07-01-2007")
    @test response.status == 200
    @test nrow(df) > 0

    # activity metrics query
    df, response = whatWQPactivityMetrics(statecode="US:38",
                                          startDateLo="07-01-2006",
                                          startDateHi="07-01-2007")
    @test response.status == 200
    @test nrow(df) > 0
end