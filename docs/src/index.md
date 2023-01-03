# DataRetrieval.jl Documentation

## Introduction
DataRetrieval.jl is a Julia package for retrieving data USGS water data and is
based off of the popular R package of the same name. Both R and Python
versions of data retrieval are available:
[R](https://github.com/DOI-USGS/dataRetrieval),
[Python](https://github.com/USGS-python/dataretrieval). Development of the
package currently takes place on GitLab, in the
[DataRetrieval.jl repository](https://code.usgs.gov/wma/iow/computational-tools/DataRetrieval.jl).

## Installation

Currently only the development version of DataRetrieval.jl is available. To
install the development version, you can use the Julia package manager and
point to the git repository:

```julia
] add https://code.usgs.gov/wma/iow/computational-tools/DataRetrieval.jl.git
```

When developing in Julia, we recommend using the
[Revise](https://timholy.github.io/Revise.jl/stable/) package so that you do
not need to keep re-compiling the package every time you make a change.