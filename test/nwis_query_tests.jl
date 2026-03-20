# Tests of NWIS query functions
isdefined(Main, :_try_live) || include("test_utils.jl")

@testset "NWIS queries" begin
    # Tests of functions that actually perform NWIS queries
    # Ensure return is a populated DataFrame with expected structure

    # pCode service is decommissioned
    @test_throws ArgumentError NWIS.pcode("00060")

    # daily values — known site and date range
    df, response = _try_live(service_name="NWIS") do
        NWIS.dv("02177000", "00060",
                   start_date="2012-09-01", end_date="2012-09-02")
    end
    if df !== nothing
        @test isa(df, DataFrames.DataFrame)
        @test response.status == 200
        @test nrow(df) > 0
        @test "agency_cd" in names(df)
        @test "site_no" in names(df)
        @test "datetime" in names(df)
        @test df.agency_cd[1] == "USGS"
        @test df.site_no[1] == "02177000"
    end

    # site info — single site
    df, response = _try_live(service_name="NWIS") do
        NWIS.site("05212700")
    end
    if df !== nothing
        @test isa(df, DataFrames.DataFrame)
        @test response.status == 200
        @test nrow(df) >= 1
        @test "agency_cd" in names(df)
        @test "site_no" in names(df)
        @test "station_nm" in names(df)
        @test df.agency_cd[1] == "USGS"
        @test df.site_no[1] == "05212700"
    end

    # site info — multiple sites
    df, response = _try_live(service_name="NWIS") do
        NWIS.site(["07334200", "05212700"])
    end
    if df !== nothing
        @test isa(df, DataFrames.DataFrame)
        @test response.status == 200
        @test nrow(df) >= 2
        @test "site_no" in names(df)
    end

    # unit/instantaneous data
    df, response = _try_live(service_name="NWIS") do
        NWIS.unit("01646500", "00060",
                     start_date="2022-12-29",
                     end_date="2022-12-29")
    end
    if df !== nothing
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
end

@testset "NWIS decommission messaging" begin
    # qw endpoint should be retired with an actionable error
    @test_throws ArgumentError NWIS.qw("01646500")
    @test_throws ArgumentError NWIS.qw_data("01646500", "00060")
end
