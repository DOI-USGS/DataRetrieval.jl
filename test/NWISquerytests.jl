# Tests of NWIS query functions

@testset "NWIS queries" begin
    # Tests of functions that actually perform NWIS queries
    # Ensure return is a populated DataFrame with expected structure

    # pCode service is decommissioned
    @test_throws ArgumentError readNWISpCode("00060")

    # daily values — known site and date range
    df, response = readNWISdv("02177000", "00060",
                              startDate="2012-09-01", endDate="2012-09-02")
    @test isa(df, DataFrames.DataFrame)
    @test isa(response, HTTP.Messages.Response)
    @test response.status == 200
    @test nrow(df) > 0
    @test "agency_cd" in names(df)
    @test "site_no" in names(df)
    @test "datetime" in names(df)
    @test df.agency_cd[1] == "USGS"
    @test df.site_no[1] == "02177000"

    # site info — single site
    df, response = readNWISsite("05212700")
    @test isa(df, DataFrames.DataFrame)
    @test response.status == 200
    @test nrow(df) >= 1
    @test "agency_cd" in names(df)
    @test "site_no" in names(df)
    @test "station_nm" in names(df)
    @test df.agency_cd[1] == "USGS"
    @test df.site_no[1] == "05212700"

    # site info — multiple sites
    df, response = readNWISsite(["07334200", "05212700"])
    @test isa(df, DataFrames.DataFrame)
    @test response.status == 200
    @test nrow(df) >= 2
    @test "site_no" in names(df)

    # unit/instantaneous data
    df, response = readNWISunit("01646500", "00060",
                                startDate="2022-12-29",
                                endDate="2022-12-29")
    @test isa(df, DataFrames.DataFrame)
    @test response.status == 200
    @test nrow(df) > 0
    @test "agency_cd" in names(df)
    @test "site_no" in names(df)
    @test "datetime" in names(df)
    @test "tz_cd" in names(df)
    @test df.agency_cd[1] == "USGS"
    @test df.site_no[1] == "01646500"
end

@testset "NWIS decommission messaging" begin
    # qw endpoint should be retired with an actionable error
    @test_throws ArgumentError readNWISqw("01646500")
    @test_throws ArgumentError readNWISqwdata("01646500")
end
