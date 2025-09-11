module SatelliteToolboxOrbitDataMessages

using Dates
using HTTP
using Scratch
using Serialization
using StyledStrings
using URIs
using XML

import Base: show
import NanoDates: NanoDate

############################################################################################
#                                          Types                                           #
############################################################################################

include("./types.jl")

############################################################################################
#                                         Includes                                         #
############################################################################################

include("./printing.jl")
include("./show.jl")

include("./fetcher/api.jl")
include("./fetcher/celestrak.jl")
include("./fetcher/spacetrack.jl")

include("./parse/odm.jl")
include("./parse/omm.jl")

end # module SatelliteToolboxOrbitDataMessages
