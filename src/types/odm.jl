## Description #############################################################################
#
# Definition of types and constructors for Orbit Data Messages (ODM).
#
## References ##############################################################################
#
# [1] CCSDS 502.0-B-3 (2023). Orbit Data Messages. CCSDS Secretariat, Issue 3. Washington,
#     DC, USA.
#
############################################################################################

export OrbitDataMessage

"""
    abstract type OrbitDataMessage

Supertype of all Orbit Data Messages (ODM) defined by the CCSDS 502.0-B-3 standard.

Every concrete message type supported by this package (for example,
[`OrbitMeanElementsMessage`](@ref)) is a subtype of `OrbitDataMessage`. Functions that
handle generic messages, such as [`parse_odm`](@ref) and [`write_odm`](@ref), operate on
this abstract type.
"""
abstract type OrbitDataMessage end
