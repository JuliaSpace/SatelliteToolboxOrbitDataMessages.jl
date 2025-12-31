## Description #############################################################################
#
# Test the display function of Orbit Mean-Elements Messages (OMM).
#
############################################################################################

@testset "OMM Display" verbose = true begin
    omm = read_omm(joinpath(@__DIR__, "2025-12-30-Amazonia_1.xml"))

    # == Compact Display ===================================================================

    result   = sprint(show, omm)
    expected = "OMM: AMAZONIA 1 [2021-015A] (Epoch = 2025-12-30T18:12:04.533984)"

    @test result == expected

    # == Detailed Display ==================================================================

    expected = """
OrbitMeanElementsMessage:
  Header
  │                   Comment : GENERATED VIA SPACE-TRACK.ORG API
  │             Creation Date : 2025-12-30T23:36:37
  │                Originator : 18 SPCS
  Body
  └─Segment
    ├─Metadata
    │             Object Name : AMAZONIA 1
    │               Object ID : 2021-015A
    │             Center Name : EARTH
    │              Ref. Frame : TEME
    │             Time System : UTC
    │     Mean Element Theory : SGP4
    └─Data
      ├─Mean Keplerian Elements
      │                 Epoch : 2025-12-30T18:12:04.533984
      │           Mean Motion : 14.40772474 rev/day
      │          Eccentricity : 0.0001124
      │           Inclination : 98.3721°
      │       RA of Asc. Node : 75.0877°
      │    Arg. of Pericenter : 97.3772°
      │          Mean Anomaly : 262.7545°
      │ 
      ├─TLE Related Parameters
      │        Ephemeris Type : 0
      │   Classification Type : U
      │          NORAD Cat ID : 47699
      │    Element Set Number : 999
      │          Rev at Epoch : 25439
      │                 Bstar : 0.0001533
      │    ∂(Mean Motion)/∂t  : 4.47e-6     rev/day²
      │   ∂²(Mean Motion)/∂t² : 0.0         rev/day³
      │ 
      ├─User-Defined Parameters
      │        SEMIMAJOR_AXIS : 7134.084
      │                PERIOD : 99.946
      │              APOAPSIS : 756.751
      │             PERIAPSIS : 755.147
      │           OBJECT_TYPE : PAYLOAD
      │              RCS_SIZE : LARGE
      │          COUNTRY_CODE : BRAZ
      │           LAUNCH_DATE : 2021-02-28
      │                  SITE : SRI
      │            DECAY_DATE :
      │                  FILE : 4946249
      │                 GP_ID : 307230979
      └─"""

    result = sprint(show, MIME("text/plain"), omm)
    @test result == expected
end