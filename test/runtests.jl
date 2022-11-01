using DataRetrieval
using Test

@testset "All Tests" begin
    include("NWISURLtests.jl")
    include("NWISRDBtests.jl")
end
