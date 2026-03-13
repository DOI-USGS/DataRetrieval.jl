# DataRetrieval.jl Documentation

## Introduction
DataRetrieval.jl is a Julia package for retrieving data USGS water data and is
based off of the popular R package of the same name. Both R and Python
versions of data retrieval are available:
[R](https://github.com/DOI-USGS/dataRetrieval),
[Python](https://github.com/DOI-USGS/dataretrieval-python). Development of the
package currently takes place on GitLab, in the
[DataRetrieval.jl repository](https://code.usgs.gov/water/computational-tools/DataRetrieval.jl).

The Julia package includes support for NWIS, WQP, and WaterData samples-data
queries.

USGS data access is transitioning from legacy NWIS web services to modern
Water Data APIs. In general, prefer `readWaterData*` functions for new
workflows when equivalent Julia functionality is available.

For broader upstream migration and status context from the R package, see:

- <https://doi-usgs.github.io/dataRetrieval/articles/read_waterdata_functions.html>
- <https://doi-usgs.github.io/dataRetrieval/articles/Status.html>

### What would you like to do?

Use this quick guide to select the right DataRetrieval.jl function family:

1. Instantaneous USGS data: `readWaterDataContinuous` /
	`readWaterDataLatestContinuous`
2. Daily USGS data: `readWaterDataDaily` / `readWaterDataLatestDaily`
3. Discrete USGS groundwater field measurements:
	`readWaterDataFieldMeasurements`
4. Water Quality Portal data: `readWQPdata` / `readWQPresults`
5. USGS discrete samples-data: `readWaterDataSamples`
6. USGS time-series metadata: `readWaterDataTimeSeriesMetadata`
7. NLDI discovery and hydrography: `searchNLDI`, `readNLDIfeatures`,
	`readNLDIflowlines`, `readNLDIbasin`
8. Daily statistics: `readWaterDataStatsPOR`, `readWaterDataStatsDateRange`

USGS WaterData APIs may apply stricter rate limits to unauthenticated requests.
For higher rate limits, register for an API key at
[https://api.waterdata.usgs.gov/signup/](https://api.waterdata.usgs.gov/signup/)
and set `ENV["API_USGS_PAT"]` before making requests. You can also set a
session-only override with `setUSGSAPIToken!("...")`.

NWIS legacy endpoints are being decommissioned. For water-quality samples,
prefer `readWaterDataSamples` over NWIS `qw/qwdata` workflows.

## Installation

### User Installation

Currently only installation from the git repository is supported.
To install the package, you can use the Pkg REPL (hitting `]` from the Julia REPL):

```julia
pkg> add https://code.usgs.gov/water/computational-tools/DataRetrieval.jl.git
```

This is equivalent to the following code using the Julia REPL:

```julia
> using Pkg
> Pkg.add(https://code.usgs.gov/water/computational-tools/DataRetrieval.jl.git)
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