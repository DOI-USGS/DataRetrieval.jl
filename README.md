# DataRetrieval.jl

[![USGS-category-image](https://img.shields.io/badge/USGS-Core-green.svg)](https://owi.usgs.gov/R/packages.html#core)

DataRetrieval.jl is a Julia alternative to the R [dataRetrieval](https://code.usgs.gov/water/dataRetrieval) package for obtaining USGS water data directly from web services. There is also a [Python dataretrieval](https://github.com/USGS-python/dataretrieval) package designed to perform the same functionality in the Python language.

**Note:** Due to the both the relative newness of the Julia language and a
lack of knowledge regarding its adoption within the water community, the
development of this package will be subject to demand from the community.
Consequently, please raise an
[issue](https://code.usgs.gov/wma/iow/computational-tools/DataRetrieval.jl/-/issues)
if there is functionality you'd like added to the Julia package.


## Installation

The package currently must be installed from source. More stable, periodic,
releases will be made to the 'main' branch while active development will occur
on the 'dev' branch. To install the package, from the 'main' branch, run the
following commands in the Julia REPL:

```julia
julia> ]
pkg> add https://code.usgs.gov/wma/iow/computational-tools/DataRetrieval.jl.git
```

## Usage

The package is designed to be used in a similar manner to the R package.
For example, to obtain information about a site, you can use the
`readNWISsite` function:

```julia
julia> using DataRetrieval
julia> df, response = readNWISsite("05114000")
```

The `readNWISsite` function returns a `DataFrame` containing the site
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
and can be found [here](https://rconnect.chs.usgs.gov/DataRetrieval-jl/).

Documentation for the "dev" branch is also available, and can be found [here](https://rconnect.chs.usgs.gov/DataRetrieval-jl-dev/).

## Contributing

Contributions to the package are welcome. Please see the
[contributing guidelines](https://code.usgs.gov/wma/iow/computational-tools/DataRetrieval.jl/-/blob/main/CONTRIBUTING.md)
for more information.

## License

The package is licensed per the
[LICENSE.md](https://code.usgs.gov/wma/iow/computational-tools/DataRetrieval.jl/-/blob/main/LICENSE)
file.

## Acknowledgements

The package was developed by @jhariharan.

## Disclaimer

See [DISCLAIMER.md](https://code.usgs.gov/wma/iow/computational-tools/DataRetrieval.jl/-/blob/main/DISCLAIMER.md).

## Contact

For questions or comments about the package, please contact
[J. Hariharan](mailto:jhariharan@usgs.gov)
