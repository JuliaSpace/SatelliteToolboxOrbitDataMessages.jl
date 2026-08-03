## Description #############################################################################
#
# Parse Orbit Mean-Elements Messages (OMM) using KVN format.
#
############################################################################################

############################################################################################
#                                    Private Functions                                     #
############################################################################################

function _omm_kvn__parse(kvn::AbstractString)
    # == Initialize Variables ==============================================================

    # -- Header ----------------------------------------------------------------------------

    classification = nothing
    creation_date  = nothing
    originator     = nothing
    message_id     = nothing

    # -- Metadata --------------------------------------------------------------------------

    object_name         = nothing
    object_id           = nothing
    center_name         = nothing
    ref_frame           = nothing
    ref_frame_epoch     = nothing
    time_system         = nothing
    mean_element_theory = nothing

    # -- Data ------------------------------------------------------------------------------

    # .. Mean Keplerian Elements ...........................................................

    epoch             = nothing
    semi_major_axis   = nothing
    mean_motion       = nothing
    eccentricity      = nothing
    inclination       = nothing
    raan              = nothing
    arg_of_pericenter = nothing
    mean_anomaly      = nothing
    GM                = nothing

    # .. Spacecraft Data ...................................................................

    mass            = nothing
    solar_rad_area  = nothing
    solar_rad_coeff = nothing
    drag_area       = nothing
    drag_coeff      = nothing

    # .. TLE Related Parameters ............................................................

    ephemeris_type      = nothing
    classification_type = nothing
    norad_cat_id        = nothing
    element_set_number  = nothing
    rev_at_epoch        = nothing
    bstar               = nothing
    bterm               = nothing
    mean_motion_dot     = nothing
    mean_motion_ddot    = nothing
    agom                = nothing

    # .. Covariance Matrix .................................................................

    covariance_matrix = nothing

    # .. User.Defined Parameters ...........................................................

    user_defined_parameters = nothing

    # == Parse File ========================================================================

    for (l, line) in enumerate(eachsplit(kvn, "\n"))
        keyword, value = _kvn__parse_keyword(line)

        keyword == :invalid && error("Invalid KVN line at line $l: $line")
        keyword == :comment && continue

        if keyword == :epoch
            epoch = _kvn__parse_value(Val(:datetime), value)
        elseif keyword == :semi_major_axis
            semi_major_axis = _kvn__parse_value(Val(:float), value)
        elseif keyword == :mean_motion
            mean_motion = _kvn__parse_value(Val(:float), value)
        elseif keyword == :eccentricity
            eccentricity = _kvn__parse_value(Val(:float), value)
        elseif keyword == :inclination
            inclination = _kvn__parse_value(Val(:float), value)
        elseif keyword == :ra_of_asc_node
            raan = _kvn__parse_value(Val(:float), value)
        elseif keyword == :arg_of_pericenter
            arg_of_pericenter = _kvn__parse_value(Val(:float), value)
        elseif keyword == :mean_anomaly
            mean_anomaly = _kvn__parse_value(Val(:float), value)
        elseif keyword == :GM
            GM = _kvn__parse_value(Val(:float), value)
        elseif keyword == :mass
            mass = _kvn__parse_value(Val(:float), value)
        elseif keyword == :solar_rad_area
            solar_rad_area = _kvn__parse_value(Val(:float), value)
        elseif keyword == :solar_rad_coeff
            solar_rad_coeff = _kvn__parse_value(Val(:float), value)
        elseif keyword == :drag_area
            drag_area = _kvn__parse_value(Val(:float), value)
        elseif keyword == :drag_coeff
            drag_coeff = _kvn__parse_value(Val(:float), value)
        elseif keyword == :ephemeris_type
            ephemeris_type = _kvn__parse_value(Val(:integer), value)
        elseif keyword == :classification_type
            classification_type = _kvn__parse_value(Val(:string), value)
        elseif keyword == :norad_cat_id
            norad_cat_id = _kvn__parse_value(Val(:integer), value)
        elseif keyword == :element_set_number
            element_set_number = _kvn__parse_value(Val(:integer), value)
        elseif keyword == :rev_at_epoch
            rev_at_epoch = _kvn__parse_value(Val(:integer), value)
        elseif keyword == :bstar
            bstar = _kvn__parse_value(Val(:float), value)
        elseif keyword == :bterm
            bterm = _kvn__parse_value(Val(:float), value)
        elseif keyword == :mean_motion_dot
            mean_motion_dot = _kvn__parse_value(Val(:float), value)
        elseif keyword == :mean_motion_ddot
            mean_motion_ddot = _kvn__parse_value(Val(:float), value)
        elseif keyword == :agom
            agom = _kvn__parse_value(Val(:float), value)
        else
            @warn "Unknown or unsupported KVN keyword at line $l: $keyword"
        end
    end

    # == Return OMM Object =================================================================

    return OrbitMeanElementsMessage(;
        classification,
        creation_date,
        originator,
        message_id,
        object_name,
        object_id,
        center_name,
        ref_frame,
        ref_frame_epoch,
        time_system,
        mean_element_theory,
        epoch,
        semi_major_axis,
        mean_motion,
        eccentricity,
        inclination,
        raan,
        arg_of_pericenter,
        mean_anomaly,
        GM,
        mass,
        solar_rad_area,
        solar_rad_coeff,
        drag_area,
        drag_coeff,
        ephemeris_type,
        classification_type,
        norad_cat_id,
        element_set_number,
        rev_at_epoch,
        bstar,
        bterm,
        mean_motion_dot,
        mean_motion_ddot,
        agom
    )
end
