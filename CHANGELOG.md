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
  removed. The validation is now based on the OMM version instead of the `strict` keyword,
  adding support for the version 2.0 rules.
- ![Feature][badge-feature] `parse_omm` and `parse_omms` now support the KVN format, which
  is automatically detected from the content or selected with the new `file_type` keyword.
  The comments are preserved and attributed to the corresponding message sections.
- ![Feature][badge-feature] `write_omm` now supports the KVN format through the `file_type`
  keyword, which can be `:xml`, `:kvn`, or, when writing to a file, `:auto` to infer the
  format from the file extension. It also accepts a vector of messages: the XML output
  wraps them in an NDM document, whereas the KVN output writes them sequentially.
- ![Feature][badge-feature] Add `read_omms` to read a set of OMMs from a file or IO stream.
  Additionally, `read_omm` and `read_omms` now forward every keyword to the parsing
  functions, so `file_type` can also be selected when reading.
- ![Enhancement][badge-enhancement] Improve the performance of parsing and comparing
  messages: `==` and `hash` are now type-stable and allocation-free, and the parsers
  perform fewer allocations and keyword lookups.
- ![Enhancement][badge-enhancement] Reduce the allocations and dynamic dispatches in the
  parsers, the writers, and the display code.
- ![Enhancement][badge-enhancement] Print the messages with the tree helpers of
  **SatelliteToolboxBase.jl** v2.1, which is now a dependency, so that the layout matches
  the other types of the ecosystem: the header, the metadata, and the data are tree nodes,
  and the data subsections are nested under the data. The faces `satellitetoolbox_odm_*`
  were replaced by the `satellitetoolbox_base_*` faces registered by
  **SatelliteToolboxBase.jl**.
- ![Bugfix][badge-bugfix] Define `isequal` for the message types, fixing the behavior of
  messages containing `-0.0` or `NaN` values in `Set`s and `Dict`s.
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
