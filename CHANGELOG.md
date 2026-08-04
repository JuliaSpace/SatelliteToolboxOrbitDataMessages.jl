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

Version 0.1.0
-------------

- Initial version.

[badge-breaking]: https://img.shields.io/badge/Breaking-DC2626?style=flat-square
[badge-deprecation]: https://img.shields.io/badge/Deprecation-D97706?style=flat-square
[badge-feature]: https://img.shields.io/badge/Feature-16A34A?style=flat-square
[badge-enhancement]: https://img.shields.io/badge/Enhancement-0284C7?style=flat-square
[badge-bugfix]: https://img.shields.io/badge/Bugfix-DB2777?style=flat-square
[badge-info]: https://img.shields.io/badge/Info-475569?style=flat-square
