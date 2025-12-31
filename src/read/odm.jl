
## Description #############################################################################
#
# Read Orbit Data Messages (ODM) from files.
#
############################################################################################

export read_odm

"""
    read_odm(file::AbstractString) -> OrbitDataMessage

Read an Orbit Data Message (ODM) from the provided `file`.
"""
function read_odm(file::AbstractString)
    # Open the file and parse the ODM.
    open(file, "r") do io
        str = read(io, String)
        return parse_odm(str)
    end
end
