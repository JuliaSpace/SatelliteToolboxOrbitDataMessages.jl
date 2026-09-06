# Repository Guide

## Package Structure

- Single Julia package (`SatelliteToolboxOrbitDataMessages.jl`). Requires Julia 1.10 or newer.
- `src/SatelliteToolboxOrbitDataMessages.jl` is the module entrypoint and controls the source include order: types first, then `api.jl` and the shared utilities, then `fetcher/`, `parse/`, `read/`, `write/`, and `precompile.jl`. Feature files are plain includes.
- The parsers and writers are data-driven: the ordered keyword mappings in `src/parse/omm.jl` (`_OMM_*_KEYWORD_TO_FIELD`, `Vector{Pair{String, Symbol}}` in CCSDS keyword order) are shared by the XML/KVN parsers and writers. Adding or reordering an OMM field starts there.
- `ext/SatelliteToolboxTleExt` is a package extension that loads only when `SatelliteToolboxTle` is loaded; it provides `convert(TLE, omm)`.
- Tests are included unconditionally from `test/runtests.jl` and are organized by area (`test/parsing/`, `test/interface/`, `test/serialization/`, `test/fetchers/`, `test/extensions/`, `test/regressions/`); they do not mirror `src/` files one-to-one. Shared fixtures live in `test/helpers.jl`.
- Test-only dependencies are declared in `[extras]` + `[targets]` in `Project.toml` (`Random`, `Test`, `SatelliteToolboxTle`). `Manifest.toml` is gitignored.
- `src/show.jl` prints the messages with the public tree helpers of **SatelliteToolboxBase.jl** v2.1 (`print_tree`, `print_tree_body`, `PrintedField`, `PrintedSection`), imported by name in the module entrypoint, and overloads `SatelliteToolboxBase.print_tree_body` so that other types can print a message body under their own header. The values keep their exact string representation.
- `src/precompile.jl` holds a PrecompileTools `@compile_workload` covering parse, write (XML and KVN), and show; keep it exercising the public API when it changes.

## Commands

- Instantiate: `julia --project=. -e 'using Pkg; Pkg.instantiate()'`
- Full test suite: `julia --project=. -e 'using Pkg; Pkg.test()'` — the first run precompiles for minutes while printing little; use generous timeouts.
- Focused test file: `julia --project=. -e 'using SatelliteToolboxOrbitDataMessages, Test, NanoDates; include("test/helpers.jl"); include("test/parsing/kvn.jl")'` — always include `test/helpers.jl` first. Run `test/extensions/` and `test/fetchers/` through the full suite instead, since they need the test-only dependencies. There is no test-name selector.
- Some tests in `test/fetchers/` perform real network requests to Celestrak; offline runs will fail there.
- CI builds before testing and covers Julia 1.10 and the latest stable release on Linux x64, macOS arm64, and Windows x64, plus a separate nightly workflow. There is no `deps/build.jl`, so `Pkg.test()` alone reproduces CI.
- Build docs: `julia --project=docs docs/make.jl` (first run: `julia --project=docs -e 'using Pkg; Pkg.develop(path="."); Pkg.instantiate()'`). The manual pages contain executable `@repl` blocks, so the build fails if the examples break. CI builds and deploys docs via `julia-docdeploy`.

## Code Style

- Code follows Blue style with the local overrides in `.JuliaFormatter.toml` (alignment enabled, `whitespace_in_kwargs = true`); that file is the source of truth.
- Format: `julia -e 'using JuliaFormatter; format(".")'` — requires JuliaFormatter in the default environment, not in the project.
- CI does not run a format check; formatting is applied manually.
- Lines wrap at 92 characters. Comments are complete sentences ending with a period. Files start with a `## Description ##...` header block, and sections are separated by `# == Section ==...` comment rules.
- Every function, macro, and structure has a docstring. Private functions are prefixed with `_`, and format-specific backends use the `_<format>_<message>__<action>` pattern (e.g. `_kvn_omm__write`, `_xml_omm__parse`).
- Commit messages follow gitmoji short codes with a capitalized imperative summary of at most 50 characters (e.g. `:sparkles: Add support for writing OMMs in KVN`).

## Behavioral Constraints

- Writers always emit OMM version 3.0 regardless of the version stored in the message; the parsers accept 2.0 and 3.0 and validate the version-specific field rules in `_omm_check_mandatory_fields`.
- `==`, `isequal`, and `hash` for the OMM types are generated together in `src/types/omm.jl` to keep `isequal(x, y)` ⟹ `hash(x) == hash(y)`; never define one without the others.
- Round-trip fidelity (parse → write → parse yields an equal message) is a core invariant covered by `test/serialization/`; preserve it when touching parsers or writers.
- New tests follow the `@testset "Name" verbose = true begin ... end` pattern used in `test/runtests.jl`.
- `CHANGELOG.md` uses badge-style entries per version; add an entry when changing user-facing behavior.

## Not Configured

- No linter, pre-commit hooks, Aqua/JET checks, or CI format check are configured; do not invent them.
