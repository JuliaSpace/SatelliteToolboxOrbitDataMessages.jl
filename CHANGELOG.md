SatelliteToolboxOrbitDataMessages.jl Changelog
==============================================

Version 0.2.0
-------------

- ![BREAKING][badge-breaking] The struct `OrbitMeanElementsMessage` now contains the three
  sections defined by the CCSDS 502.0-B-3 standard directly: `header`, `metadata`, and
  `data`. The intermediate types `OmmBody` and `OmmSegment` were removed, so the fields are
  now accessed as, e.g., `omm.metadata.object_name` instead of
  `omm.body.segment.metadata.object_name`.
- ![BREAKING][badge-breaking] The public parsing API is now string-based only: the
  `parse_omm`, `parse_omms`, and `parse_odm` methods that received an `XML.Cursor` were
  removed. The validation is based on the OMM version, adding support for the version 2.0
  rules.
- ![BREAKING][badge-breaking] The `strict` keyword was removed from the parsing functions
  and the fetchers. The parsers always accommodate the deviations found in real-world
  files: the XML tags and the OMM `id` attribute are matched ignoring the case, empty XML
  elements are treated as absent fields, and a missing `CREATION_DATE` is preserved as
  `nothing`.
- ![BREAKING][badge-breaking] Malformed input now throws the new `OdmParseError`, which
  carries the related CCSDS keyword and, for KVN input, the line number, instead of an
  `ArgumentError`. `ArgumentError` is reserved for invalid keyword arguments.
- ![BREAKING][badge-breaking] `parse_omm` and `read_omm` throw an `OdmParseError` when the
  input does not contain an OMM instead of returning `nothing`, and every parser rejects
  XML documents whose root tag is not recognized. In the KVN format, any content before
  the first version keyword is ignored by every entry point.
- ![BREAKING][badge-breaking] The keyword `file_type` was renamed to `format` in every
  parsing, reading, and writing function.
- ![BREAKING][badge-breaking] The field `user_defined_parameters` is always a
  `Vector{Pair{String, String}}`; an empty vector means that the section is absent, as for
  the comments.
- ![BREAKING][badge-breaking] The accessor module `ODM` was removed. Every field of the
  header, metadata, and data sections is now a property of the message, so `omm.epoch` is
  equivalent to `omm.data.epoch`. The `comments` fields are only reachable through their
  sections.
- ![BREAKING][badge-breaking] The Space-Track fetcher always URL-encodes the predicate
  values, keeping the characters used by its operators, so the `HTML{String}` marker for
  raw values is no longer accepted.
- ![BREAKING][badge-breaking] The **SatelliteToolboxTle.jl** extension now requires
  version 2 of that package.
- ![Feature][badge-feature] `parse_omm` and `parse_omms` now support the KVN format, which
  is automatically detected from the content or selected with the new `format` keyword.
  The comments are preserved and attributed to the corresponding message sections.
- ![Feature][badge-feature] `write_omm` now supports the KVN format through the `format`
  keyword, which can be `:xml`, `:kvn`, or, when writing to a file, `:auto` to infer the
  format from the file extension. It also accepts a vector of messages: the XML output
  wraps them in an NDM document, whereas the KVN output writes them sequentially.
- ![Feature][badge-feature] `parse_odm`, `read_odm`, and `write_odm` accept the `format`
  keyword as well, adding the KVN format to the generic ODM functions. Other message types
  found in KVN input are skipped with a warning, as in XML.
- ![Feature][badge-feature] Add `read_omms` to read a set of OMMs from a file or IO stream.
  Additionally, `read_omm` and `read_omms` now forward every keyword to the parsing
  functions, so `format` can also be selected when reading.
- ![Feature][badge-feature] The section types `OmmHeader`, `OmmMetadata`, and `OmmData` are
  exported with their keyword constructors and a copy constructor each, and the message
  can be assembled from them with `OrbitMeanElementsMessage(header, metadata, data;
  version)`. Every constructor validates the rules relating the fields. The alias `OMM`
  can be used instead of `OrbitMeanElementsMessage`.
- ![Feature][badge-feature] `OmmCovarianceMatrix` can be created from a 6×6 matrix and
  converted back with `Matrix` or `SMatrix`.
- ![Feature][badge-feature] Add the conversion from TLEs to OMMs to the
  **SatelliteToolboxTle.jl** extension: `OrbitMeanElementsMessage(tle; kwargs...)` creates
  a message from a TLE, accepting any keyword of the keyword constructor to override the
  generated fields (e.g. the creation date and the originator), and
  `convert(OrbitMeanElementsMessage, tle)` uses the default header. The two-digit years of
  the TLE epoch and of the international designator are interpreted with the SGP4 pivot
  (years from 57 to 99 refer to the 20th century).
- ![Enhancement][badge-enhancement] The parsers and writers are several times faster and
  allocate a fraction of the memory: the fields are parsed into typed builders, the dates
  are read and written without `DateFormat`, the KVN lines are scanned without regular
  expressions in a single pass, and the XML output is streamed instead of built as a tree.
  Parsing one XML message went from 20 μs and 27 KiB to 9 μs and 8 KiB, and writing it
  from 15 μs and 46 KiB to 7 μs and 23 KiB. The XML documents now end with a line break.
- ![Enhancement][badge-enhancement] Improve the performance of comparing messages: `==`
  and `hash` are now type-stable and allocation-free.
- ![Enhancement][badge-enhancement] Print the messages with the tree helpers of
  **SatelliteToolboxBase.jl** v2.1, which is now a dependency, so that the layout matches
  the other types of the ecosystem: the header, the metadata, and the data are tree nodes,
  and the data subsections are nested under the data. The faces `satellitetoolbox_odm_*`
  were replaced by the `satellitetoolbox_base_*` faces registered by
  **SatelliteToolboxBase.jl**. The B* parameter is labeled `B*`, as in the other packages.
- ![Bugfix][badge-bugfix] Define `isequal` for the message types, fixing the behavior of
  messages containing `-0.0` or `NaN` values in `Set`s and `Dict`s.
- ![Bugfix][badge-bugfix] `convert(TLE, omm)` now throws an error when the epoch year
  cannot be represented by the two-digit TLE year (outside the interval from 1957 to 2056)
  instead of silently wrapping it, and copies the OMM `EPHEMERIS_TYPE` into the TLE.
- ![Bugfix][badge-bugfix] `write_omm` and `write_odm` now validate the message before
  opening the output file, so a failure no longer truncates an existing file.
- ![Bugfix][badge-bugfix] The parsing functions now handle inputs with a leading
  byte-order mark.
- ![Bugfix][badge-bugfix] The Celestrak fetcher now builds the query URL correctly when a
  custom endpoint already carries query parameters.
- ![Bugfix][badge-bugfix] The Space-Track login now throws an `OdmLoginError` for network
  failures, and the cached session cookie is saved with owner-only permissions.

Version 0.1.0
-------------

- Initial version.

[badge-breaking]: https://img.shields.io/badge/Breaking-DC2626?style=flat-square
[badge-deprecation]: https://img.shields.io/badge/Deprecation-D97706?style=flat-square
[badge-feature]: https://img.shields.io/badge/Feature-16A34A?style=flat-square
[badge-enhancement]: https://img.shields.io/badge/Enhancement-0284C7?style=flat-square
[badge-bugfix]: https://img.shields.io/badge/Bugfix-DB2777?style=flat-square
[badge-info]: https://img.shields.io/badge/Info-475569?style=flat-square
