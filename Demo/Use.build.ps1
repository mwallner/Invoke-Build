
<#
.Synopsis
	Examples of Use-BuildAlias (use).

.Description
	Points of interest:

	* If a build script changes the location it does not have to restore it.

	* Tasks v2.0.50727 and v4.0.30319 are conditional (see the If parameter).

	* Use of several frameworks simultaneously.

.Example
	Invoke-Build . Use.build.ps1

.Link
	Invoke-Build
	.build.ps1
#>

# Use the current framework at the script level (used by CurrentFramework).
# In order to use the current framework pass $null or '':
use $null MSBuild

# It is fine to change the location (used for -If) and leave it changed.
Set-Location "$env:windir\Microsoft.NET\Framework"

# This task calls MSBuild 2.0 and tests its version.
task v2.0.50727 -If (Test-Path 'v2.0.50727') {
	use Framework\v2.0.50727 MSBuild
	$version = exec { MSBuild /version /nologo }
	$version
	assert ($version -like '2.0.*')
}

# This task calls MSBuild 4.0 and tests its version.
task v4.0.30319 -If (Test-Path 'v4.0.30319') {
	use Framework\v4.0.30319 MSBuild
	$version = exec { MSBuild /version /nologo }
	$version
	assert ($version -like '4.0.*')
}

# This task simply uses the alias set at the scope level.
task CurrentFramework {
	$version = exec { MSBuild /version /nologo }
	$version
}

# The directory path used for aliased commands should be resolved.
task ResolvedPath {
	use . MyTestAlias
	$path = (Get-Command MyTestAlias).Definition
	assert (($path -like '?:\*\MyTestAlias') -or ($path -like '\\*\MyTestAlias'))
}

# This task fails due to the invalid framework specified.
task InvalidFramework {
	use Framework\xyz MSBuild
}

# This task fails due to the invalid directory specified.
task InvalidDirectory {
	use \MissingScripts MyScript
}

# This task fails because `use` should not be dot-sourced.
task DoNotDotSource {
	. use $null MSBuild
}

# The default task calls the others and checks that InvalidFramework and
# DoNotDotSource have failed. Failing tasks are referenced as @{Task=1}.
task . `
v2.0.50727,
v4.0.30319,
CurrentFramework,
ResolvedPath,
@{InvalidFramework=1},
@{InvalidDirectory=1},
@{DoNotDotSource=1}, {
	$e = error InvalidFramework
	assert ("$e" -like "Directory does not exist: '*\xyz'.")

	$e = error InvalidDirectory
	assert ("$e" -eq "Directory does not exist: '\MissingScripts'.")

	$e = error DoNotDotSource
	assert ("$e" -like "Use-BuildAlias should not be dot-sourced.")
}