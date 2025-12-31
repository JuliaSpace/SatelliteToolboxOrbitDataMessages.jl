## Description #############################################################################
#
# Read Orbit Mean-Elements Messages (OMM) from files.
#
############################################################################################

export read_omm

"""
    read_omm(file::AbstractString) -> OrbitMeanElementsMessage

Read an Orbit Mean-Elements Message (OMM) from the provided `file`.
"""
function read_omm(file::AbstractString)
    # Open the file and parse the OMM.
    open(file, "r") do io
        str = read(io, String)
        return parse_omm(str)
    end
end
