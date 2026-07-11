## Description #############################################################################
#
# Tests of the accessor functions in the `OMM` module.
#
############################################################################################

@testset "Accessor Functions" begin
    omm = parse_omm(_fixture_omm_xml())

    # Every generated accessor must return the corresponding field of the message.
    for (fname, field, _, _) in OMM._OMM_HEADER_ACCESSORS
        accessor = getfield(OMM, fname)
        @test accessor(omm) === getfield(omm.header, field)
    end

    for (fname, field, _, _) in OMM._OMM_METADATA_ACCESSORS
        accessor = getfield(OMM, fname)
        @test accessor(omm) === getfield(omm.body.segment.metadata, field)
    end

    for (fname, field, _, _) in OMM._OMM_DATA_ACCESSORS
        accessor = getfield(OMM, fname)
        @test accessor(omm) === getfield(omm.body.segment.data, field)
    end

    # Spot-check some accessors against the fixture values.
    @test OMM.object_name(omm)  == "AMAZONIA 1"
    @test OMM.object_id(omm)    == "2021-015A"
    @test OMM.originator(omm)   == "18 SPCS"
    @test OMM.epoch(omm)        == NanoDate("2025-12-30T18:12:04.533984")
    @test OMM.mean_motion(omm)  ≈  14.40772474
    @test OMM.eccentricity(omm) ≈  0.0001124
    @test OMM.norad_cat_id(omm) == 47699

    # The accessors must be available in the `OMM` module without polluting the package
    # namespace.
    omm_names     = names(OMM)
    package_names = names(SatelliteToolboxOrbitDataMessages)

    @test :OMM in package_names

    for table in (
        OMM._OMM_HEADER_ACCESSORS,
        OMM._OMM_METADATA_ACCESSORS,
        OMM._OMM_DATA_ACCESSORS,
    )
        for (fname, _, _, _) in table
            @test fname in omm_names
            @test fname ∉ package_names
        end
    end
end
