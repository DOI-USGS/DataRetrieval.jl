module DataRetrieval

import HTTP
import JSON
import DataFrames
import CSV
import EzXML
using Dates

# Include utility functions first so submodules can access them
include("utilities.jl")
export set_token!, clear_token!

# Include submodules
include("WaterData.jl")
include("NWIS.jl")
include("WQP.jl")
include("NLDI.jl")

export WaterData, NWIS, WQP, NLDI

end
