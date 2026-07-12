## Description #############################################################################
#
# Tests of the accessor functions in the `ODM` module.
#
############################################################################################

@testset "Accessor Functions" begin
    omm = parse_omm(_fixture_omm_xml())

    # Every generated accessor must return the corresponding field of the message.
    for (fname, field, _, _) in ODM._OMM_HEADER_ACCESSORS
        accessor = getfield(ODM, fname)
        @test accessor(omm) === getfield(omm.header, field)
    end

    for (fname, field, _, _) in ODM._OMM_METADATA_ACCESSORS
        accessor = getfield(ODM, fname)
        @test accessor(omm) === getfield(omm.body.segment.metadata, field)
    end

    for (fname, field, _, _) in ODM._OMM_DATA_ACCESSORS
        accessor = getfield(ODM, fname)
        @test accessor(omm) === getfield(omm.body.segment.data, field)
    end

    # Spot-check some accessors against the fixture values.
    @test ODM.object_name(omm)  == "AMAZONIA 1"
    @test ODM.object_id(omm)    == "2021-015A"
    @test ODM.originator(omm)   == "18 SPCS"
    @test ODM.epoch(omm)        == NanoDate("2025-12-30T18:12:04.533984")
    @test ODM.mean_motion(omm)  ≈  14.40772474
    @test ODM.eccentricity(omm) ≈  0.0001124
    @test ODM.norad_cat_id(omm) == 47699

    # The accessors must be available in the `ODM` module without polluting the package
    # namespace.
    odm_names     = names(ODM)
    package_names = names(SatelliteToolboxOrbitDataMessages)

    @test :ODM in package_names

    for table in (
        ODM._OMM_HEADER_ACCESSORS,
        ODM._OMM_METADATA_ACCESSORS,
        ODM._OMM_DATA_ACCESSORS,
    )
        for (fname, _, _, _) in table
            @test fname in odm_names
            @test fname ∉ package_names
        end
    end
end
