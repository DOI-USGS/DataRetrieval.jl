using DataRetrieval
using Test
using HTTP
using DataFrames

@testset "All Tests" begin
    include("NWISURLtests.jl")
    include("NWISRDBtests.jl")
    include("NWISquerytests.jl")
end
