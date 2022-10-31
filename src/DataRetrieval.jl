module DataRetrieval

using HTTP
using JSON

# Include utility functions:
#   URL construction
include("utils.jl")
export constructNWISURL

end
