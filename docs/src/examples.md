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
using DataRetrieval
siteID = "USGS-01646500"
df, response = WaterData.continuous(monitoring_location_id=siteID, 
                                    parameter_code="00060", 
                                    time="2022-12-01/2022-12-01");
# display the first row
first(df)
```

We can fetch additional information about the parameter code (units, description) using the reference table service.

```@example 01646500
pcodedf, response = WaterData.reference_table("parameter-codes", query=Dict("id" => "00060"));
pcodedf
```

Now we plot the discharge data. Note that column names in the modern API are standardized (e.g., `time` and `value`).

```julia
using Plots
plot(df.time, df.value,
     title="Discharge at Little Falls Pump Station, Dec. 1, 2022",
     ylabel="Discharge (ft³/s)",
     xlabel="Time",
     xrotation=60,
     label="Discharge",
     dpi=200)
```

### Fetching and Plotting Groundwater Levels from Site 393617075380403

In this example we fetch and plot daily groundwater levels (parameter code "72019") for the first six months of 2012.

```@example 393617075380403
using DataRetrieval
siteID = "USGS-393617075380403"
df, response = WaterData.daily(monitoring_location_id=siteID, 
                              parameter_code="72019",
                              time="2012-01-01/2012-06-30");
# display the first row
first(df)
```

Get parameter metadata:

```@example 393617075380403
pcodedf, response = WaterData.reference_table("parameter-codes", query=Dict("id" => "72019"));
pcodedf
```

Plot the groundwater levels:

```julia
using Plots
# Use the value column directly
plot(df.time, df.value,
     title="Groundwater Levels at Site 393617075380403",
     ylabel="Depth (ft below land surface)",
     xlabel="Time",
     xrotation=60,
     label="Groundwater Level",
     dpi=200,
     margin=5Plots.mm)
```

## Water Quality Portal (WQP) / Samples API Examples

Modern water quality queries should prefer the `WaterData.results` or `WaterData.samples` functions.

### Identifying Sites with Chloride Measurements

In this example we identify sites with chloride measurements in New Jersey (state code "US:34").

```@example NJchloride
using DataRetrieval
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

# display the first few results
first(results, 5)
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