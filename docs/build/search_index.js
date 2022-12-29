var documenterSearchIndex = {"docs":
[{"location":"apiref.html#API-Reference","page":"API Reference","title":"API Reference","text":"","category":"section"},{"location":"apiref.html","page":"API Reference","title":"API Reference","text":"CurrentModule = DataRetrieval","category":"page"},{"location":"apiref.html","page":"API Reference","title":"API Reference","text":"constructNWISURL","category":"page"},{"location":"apiref.html#DataRetrieval.constructNWISURL","page":"API Reference","title":"DataRetrieval.constructNWISURL","text":"constructNWISURL(siteNumbers; parameterCd=\"00060\",\n    startDate=\"\", endDate=\"\", service=\"site\", statCd=\"00003\",\n    format=\"xml\", expanded=True, ratingType=\"base\", statReportType=\"daily\",\n    statType=\"mean\")\n\nConstruct a URL to be used to make an API query to the NWIS service.\n\n\n\n\n\n","category":"function"},{"location":"apiref.html","page":"API Reference","title":"API Reference","text":"readNWIS","category":"page"},{"location":"apiref.html#DataRetrieval.readNWIS","page":"API Reference","title":"DataRetrieval.readNWIS","text":"readNWIS(obs_url)\n\nFunction to take an NWIS url (typically constructed using the constructNWISURL() function) and return the associated data.\n\n\n\n\n\n","category":"function"},{"location":"apiref.html","page":"API Reference","title":"API Reference","text":"readNWISdv","category":"page"},{"location":"apiref.html#DataRetrieval.readNWISdv","page":"API Reference","title":"DataRetrieval.readNWISdv","text":"readNWISdv(siteNumbers, parameterCd;\n           startDate=\"\", endDate=\"\", statCd=\"00003\")\n\nFunction to obtain daily value data from the NWIS web service.\n\n\n\n\n\n","category":"function"},{"location":"examples.html#Examples","page":"Examples","title":"Examples","text":"","category":"section"},{"location":"examples.html","page":"Examples","title":"Examples","text":"to be added...","category":"page"},{"location":"index.html#DataRetrieval.jl-Documentation","page":"DataRetrieval.jl Documentation","title":"DataRetrieval.jl Documentation","text":"","category":"section"},{"location":"index.html#Introduction","page":"DataRetrieval.jl Documentation","title":"Introduction","text":"","category":"section"},{"location":"index.html","page":"DataRetrieval.jl Documentation","title":"DataRetrieval.jl Documentation","text":"DataRetrieval.jl is a Julia package for retrieving data USGS water data and is based off of the popular R package of the same name. Both R and Python versions of data retrieval are available: R, Python.","category":"page"},{"location":"index.html#Installation","page":"DataRetrieval.jl Documentation","title":"Installation","text":"","category":"section"},{"location":"index.html","page":"DataRetrieval.jl Documentation","title":"DataRetrieval.jl Documentation","text":"Currently only the development version of DataRetrieval.jl is available. To install the development version, you can use the Julia package manager and point to the git repository:","category":"page"},{"location":"index.html","page":"DataRetrieval.jl Documentation","title":"DataRetrieval.jl Documentation","text":"] add https://code.usgs.gov/wma/iow/computational-tools/DataRetrieval.jl.git","category":"page"},{"location":"index.html","page":"DataRetrieval.jl Documentation","title":"DataRetrieval.jl Documentation","text":"When developing in Julia, we recommend using the Revise package so that you do not need to keep re-compiling the package every time you make a change.","category":"page"}]
}
