SatelliteToolboxOrbitDataMessages.jl Changelog
==============================================

Version 0.2.0
-------------

- ![BREAKING][badge-breaking] OMM version 2.0 messages are now validated against the 2.0
  schema in strict mode: the 3.0-only fields `MESSAGE_ID`, `CLASSIFICATION`, `BTERM`, and
  `AGOM` are rejected, and `BSTAR` and `MEAN_MOTION_DDOT` are required when a
  `tleParameters` section is present.
- ![BREAKING][badge-breaking] `parse_omm` now only searches for the `omm` element at the
  document root or as a direct child of an `ndm` root, matching `parse_odm`. Elements
  nested inside unsupported roots are no longer parsed.
- ![BREAKING][badge-breaking] `write_omm` and `write_odm` now throw an `ArgumentError`
  when both fields of a mutually exclusive pair are set (`SEMI_MAJOR_AXIS`/`MEAN_MOTION`,
  `BSTAR`/`BTERM`, and `MEAN_MOTION_DDOT`/`AGOM`), instead of emitting schema-invalid XML.
- ![Enhancement][badge-enhancement] The parser was reworked to reduce allocations and
  remove type instabilities: the section parsers now return concrete `NamedTuple` types,
  the covariance matrix is built without intermediate dictionaries, duplicate fields are
  detected with bitmasks instead of per-call `Set`s, and unsupported NDM subtrees are
  skipped without tokenization.
- ![Enhancement][badge-enhancement] The Celestrak fetcher and the TLE extension now accept
  international designators with lowercase piece letters.
- ![Enhancement][badge-enhancement] The Space-Track fetcher now finds the authentication
  cookie by name in the jar, saves the cookie cache only when the expiration changed, and
  removes an unreadable cache file with a warning instead of an error.
- ![Bugfix][badge-bugfix] Messages containing `NaN` values (e.g. in the covariance matrix)
  can now be found in `Dict`s and `Set`s thanks to a field-wise `isequal` definition.
- ![Bugfix][badge-bugfix] Copying a message parsed in non-strict mode without a
  `CREATION_DATE` no longer throws a `TypeError`.
- ![Bugfix][badge-bugfix] The keyword constructor now defensively copies
  `user_defined_parameters`, so mutating the caller's vector does not change the message.
- ![Bugfix][badge-bugfix] An empty `REF_FRAME_EPOCH` tag is now tolerated in non-strict
  mode since the field is optional.
- ![Bugfix][badge-bugfix] Displaying a Space-Track fetcher with an expired login now
  prints "Login expired" instead of a negative duration.

Version 0.1.0
-------------

- Initial version.

[badge-breaking]: https://img.shields.io/badge/Breaking-DC2626?style=flat-square
[badge-deprecation]: https://img.shields.io/badge/Deprecation-D97706?style=flat-square
[badge-feature]: https://img.shields.io/badge/Feature-16A34A?style=flat-square
[badge-enhancement]: https://img.shields.io/badge/Enhancement-0284C7?style=flat-square
[badge-bugfix]: https://img.shields.io/badge/Bugfix-DB2777?style=flat-square
[badge-info]: https://img.shields.io/badge/Info-475569?style=flat-square
