# Tests of RDB parsing — offline fixtures + slim live endpoint checks

const FIXTURES_DIR = joinpath(@__DIR__, "fixtures")

# Helper: build a mock HTTP.Messages.Response from a fixture file
function _mock_response(fixture_name; content_type="text/plain")
    body = read(joinpath(FIXTURES_DIR, fixture_name))
    response = HTTP.Messages.Response(200)
    response.body = body
    HTTP.setheader(response, "Content-Type" => content_type)
    return response
end

# ──────────────────────────────────────────────────────────────────────────────
# Offline parsing tests — deterministic, no network required
# ──────────────────────────────────────────────────────────────────────────────
@testset "RDB Parsing (offline)" begin

    @testset "single parameter daily values" begin
        response = _mock_response("nwis_dv_single.rdb")
        df = DataRetrieval._readRDB(response)

        # dimensions
        @test nrow(df) == 31
        @test ncol(df) == 5

        # expected columns
        @test "agency_cd" in names(df)
        @test "site_no" in names(df)
        @test "datetime" in names(df)

        # leading zeros preserved in site_no
        @test df.site_no[1] == "02177000"
        @test all(x -> x == "02177000", df.site_no)

        # agency code
        @test df.agency_cd[1] == "USGS"

        # first row content
        @test string(df.datetime[1]) == "2012-09-01"
        @test isa(df.datetime[1], Dates.Date)

        # data value is numeric
        val_col = names(df)[4]  # the discharge value column
        @test isa(df[1, val_col], Number)
        @test df[1, val_col] == 191

        # last row content
        @test string(df.datetime[end]) == "2012-10-01"
        @test df[end, val_col] == 365

        # approval code column
        cd_col = names(df)[5]
        @test df[1, cd_col] == "A"
    end

    @testset "multiple parameter daily values" begin
        response = _mock_response("nwis_dv_multi.rdb")
        df = DataRetrieval._readRDB(response)

        # dimensions
        @test nrow(df) == 31
        @test ncol(df) == 9

        # expected columns
        @test "agency_cd" in names(df)
        @test "site_no" in names(df)
        @test "datetime" in names(df)

        # leading zeros preserved
        @test df.site_no[1] == "04085427"

        # first row values (cross-checked with R dataRetrieval)
        @test df.agency_cd[1] == "USGS"
        @test string(df.datetime[1]) == "2012-09-01"
    end

    @testset "site info" begin
        response = _mock_response("nwis_site.rdb")
        df = DataRetrieval._readRDB(response)

        @test nrow(df) == 1
        @test "agency_cd" in names(df)
        @test "site_no" in names(df)
        @test "station_nm" in names(df)
        @test "dec_lat_va" in names(df)

        @test df.agency_cd[1] == "USGS"
        @test df.site_no[1] == "05114000"
        @test occursin("SOURIS RIVER", df.station_nm[1])
    end

    @testset "instantaneous/unit values" begin
        response = _mock_response("nwis_uv.rdb")
        df = DataRetrieval._readRDB(response)

        @test nrow(df) > 0
        @test "agency_cd" in names(df)
        @test "site_no" in names(df)
        @test "datetime" in names(df)
        @test "tz_cd" in names(df)

        @test df.agency_cd[1] == "USGS"
        @test df.site_no[1] == "01646500"
    end

    @testset "HTML error page detection" begin
        # Simulate an HTML error response (decommissioned endpoint redirect)
        response = HTTP.Messages.Response(200)
        response.body = Vector{UInt8}("""
        <html><body>
        <p>This service has moved. Visit
        <a href="https://help.waterdata.usgs.gov">help.waterdata.usgs.gov</a></p>
        </body></html>
        """)
        HTTP.setheader(response, "Content-Type" => "text/html")
        @test_throws ArgumentError DataRetrieval._readRDB(response)
    end

end

# ──────────────────────────────────────────────────────────────────────────────
# Live endpoint tests — confirm APIs are reachable and return valid data
# ──────────────────────────────────────────────────────────────────────────────
@testset "RDB Live Endpoint" begin

    @testset "daily values round-trip" begin
        obs_url = "https://waterservices.usgs.gov/nwis/dv/?site=02177000&format=rdb,1.0&ParameterCd=00060&StatCd=00003&startDT=2012-09-01&endDT=2012-10-01"
        df, response = readNWIS(obs_url)

        @test response.status == 200
        @test nrow(df) > 0
        @test "agency_cd" in names(df)
        @test "site_no" in names(df)
        @test df.agency_cd[1] == "USGS"
        @test df.site_no[1] == "02177000"
        @test string(df.datetime[1]) == "2012-09-01"
        @test isa(df.datetime[1], Dates.Date)
    end

end