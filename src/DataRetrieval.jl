module DataRetrieval

using HTTP
using JSON
using DataFrames
using CSV
using EzXML
using Dates

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

# Include functions to read WaterData API data
include("ReadWaterData.jl")
export readWaterDataCodes
export readWaterData
export checkWaterDataOGCRequests
export getWaterDataOGCParams
export readWaterDataSamples
export readWaterDataResults
export whatWaterDataLocations
export whatWaterDataActivities
export whatWaterDataProjects
export whatWaterDataOrganizations
export readWaterDataDaily
export readWaterDataContinuous
export whatWaterDataMonitoringLocations
export readWaterDataTimeSeriesMetadata
export readWaterDataLatestContinuous
export readWaterDataLatestDaily
export readWaterDataFieldMeasurements
export readWaterDataChannelMeasurements
export readWaterDataFieldMetadata
export readWaterDataCombinedMetadata
export readWaterDataReferenceTable
export readWaterDataStatsPOR
export readWaterDataStatsDateRange

# Include functions to read NLDI API data
include("ReadNLDI.jl")
export readNLDIflowlines
export readNLDIbasin
export readNLDIfeatures
export searchNLDI

# Include utility functions
include("Utilities.jl")
export setUSGSAPIToken!
export clearUSGSAPIToken!

end
