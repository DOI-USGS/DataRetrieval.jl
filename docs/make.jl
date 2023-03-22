using Documenter, DataRetrieval

DocMeta.setdocmeta!(DataRetrieval, :DocTestSetup, :(using DataRetrieval); recursive=true)

# Copy some files from the top level directory to the docs and modify them
# as necessary
# Code modified from: https://github.com/ranocha/SummationByPartsOperators.jl
# which is provided with an MIT license
open(joinpath(@__DIR__, "src", "contributing.md"), "w") do io
    # Point to source contributing file
    println(io, """
    ```@meta
    EditURL = "https://code.usgs.gov/water/computational-tools/DataRetrieval.jl/-/blob/main/CONTRIBUTING.md"
    ```
    """)
    # Write the modified contents
    println(io, "# Contributing")
    println(io, "")
    for line in eachline(joinpath(dirname(@__DIR__), "CONTRIBUTING.md"))
        line = replace(line, "[CONTRIBUTING.md](Contributing.md)" => "[Contributing](@ref)")
        println(io, "> ", line)
    end
end

open(joinpath(@__DIR__, "src", "license.md"), "w") do io
    # Point to source license file
    println(io, """
    ```@meta
    EditURL = "https://code.usgs.gov/water/computational-tools/DataRetrieval.jl/-/blob/main/LICENSE.md"
    ```
    """)
    # Write the modified contents
    println(io, "# License")
    println(io, "")
    for line in eachline(joinpath(dirname(@__DIR__), "LICENSE.md"))
        line = replace(line, "[LICENSE.md](LICENSE.md)" => "[License](@ref)")
        println(io, "> ", line)
    end
end

open(joinpath(@__DIR__, "src", "disclaimer.md"), "w") do io
    # Point to source disclaimer file
    println(io, """
    ```@meta
    EditURL = "https://code.usgs.gov/water/computational-tools/DataRetrieval.jl/-/blob/main/DISCLAIMER.md"
    ```
    """)
    # Write the modified contents
    println(io, "# Disclaimer")
    println(io, "")
    for line in eachline(joinpath(dirname(@__DIR__), "LICENSE.md"))
        line = replace(line, "[DISCLAIMER.md](Disclaimer.md)" => "[Disclaimer](@ref)")
        println(io, "> ", line)
    end
end

makedocs(
    modules = [DataRetrieval],
    sitename = "DataRetrieval.jl Documentation",
    authors = "J. Hariharan",
    pages = [
        "index.md", "examples.md", "contributing.md", "license.md",
        "disclaimer.md", "apiref.md"
    ],
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
        edit_link = nothing
    )
)