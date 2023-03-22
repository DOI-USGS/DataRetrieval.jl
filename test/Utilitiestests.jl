# Testing utilities functions

@testset "Utilities Testing" begin

    # test the custom get function (wrapper around HTTP.request)

    # no query params
    url = "https://www.google.com";
    response = DataRetrieval._custom_get(url);
    @test response.status == 200
    @test isa(response, HTTP.Messages.Response)
    @test response.request.headers[1][1] == "user-agent"

    # with query params
    url = constructWQPURL("ActivityMetric");
    query_params = Dict("statecode"=>"US:38",
                        "startDateLo"=>"07-01-2006",
                        "startDateHi"=>"07-01-2007");
    response_qp = DataRetrieval._custom_get(url, query_params=query_params);
    @test response_qp.status == 200
    @test isa(response_qp, HTTP.Messages.Response)
    @test response_qp.request.headers[1][1] == "user-agent"

end