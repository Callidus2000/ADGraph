# Changelog

## 2.0.0 (2026-05-12)
- New: Added support for foreign domains and credential forwarding across the ADGraph call chain.
- New: Added direct domain selection support to `Start-ADGraph`, allowing the GUI flow to skip forest-based domain selection.
- Upd: Reworked `Get-ADGraphCache` to use PSFramework task engine cache collectors instead of a module-global cache variable.
- Upd: Refined module metadata and help-related test handling for the current PowerShell environment.
- Fix: Removed the temporary `NoCache` switch again and aligned the help and analyzer checks with the final cache implementation.

## 1.0.4 (2022-05-24)
- New: Added GitHub Actions support for the repository.
- Fix: Resolved Pester help test failures across the module.
- Upd: Increased the module version to `1.0.4`.

## 1.0.3 (2022-05-13)
- Upd: Switched the Excel export dependency to `ImportExcel`.
- Upd: Added `CmdletBinding()` to public commands and internal helpers where needed.
- Fix: Improved file name creation for long output paths.
- Fix: Adjusted logging behavior in node formatting.

## 1.0.1 (2021-02-23)
- Fix: Duplicated the module license into the internal module folder.
- Fix: Corrected the `New-PSFLicense` command line used during module build and packaging.

## 1.0.0 (2021-02-17)
- New: Initial public release of the ADGraph module.
- New: Added `New-ADGraph` and `Start-ADGraph` for command-line and GUI-based AD graph generation.
- New: Added graph generation, Excel export, formatting, localization, XML type/format definitions, and Pester test coverage.