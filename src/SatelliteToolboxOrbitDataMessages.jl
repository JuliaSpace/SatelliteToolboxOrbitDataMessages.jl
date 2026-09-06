"""
    module SatelliteToolboxOrbitDataMessages

Create, fetch, parse, and write CCSDS Orbit Data Messages (ODM).

The package currently supports Orbit Mean-Elements Messages (OMM) in the XML and KVN
formats, including Navigation Data Messages (NDM) that wrap multiple messages in XML, and
fetching OMMs from the Celestrak and Space-Track services.
"""
module SatelliteToolboxOrbitDataMessages

using Dates
using HTTP
using PrecompileTools
using Scratch
using Serialization
using URIs
using XML

import Base: ==
import NanoDates: NanoDate
import SatelliteToolboxBase: PrintedField, PrintedSection, print_tree, print_tree_body

############################################################################################
#                                          Types                                           #
############################################################################################

include("./types/odm.jl")
include("./types/omm.jl")

include("./api.jl")

############################################################################################
#                                         Includes                                         #
############################################################################################

include("./misc.jl")
include("./kvn.jl")
include("./show.jl")
include("./xml.jl")

include("./fetcher/api.jl")
include("./fetcher/celestrak.jl")
include("./fetcher/spacetrack.jl")

include("./parse/odm.jl")
include("./parse/omm.jl")
include("./parse/kvn/odm.jl")
include("./parse/kvn/omm.jl")
include("./parse/kvn/omms.jl")
include("./parse/xml/odm.jl")
include("./parse/xml/omm.jl")
include("./parse/xml/omms.jl")

include("./read/odm.jl")
include("./read/omm.jl")

include("./write/odm.jl")
include("./write/omm.jl")
include("./write/kvn/odm.jl")
include("./write/kvn/omm.jl")
include("./write/xml/odm.jl")
include("./write/xml/omm.jl")

include("./precompile.jl")

end # module SatelliteToolboxOrbitDataMessages
