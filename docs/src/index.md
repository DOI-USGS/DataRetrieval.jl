# DataRetrieval.jl Documentation

## Introduction
DataRetrieval.jl is a Julia package for retrieving data USGS water data and is
based off of the popular R package of the same name. Both R and Python
versions of data retrieval are available:
[R](https://github.com/DOI-USGS/dataRetrieval),
[Python](https://github.com/DOI-USGS/dataretrieval-python). Development of the
package currently takes place on GitHub, in the
[DataRetrieval.jl repository](https://github.com/DOI-USGS/DataRetrieval.jl).

The Julia package includes support for Nwis, Wqp, and Waterdata samples-data
queries.

USGS data access is transitioning from legacy NWIS web services to modern
Water Data APIs. In general, prefer `WaterData.*` functions for new
workflows when equivalent Julia functionality is available.

For broader upstream migration and status context from the R package, see:

- <https://doi-usgs.github.io/dataRetrieval/articles/read_waterdata_functions.html>
- <https://doi-usgs.github.io/dataRetrieval/articles/Status.html>

## Service Modules

DataRetrieval.jl provides data from four primary USGS services, each represented by a module:

* **[WaterData](@ref)**: The modernized USGS Water Data API and Samples API. Provides generic OGC API retrieval, daily values, continuous values, monitoring locations, field measurements, series metadata, and chemical sample results. This is the recommended module for new workflows.
* **[WQP](@ref)**: The Water Quality Portal. Provides water quality data including results, sites, organizations, projects, activities, and detection limits.
* **[NLDI](@ref)**: The Network Linked Data Index API. Provides functions to navigate flowlines, find upstream/downstream basin boundaries, and discover linked features.
* **[NWIS](@ref)**: The legacy National Water Information System. Provides historical daily values, instantaneous values, and site metadata. **Note:** Legacy NWIS services are being decommissioned by the USGS. Users are encouraged to migrate to `WaterData` functions.

### What would you like to do?

Use this quick guide to select the right DataRetrieval.jl function family:

1. Instantaneous USGS data: `WaterData.continuous` / `WaterData.latest_continuous` (see [Examples](examples.md#Plotting-Flow-Data-for-Site-01646500))
2. Daily USGS data: `WaterData.daily` / `WaterData.latest_daily` (see [Examples](examples.md#Examining-Site-01491000))
3. Discrete USGS groundwater field measurements: `WaterData.field_measurements`
4. Water Quality Portal data: `WQP.data` / `WQP.results` (see [Examples](examples.md#Water-Quality-Portal-(WQP)-/-Samples-API-Examples))
5. USGS discrete samples-data: `WaterData.samples` (see [Examples](examples.md#Retrieving-Water-Quality-Results))
6. USGS time-series metadata: `WaterData.series_metadata`
7. NLDI discovery and hydrography: `NLDI.search`, `NLDI.features`, `NLDI.flowlines`, `NLDI.basin`
8. Daily statistics: `WaterData.stats_por`, `WaterData.stats_date_range`

USGS Waterdata APIs may apply stricter rate limits to unauthenticated requests.
For higher rate limits, register for an API key at
[https://api.waterdata.usgs.gov/signup/](https://api.waterdata.usgs.gov/signup/)
and set `ENV["API_USGS_PAT"]` before making requests. You can also set a
session-only override with `set_token!("...")`.

NWIS legacy endpoints are being decommissioned. For water-quality samples,
prefer `WaterData.samples` over NWIS `qw/qwdata` workflows.

## Installation

### User Installation

Currently only installation from the git repository is supported.
To install the package, you can use the Pkg REPL (hitting `]` from the Julia REPL):

```julia
pkg> add https://github.com/DOI-USGS/DataRetrieval.jl.git
```

This is equivalent to the following code using the Julia REPL:

```julia
> using Pkg
> Pkg.add("https://github.com/DOI-USGS/DataRetrieval.jl.git")
```

### Developer Installation

When developing in Julia, we recommend using an [environment](https://pkgdocs.julialang.org/v1/environments/#Using-someone-else's-project) as well as the [Revise](https://timholy.github.io/Revise.jl/stable/) package so that you do not need to keep track of individual dependencies or re-compile the package every time you make a change.
Development takes place using `git` for version control.
A fork and clone workflow is recommended, where a developer first creates a "fork" of the repository, and then "clones" that fork to work locally on an individual feature branch.

Once you have a local clone of the repository, from within that repository and in the Pkg REPL, the following commands should create a working environment (taken from the [Pkg.jl documentation](https://pkgdocs.julialang.org/v1/environments/#Using-someone-else's-project)):

```julia
pkg> activate .
(DataRetrieval) pkg> instantiate
```

To use `Revise` to help streamline development and avoid having to re-compile the package every time you make a modification, you should begin your Julia sessions with the following:

```julia
using Revise
using DataRetrieval
```

## Branches

Note that for the `DataRetrieval.jl` project there are two branches to be aware of.
The "main" branch is designed to be the stable and most-used branch, it has documentation [here](https://rconnect.usgs.gov/DataRetrieval-jl/).
The "dev" branch is designed for development and prototyping of new or upcoming features.
As such, installation from the "dev" branch is not recommended for novice users, but can be useful for developers to work on, propose, or test new functionality or documentation.
There is documentation for the "dev" branch available [here](https://rconnect.usgs.gov/DataRetrieval-jl-dev/).