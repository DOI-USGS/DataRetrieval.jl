# Tests of RDB parsing
using Dates

@testset "RDB Parsing" begin
    # These tests take functional URLs and query the NWIS system with them.
    # Specific cases are taken / inspired by those in the R package test suite.
    # Some of the testing values are taken from the returns when analogous
    # functions are run in R dataRetrieval. Others are based on what the
    # expected output is. Draws from tests_inports.R and tests_general.R

    # single parameter
    obs_url = "https://waterservices.usgs.gov/nwis/dv/?site=02177000&format=rdb,1.0&ParameterCd=00060&StatCd=00003&startDT=2012-09-01&endDT=2012-10-01"
    df = readNWIS(obs_url)
    @test first(df)[1] == "USGS"
    @test first(df)[2] == 2177000
    @test first(df)[3] == Dates.Date(2012, 09, 01)
    @test first(df)[4] == 191
    @test first(df)[5] == "A"

    # multiple parameters
    obs_url = "https://waterservices.usgs.gov/nwis/dv/?site=04085427&format=rdb,1.0&ParameterCd=00060,00010&StatCd=00003,00001&startDT=2012-09-01&endDT=2012-10-01"
    df = readNWIS(obs_url)
    @test size(df) == (31, 9)
    @test first(df)[1] == "USGS"
    @test first(df)[2] == 4085427
    @test first(df)[3] == Dates.Date(2012, 09, 01)
    @test first(df)[4] == 24.9
    @test first(df)[5] == "A"
    @test first(df)[6] == 23.1
    @test first(df)[7] == "A"
    @test first(df)[8] == 46.4
    @test first(df)[9] == "A"




end