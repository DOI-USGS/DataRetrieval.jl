module DataRetrieval

using HTTP
using JSON
using DataFrames
using CSV
using EzXML
using Dates

# Include utility functions first so submodules can access them
include("utilities.jl")
export set_token!, clear_token!

# Include submodules
include("waterdata.jl")
include("nwis.jl")
include("wqp.jl")
include("nldi.jl")

export WaterData, NWIS, WQP, NLDI

end
