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
[National Water Information System (NWIS)](https://waterdata.usgs.gov/nwis).

```@meta
CurrentModule = DataRetrieval.NWIS
```

```@docs
url
dv
pcode
qwdata
site
unit
uv
iv
```

## WQP Functions
Functions that are related to the
[Water Quality Portal](https://waterqualitydata.us/).

```@meta
CurrentModule = DataRetrieval.WQP
```

```@docs
url
data
results
sites
organizations
projects
activities
detection_limits
habitat_metrics
project_weights
activity_metrics
```

## WaterData Functions
Functions that are related to the
[USGS Water Data APIs](https://api.waterdata.usgs.gov/samples-data/docs#/).

```@meta
CurrentModule = DataRetrieval.WaterData
```

```@docs
samples
data
codes
ogc_requests
ogc_params
results
locations
activities
projects
organizations
daily
continuous
monitoring_locations
series_metadata
latest_continuous
latest_daily
field_measurements
channel_measurements
field_metadata
combined_metadata
reference_table
stats_por
stats_date_range
```

## NLDI Functions
Functions that are related to the
[USGS NLDI API](https://api.water.usgs.gov/nldi/swagger-ui/index.html).

```@meta
CurrentModule = DataRetrieval.NLDI
```

```@docs
flowlines
basin
features
search
```

```@meta
CurrentModule = DataRetrieval
```

```@docs
set_token!
clear_token!
```
