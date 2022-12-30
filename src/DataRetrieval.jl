module DataRetrieval

using HTTP
using JSON
using DataFrames
using CSV
using EzXML

# Include URL construction functions:
include("ConstructURLs.jl")
export constructNWISURL

# Include functions to read NWIS data
include("ReadNWIS.jl")
export readNWIS
export readNWISdv
export readNWISpCode
export readNWISqw
export readNWISqwdata
export readNWISsite
export readNWISunit
export readNWISuv
export readNWISiv

end
