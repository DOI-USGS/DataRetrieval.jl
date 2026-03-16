using DataRetrieval
using Test
using HTTP
using DataFrames
using Dates
using JSON
using CSV
# Standard tests setup
isdefined(Main, :_try_live) || include("test_utils.jl")

@testset "All Tests" begin
    include("nwis_url_tests.jl")
    include("nwis_rdb_tests.jl")
    include("nwis_query_tests.jl")
    include("wqp_tests.jl")
    include("waterdata_tests.jl")
    include("nldi_tests.jl")
    include("utilities_tests.jl")
end
