using Documenter, DataRetrieval

DocMeta.setdocmeta!(DataRetrieval, :DocTestSetup, :(using DataRetrieval); recursive=true)

makedocs(
    modules = [DataRetrieval],
    sitename = "DataRetrieval.jl Documentation",
    authors = "J. Hariharan",
    pages = ["index.md", "examples.md", "apiref.md"],
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true"
    )
)