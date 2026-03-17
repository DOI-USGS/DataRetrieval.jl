# Examples

Modern development should use `WaterData.*` functions, which query the newer USGS Waterdata OGC and Samples APIs. These services are more performant and return cleaner, modern data formats.

## Index

```@contents
Pages = ["examples.md"]
```

## Waterdata API Examples
These examples use data retrieved from the [USGS Waterdata OGC API](https://api.waterdata.usgs.gov/ogcapi/v0) and the [Samples API](https://api.waterdata.usgs.gov/samples-data).

### Examining Site 01491000

In this example we fetch information for site "01491000" located on the Choptank River near Greensboro, MD. Site identifiers in the modern API typically include the agency prefix (e.g., `USGS-`).

First we will obtain metadata about the monitoring location.

```@example 01491000
using DataRetrieval
siteID = "USGS-01491000"
df, response = WaterData.monitoring_locations(monitoring_location_id=siteID);

# print the site information table
df
```

We can also look at the raw API response status.

```@example 01491000
# print the response status code
response.status
```

Now we can get daily discharge values. We will obtain data for the first three days of January 1980.

```@example 01491000
# parameter_code 00060 is discharge
df, response = WaterData.daily(monitoring_location_id=siteID, 
                              parameter_code="00060",
                              time="1980-01-01/1980-01-03");

# print the data frame
df
```

### Plotting Flow Data for Site 01646500

In this example we fetch and plot instantaneous (continuous) flow data for site "01646500" (Potomac River near Washington D.C.) for December 1, 2022.

```@example 01646500
using DataRetrieval, DataFrames
siteID = "USGS-01646500"
df, response = WaterData.continuous(monitoring_location_id=siteID, 
                                    parameter_code="00060", 
                                    time="2022-12-01/2022-12-05");
# Clean up missing values and sort the data
df = dropmissing(df, [:time, :value])
sort!(df, :time)

# display the first row
first(df)
```

We can fetch additional information about the parameter code (units, description) using the reference table service.

```@example 01646500
pcodedf, response = WaterData.reference_table("parameter-codes", query=Dict("id" => "00060"));
pcodedf
```

Now we plot the discharge data. Note that column names in the modern API are standardized (e.g., `time` and `value`).

```@example 01646500
using Plots
plot(df.time, df.value,
     title="Discharge at Potomac River near Washington D.C.",
     ylabel="Discharge (ft³/s)",
     xlabel="Time",
     xrotation=60,
     label="Discharge",
     dpi=200)
```

### Fetching and Plotting Groundwater Levels from Site 393617075380403

In this example we fetch and plot daily groundwater levels (parameter code "72019") for the first six months of 2012.

```@example 393617075380403
using DataRetrieval, DataFrames
siteID = "USGS-393617075380403"
df, response = WaterData.daily(monitoring_location_id=siteID, 
                              parameter_code="72019",
                              time="2012-01-01/2012-06-30");

# Clean up missing values and sort the data
dropmissing!(df, :value)
sort!(df, :time)

# display the first row
first(df)
```

Get parameter metadata:

```@example 393617075380403
pcodedf, response = WaterData.reference_table("parameter-codes", query=Dict("id" => "72019"));
pcodedf
```

Plot the groundwater levels:

```@example 393617075380403
using Plots
# Use the value column directly
plot(df.time, df.value,
     title="Groundwater Levels at Site 393617075380403",
     ylabel="Depth (ft below land surface)",
     xlabel="Time",
     xrotation=60,
     label="Groundwater Level",
     yflip=true,
     dpi=200,
     margin=5Plots.mm)
```

## NLDI Examples

The Network Linked Data Index (NLDI) API provides functions to navigate flowlines, find basin boundaries, and discover linked features.

### Finding a Basin

In this example, we find the basin for a specific NWIS site.

```@example nldi_basin
using DataRetrieval, GeoDataFrames
df_basin, response = NLDI.basin("nwissite", "USGS-01491000");

# display the basin data frame
first(df_basin)
```

### Navigating Flowlines

We can also navigate upstream or downstream from a feature to find flowlines.

```@example nldi_basin
# Navigate upstream main (UM) up to 10 km
df_flow, response = NLDI.flowlines("UM", feature_source="nwissite", feature_id="USGS-01491000", distance=10);

# display the flowlines
first(df_flow)
```

We can then plot the basin and flowlines geometries directly.

```@example nldi_basin
using Plots
p = plot(df_basin.geometry, fillalpha=0.2, c=:blue, label="Basin")
plot!(p, df_flow.geometry, c=:red, linewidth=2, label="Flowlines UM")
title!("Site 01491000 Basin & Flowlines")
```

### Retrieving Linked Features

You can also use NLDI to find all linked features for a given source, or search along navigation lines. We will grab the first few `nwissite` features and view their rich metadata.

```@example nldi_features
using DataRetrieval, GeoDataFrames

# Retrieve all water quality portal locations
df_features, response = NLDI.features_by_data_source("nwissite");

# display the properties available
first(df_features, 3)
```

## Water Quality Portal (WQP) / Samples API Examples

Modern water quality queries should prefer the `WaterData.results` or `WaterData.samples` functions.

### Identifying Sites with Chloride Measurements

In this example we identify sites with chloride measurements in New Jersey (state code "US:34").

```@example NJchloride
using DataRetrieval, DataFrames
# Find locations with Chloride measurements
njcl, response = WaterData.locations(state_fips="US:34",
                                    characteristic="Chloride");
# print the number of sites found
nrow(njcl)
```

### Retrieving Water Quality Results

We can also retrieve the actual measurements for a specific location.

```@example NJchloride
# Get narrow profile results for a specific monitoring location
results, response = WaterData.results(
    monitoring_location_identifier="USGS-01408029",
    characteristic="Chloride",
    activity_start_date_lower="2020-01-01"
);

# display the first result
first(results, 1)
```

## Summary of Modern vs Legacy Functions

| Feature | Modern Function | Legacy Function (Deprecated) |
|:--- |:--- |:--- |
| Site Metadata | `WaterData.monitoring_locations` | `NWIS.site` |
| Daily Values | `WaterData.daily` | `NWIS.dv` |
| Continuous Values | `WaterData.continuous` | `NWIS.iv` / `NWIS.unit` |
| Parameter Codes | `WaterData.reference_table` | `NWIS.pcode` |
| QW Results | `WaterData.samples` / `WaterData.results` | `NWIS.qwdata` |
| WQP Sites | `WaterData.locations` | `WQP.sites` |