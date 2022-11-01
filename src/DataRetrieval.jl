module DataRetrieval

using HTTP
using JSON
using DataFrames
using CSV

# Include URL construction functions:
include("ConstructURLs.jl")
export constructNWISURL

# Include functions to read NWIS data
include("ReadNWIS.jl")
export readNWIS

end
