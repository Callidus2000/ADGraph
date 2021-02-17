# Contributing to this repository

No need for duplicating basic KnowHow about contributing, I think that everything is [well documented by github ;-)](https://github.com/github/docs/blob/main/CONTRIBUTING.md).

A big welcome and thank you for considering contributing to this repository! Besides the named basics getting an overview of the internal logic is quite helpful if you want to contribute. Let's get started..

### Working with the layout
This module was created with the help of [PSModuleDevelopment](https://github.com/PowershellFrameworkCollective/PSModuleDevelopment) and follows the default folder layout. Therefor the default rules apply:
- Don't touch the psm1 file
- Place functions you export in `functions/` (can have subfolders)
- Place private/internal functions invisible to the user in `internal/functions` (can have subfolders)
- Don't add code directly to the `postimport.ps1` or `preimport.ps1`.
  Those files are designed to import other files only.
- When adding files & folders, make sure they are covered by either `postimport.ps1` or `preimport.ps1`.
  This adds them to both the import and the build sequence.


## Pester tests
The module does use pester for general and functional tests. The general tests are provided by [PSModuleDevelopment](https://github.com/PowershellFrameworkCollective/PSModuleDevelopment) and perform checks like *"is the help well written and complete"*. This results in more than 3500 automatic tests over all.

