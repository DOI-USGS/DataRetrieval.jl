module DataRetrieval

using HTTP
using JSON
using DataFrames
using CSV
using EzXML

# Include URL construction functions:
include("ConstructURLs.jl")
export constructNWISURL
export constructWQPURL

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

# Include functions to read WQP data
include("ReadWQP.jl")
export readWQPdata
export readWQPresults
export whatWQPsites
export whatWQPorganizations
export whatWQPprojects
export whatWQPactivities
export whatWQPdetectionLimits
export whatWQPhabitatMetrics
export whatWQPprojectWeights
export whatWQPactivityMetrics

# Include utility functions
include("Utilities.jl")

end
