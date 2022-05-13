@{
	# Script module or binary module file associated with this manifest
	RootModule        = 'ADGraph.psm1'

	# Version number of this module.
	ModuleVersion     = '1.0.3'

	# ID used to uniquely identify this module
	GUID              = '17ffe655-33f2-4567-a3f1-ecccfac9fe4e'

	# Author of this module
	Author            = 'Sascha Spiekermann'

	# Company or vendor of this module
	#CompanyName = 'MyCompany'

	# Copyright statement for this module
	Copyright         = 'Copyright (c) 2021 Sascha Spiekermann'

	# Description of the functionality provided by this module
	Description       = 'ADVisual'

	# Minimum version of the Windows PowerShell engine required by this module
	PowerShellVersion = '5.1'

	# Modules that must be imported into the global environment prior to importing
	# this module
	RequiredModules   = @(
		@{ ModuleName = 'PSGraph'; ModuleVersion = '2.1.38.27' }
		@{ ModuleName = 'PSFramework'; ModuleVersion = '1.4.149' }
		@{ ModuleName = 'ActiveDirectory'; ModuleVersion = '1.0.0' }
		@{ ModuleName = 'ImportExcel'; ModuleVersion = '7.4.0' }
	)

	# Assemblies that must be loaded prior to importing this module
	# RequiredAssemblies = @('bin\ADGraph.dll')

	# Type files (.ps1xml) to be loaded when importing this module
	# TypesToProcess = @('xml\ADGraph.Types.ps1xml')

	# Format files (.ps1xml) to be loaded when importing this module
	# FormatsToProcess = @('xml\ADGraph.Format.ps1xml')

	# Functions to export from this module
	FunctionsToExport = @(
		'Start-ADGraph'
		'New-ADGraph'
	)

	# Cmdlets to export from this module
	CmdletsToExport   = ''

	# Variables to export from this module
	VariablesToExport = ''

	# Aliases to export from this module
	AliasesToExport   = ''

	# List of all modules packaged with this module
	ModuleList        = @()

	# List of all files packaged with this module
	FileList          = @()

	# Private data to pass to the module specified in ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
	PrivateData       = @{

		#Support for PowerShellGet galleries.
		PSData = @{

			# Tags applied to this module. These help with module discovery in online galleries.
			# Tags = @()

			# A URL to the license for this module.
			LicenseUri                 = 'https://github.com/Callidus2000/ADGraph/blob/master/LICENSE'

			# A URL to the main website for this project.
			ProjectUri                 = 'https://github.com/Callidus2000/ADGraph/'

			# A URL to an icon representing this module.
			IconUri                    = ''

			# ReleaseNotes of this module
			ReleaseNotes               = ''

			ExternalModuleDependencies = @('ActiveDirectory')

		} # End of PSData hashtable

	} # End of PrivateData hashtable
}