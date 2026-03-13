# API Reference

Documentation for `DataRetrieval.jl`'s public functions.


## Index

```@index
Pages = ["apiref.md"]
```

```@meta
CurrentModule = DataRetrieval
```

## NWIS Functions
Functions that are related to the
[National Water Information System(NWIS)](https://waterdata.usgs.gov/nwis).

```@docs
readNWIS
```

```@docs
readNWISdv
```

```@docs
readNWISpCode
```

```@docs
readNWISqw
```

```@docs
readNWISqwdata
```

```@docs
readNWISsite
```

```@docs
readNWISunit
```

```@docs
readNWISuv
```

```@docs
readNWISiv
```

## WQP Functions
Functions that are related to the
[Water Quality Portal](https://waterqualitydata.us/).

```@docs
readWQPdata
```

```@docs
readWQPresults
```

```@docs
whatWQPsites
```

```@docs
whatWQPorganizations
```

```@docs
whatWQPprojects
```

```@docs
whatWQPactivities
```

```@docs
whatWQPdetectionLimits
```

```@docs
whatWQPhabitatMetrics
```

```@docs
whatWQPprojectWeights
```

```@docs
whatWQPactivityMetrics
```

## WaterData Functions
Functions that are related to the
[USGS WaterData samples-data API](https://api.waterdata.usgs.gov/samples-data/docs#/).

```@docs
readWaterDataSamples
```

```@docs
readWaterData
```

```@docs
readWaterDataCodes
```

```@docs
checkWaterDataOGCRequests
```

```@docs
getWaterDataOGCParams
```

```@docs
readWaterDataResults
```

```@docs
whatWaterDataLocations
```

```@docs
whatWaterDataActivities
```

```@docs
whatWaterDataProjects
```

```@docs
whatWaterDataOrganizations
```

```@docs
readWaterDataDaily
```

```@docs
readWaterDataContinuous
```

```@docs
whatWaterDataMonitoringLocations
```

```@docs
readWaterDataTimeSeriesMetadata
```

```@docs
readWaterDataLatestContinuous
```

```@docs
readWaterDataLatestDaily
```

```@docs
readWaterDataFieldMeasurements
```

```@docs
readWaterDataChannelMeasurements
```

```@docs
readWaterDataFieldMetadata
```

```@docs
readWaterDataCombinedMetadata
```

```@docs
readWaterDataReferenceTable
```

```@docs
readWaterDataStatsPOR
```

```@docs
readWaterDataStatsDateRange
```

## NLDI Functions
Functions that are related to the
[USGS NLDI API](https://api.water.usgs.gov/nldi/swagger-ui/index.html).

```@docs
readNLDIflowlines
```

```@docs
readNLDIbasin
```

```@docs
readNLDIfeatures
```

```@docs
searchNLDI
```

```@docs
constructNWISURL
```

```@docs
constructWQPURL
```

## Utility Functions

```@docs
setUSGSAPIToken!
```

```@docs
clearUSGSAPIToken!
```
