# Tests of NWIS query functions

@testset "NWIS queries" begin
    # Tests of functions that actually perform NWIS queries
    # Ensure return is expected data frame and HTTP response

    # single pCode
    property = "00060"
    df, md = readNWISpCode(property)
    # just test types
    @test isa(df, DataFrames.DataFrame)
    @test isa(md, HTTP.Messages.Response)


    # unit data
    df, response = readNWISunit("01646500", "00060",
                                startDate="2022-12-29",
                                endDate="2022-12-29")
    # just test types
    @test isa(df, DataFrames.DataFrame)
    @test isa(response, HTTP.Messages.Response)


    # daily values
    siteNumber = "02177000"
    startDate = "2012-09-01"
    endDate = "2012-09-02"
    property = "00060"
    df, md = readNWISdv(siteNumber, property,
                        startDate=startDate, endDate=endDate)
    # just test types
    @test isa(df, DataFrames.DataFrame)
    @test isa(md, HTTP.Messages.Response)


    # inactive site URL
    inactiveSite = "05212700"
    df, md = readNWISsite(inactiveSite)
    # just test types
    @test isa(df, DataFrames.DataFrame)
    @test isa(md, HTTP.Messages.Response)


    # combo inactive / active sites
    inactiveAndActive = ["07334200", "05212700"]
    df, md = readNWISsite(inactiveAndActive)
    # just test types
    @test isa(df, DataFrames.DataFrame)
    @test isa(md, HTTP.Messages.Response)


    # unit URL
    siteNumber = "01594440"
    pCode = ["00060", "00010"]
    startDate = "2012-06-28"
    endDate = "2012-06-29"
    df, md = readNWISunit(siteNumber, pCode,
                          startDate=startDate, endDate=endDate)
    # just test types
    @test isa(df, DataFrames.DataFrame)
    @test isa(md, HTTP.Messages.Response)


end
