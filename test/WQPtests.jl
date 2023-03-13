# Testing the WQP functions

@testset "WQP Testing" begin

    # generic data function
    df, response = readWQPdata("ActivityMetric", statecode="US:38",
                               startDateLo="07-01-2006",
                               startDateHi="07-01-2007")
    @test typeof(df) == DataFrame
    @test response.status == 200
    @test isa(response, HTTP.Messages.Response)

    # results query
    df, response = readWQPresults(lat="44.2", long="-88.9", within="0.5")
    @test typeof(df) == DataFrame
    @test response.status == 200
    @test isa(response, HTTP.Messages.Response)

    # sites query
    df, response = whatWQPsites(lat="44.2", long="-88.9", within="2.5")
    @test size(df) == (4, 37)  # matches Python output for same command
    @test response.status == 200
    @test isa(response, HTTP.Messages.Response)

    # organizations query
    df, response = whatWQPorganizations(lat="44.2", long="-88.9", within="2.5")
    @test typeof(df) == DataFrame
    @test response.status == 200
    @test isa(response, HTTP.Messages.Response)

    # projects query
    df, response = whatWQPprojects(lat="44.2", long="-88.9", within="2.5")
    @test typeof(df) == DataFrame
    @test response.status == 200
    @test isa(response, HTTP.Messages.Response)

    # activities query
    df, response = whatWQPactivities(lat="44.2", long="-88.9", within="2.5")
    @test typeof(df) == DataFrame
    @test response.status == 200
    @test isa(response, HTTP.Messages.Response)

    # detection limits query
    df, response = whatWQPdetectionLimits(statecode="US:38",
                                          characteristicName="Nitrite",
                                          startDateLo="07-01-2006",
                                          startDateHi="07-01-2007")
    @test typeof(df) == DataFrame
    @test response.status == 200
    @test isa(response, HTTP.Messages.Response)

    # habitat metrics query
    df, response = whatWQPhabitatMetrics(statecode="US:38")
    @test typeof(df) == DataFrame
    @test response.status == 200
    @test isa(response, HTTP.Messages.Response)

    # project weights query
    df, response = whatWQPprojectWeights(statecode="US:38",
                                         startDateLo="07-01-2006",
                                         startDateHi="07-01-2007")
    @test typeof(df) == DataFrame
    @test response.status == 200
    @test isa(response, HTTP.Messages.Response)

    # activity metrics query
    df, response = whatWQPactivityMetrics(statecode="US:38",
                                          startDateLo="07-01-2006",
                                          startDateHi="07-01-2007")
    @test typeof(df) == DataFrame
    @test response.status == 200
    @test isa(response, HTTP.Messages.Response)

    # private function generic call test
    query_params = Dict("statecode"=>"US:38",
                        "startDateLo"=>"07-01-2006",
                        "startDateHi"=>"07-01-2007")
    df, response = DataRetrieval._genericWQPcall("ActivityMetric",
                                                 query_params)
    @test typeof(df) == DataFrame
    @test response.status == 200
    @test isa(response, HTTP.Messages.Response)

end