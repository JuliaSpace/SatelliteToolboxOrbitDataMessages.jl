using Documenter
using SatelliteToolboxOrbitDataMessages

# Load the weak dependency so that the package extension (and its `convert` method to `TLE`)
# is available while building the documentation.
using SatelliteToolboxTle

DocMeta.setdocmeta!(
    SatelliteToolboxOrbitDataMessages,
    :DocTestSetup,
    :(using SatelliteToolboxOrbitDataMessages);
    recursive = true,
)

makedocs(
    modules = [SatelliteToolboxOrbitDataMessages],
    format = Documenter.HTML(
        prettyurls = !("local" in ARGS),
        canonical = "https://juliaspace.github.io/SatelliteToolboxOrbitDataMessages.jl/stable/",
        size_threshold = 500 * 1024,
        size_threshold_warn = 250 * 1024,
    ),
    sitename = "SatelliteToolboxOrbitDataMessages.jl",
    authors = "Ronan Arraes Jardim Chagas",
    pages = [
        "Home" => "index.md",
        "Quick Start" => "man/quick_start.md",
        "Manual" => [
            "Creating OMMs"           => "man/creating_omms.md",
            "Parsing Messages"        => "man/parsing.md",
            "Reading & Writing Files" => "man/reading_writing.md",
            "Fetching from Services"  => "man/fetching.md",
            "Converting to TLE"       => "man/tle_conversion.md",
        ],
        "Library" => "lib/library.md",
    ],
)

deploydocs(
    repo = "github.com/JuliaSpace/SatelliteToolboxOrbitDataMessages.jl.git",
    target = "build",
)
