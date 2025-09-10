## Description #############################################################################
#
# Functions to parse dates according to the CCSDS standards for Orbit Data Messages.
#
############################################################################################

funciton _parse_date(date_str::String) -> DateTime
    # Try to parse the date string with the most common formats.
    date_formats = [
        dateformat"yyyy-MM-ddTHH:MM:SS",
        dateformat"yyyy-MM-ddTHH:MM:SSZ",
        dateformat"yyyy-MM-ddTHH:MM:SS",
        dateformat"yyyy-MM-dd HH:MM:SS.sss",
        dateformat"yyyy-MM-dd HH:MM:SS",
        dateformat"yyyy-MM-ddTHH:MM:SS.ssssss",
        dateformat"yyyy-MM-dd HH:MM:SS.ssssss",
        dateformat"yyyy-MM-ddTHH:MM:SS.sssssss",
        dateformat"yyyy-MM-dd HH:MM:SS.sssssss"
    ]

    for fmt in date_formats
        try
            return DateTime(date_str, fmt)
        catch e
            if !(e isa ArgumentError)
                rethrow(e)
            end
        end
    end

    throw(ArgumentError("The date string `$date_str` is not in a recognized format."))
end
