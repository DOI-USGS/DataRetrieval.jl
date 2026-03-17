# DataRetrieval.jl

[![USGS-category-image](https://img.shields.io/badge/USGS-Core-green.svg)](https://owi.usgs.gov/R/packages.html#core)

DataRetrieval.jl is a Julia alternative to the
R [dataRetrieval](https://code.usgs.gov/water/dataRetrieval)
package for obtaining USGS water data directly from web services.
There is also a [Python dataretrieval](https://github.com/DOI-USGS/dataretrieval-python)
package with the same functionality.

Current Julia support includes NWIS, WQP, and WaterData samples-data API
functions.


**Note:** DataRetrieval.jl is currently maintained by an AI agent tasked with
keeping parity with the R
[dataRetrieval](https://github.com/DOI-USGS/dataRetrieval) package.
As a result, not all functionality has been human-tested.
If something appears incorrect, incomplete, or not
ported as expected, please open an issue.


## Introduction

USGS data access is actively transitioning from legacy NWIS web services to
USGS Water Data APIs. In general, prefer `WaterData.*` functions for new
workflows when equivalent functionality exists.


## Installation

The package currently must be installed from source. More stable, periodic,
releases will be made to the 'main' branch while active development will occur
on the 'dev' branch. To install the package, from the 'main' branch, run the
following commands in the Julia REPL:

```julia
julia> ]
pkg> add https://code.usgs.gov/water/computational-tools/DataRetrieval.jl.git
```

## Usage

The package is designed to be used in a similar manner to the R package.
The examples below focus on the newer `WaterData.*` functions.

### Waterdata API Token (Recommended)

USGS Waterdata APIs may rate limit unauthenticated requests. For higher rate
limits, register for an API key at
[https://api.waterdata.usgs.gov/signup/](https://api.waterdata.usgs.gov/signup/)
and set it as an environment variable before using DataRetrieval.jl:

```julia
julia> ENV["API_USGS_PAT"] = "your_api_key_here"
```

You can also set a token for only the current Julia session:

```julia
julia> using DataRetrieval
julia> set_token!("your_api_key_here")
```

To clear the session-specific token override:

```julia
julia> clear_token!()
```

### New Waterdata API Examples

```julia
julia> using DataRetrieval

# 1) Instantaneous data (continuous)
julia> iv, iv_response = WaterData.continuous(
           monitoring_location_id="USGS-06904500",
           parameter_code="00065",
           time="2025-01-01/2025-01-03",
           limit=200,
       )

# 2) Daily data
julia> dv, dv_response = WaterData.daily(
           monitoring_location_id="USGS-05427718",
           parameter_code="00060",
           time="2025-01-01/2025-01-07",
           limit=200,
       )

# 3) Latest values (continuous and daily)
julia> latest_iv, _ = WaterData.latest_continuous(
           monitoring_location_id=["USGS-05427718", "USGS-05427719"],
           parameter_code=["00060", "00065"],
           limit=200,
       )

julia> latest_dv, _ = WaterData.latest_daily(
           monitoring_location_id=["USGS-05427718", "USGS-05427719"],
           parameter_code=["00060", "00065"],
           limit=200,
       )

# 4) USGS samples-data API
julia> samples, samples_response = WaterData.samples(
           service="results",
           profile="narrow",
           monitoring_location_identifier="USGS-05288705",
           activity_start_date_lower="2024-10-01",
           activity_start_date_upper="2025-04-24",
       )

# 5) Daily statistics
julia> stats_por, _ = WaterData.stats_por(
           monitoring_location_id="USGS-12451000",
           parameter_code="00060",
           start_date="01-01",
           end_date="01-01",
       )
```

Each function returns a `DataFrame` and a `HTTP.Messages.Response` object.
You can inspect the HTTP status of any call:

```julia
julia> iv_response.status
200
```

### Legacy NWIS Example

Legacy NWIS functions are still available where services remain active.

```julia
julia> using DataRetrieval
julia> df, response = NWIS.site("05114000")
```

The `NWIS.site` function returns a `DataFrame` containing the site
information and a `HTTP.Messages.Response` object containing the raw API GET
query response. The `DataFrame` can be printed to the console:

```julia
julia> df
1×12 DataFrame
 Row │ agency_cd  site_no   station_nm                    site_tp_cd  dec_lat_ ⋯
     │ String7    String15  String31                      String3     String15 ⋯
─────┼──────────────────────────────────────────────────────────────────────────
   1 │ USGS       05114000  SOURIS RIVER NR SHERWOOD, ND  ST          48.99001 ⋯
                                                               8 columns omitted
```

The `HTTP.Messages.Response` object can be used to examine the raw API GET
query response. For example, we can look at the status of the GET request; a
200 code, for example, indicates a successful response:

```julia
julia> response.status
200
```

## Documentation

The documentation for the package is currently available on RStudio Connect,
and can be found [here](https://rconnect.usgs.gov/DataRetrieval-jl/).

Documentation for the "dev" branch is also available, and can be found [here](https://rconnect.usgs.gov/DataRetrieval-jl-dev/).


## Citing `DataRetrieval.jl`

When citing `DataRetrieval.jl` please use:

Hariharan, J.A., 2023, DataRetrieval.jl-Julia package for obtaining USGS water data directly from web services: U.S. Geological Survey software
release, Julia package, Reston, Va., <https://doi.org/10.5066/P95XLHUH>.
