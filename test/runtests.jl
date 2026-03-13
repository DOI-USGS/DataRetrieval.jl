using DataRetrieval
using Test
using HTTP
using DataFrames
using Dates
using JSON
using CSV

@testset "All Tests" begin
    include("NWISURLtests.jl")
    include("NWISRDBtests.jl")
    include("NWISquerytests.jl")
    include("WQPtests.jl")
    include("WaterDatatests.jl")
    include("NLDItests.jl")
    include("Utilitiestests.jl")
end
