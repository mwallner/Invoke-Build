﻿
<#
.Synopsis
	Help script (https://github.com/nightroman/Helps)
#>

### Invoke-Build.ps1
@{
	command = 'Invoke-Build.ps1'
	synopsis = 'Invoke-Build - Build Automation in PowerShell'

	description = @'
	The command invokes specified and referenced tasks defined in a PowerShell
	script. The process is called build and the script is called build script.

	A build script defines parameters, variables, tasks, and blocks. Any code
	is invoked with the current location set to $BuildRoot, normally the build
	script directory. $ErrorActionPreference is set to 'Stop'.

	To get help for commands dot-source Invoke-Build:

		PS> . Invoke-Build
		PS> help task -full

	USING BUILD SCRIPT PARAMETERS

	Build scripts define parameters using param(). They are used in tasks as
	$ParameterName for reading and as $script:ParameterName for writing.

	The following parameter names are reserved for the engine:
	Task, File, Result, Safe, Summary, WhatIf, Log

	Script parameters are specified for Invoke-Build as if they are its own.
	Known issue #4. Script switches should be specified after Task and File.

	PUBLIC COMMANDS

	Scripts should use available aliases, function names are for reference.

		task      (Add-BuildTask)
		exec      (Invoke-BuildExec)
		assert    (Assert-Build)
		equals    (Assert-BuildEquals)
		property  (Get-BuildProperty)
		requires  (Test-BuildAsset)
		use       (Use-BuildAlias)
		error     (Get-BuildError)

		Get-BuildSynopsis
		Resolve-MSBuild
		Write-Build
		Write-Warning [1]
		Get-BuildFile [2]

	[1] Write-Warning is redefined internally in order to count warnings in
	tasks, build, and other scripts. But warnings in modules are not counted.

	[2] Exists only as a pattern for wrappers.

	SPECIAL ALIASES

		Invoke-Build
		Build-Parallel

	These aliases are for the scripts Invoke-Build.ps1 and Build-Parallel.ps1.
	Use them for calling nested builds, i.e. omit script extensions and paths.
	With this rule Invoke-Build tools can be kept together with build scripts.

	PUBLIC VARIABLES

	Exposed variables designed for build scripts and tasks:

		$WhatIf    - WhatIf mode, Invoke-Build parameter
		$BuildRoot - build script location, by default
		$BuildFile - build script path
		$BuildTask - initial tasks
		$Task      - current task

	$BuildRoot may be changed by scripts on loading in order to set a custom
	build root directory. Other variables should not be changed.

	$Task is available for script blocks defined by task parameters If, Inputs,
	Outputs, and Jobs and by blocks Enter|Exit-BuildTask, Enter|Exit-BuildJob,
	Set-BuildHeader.

		$Task properties available for reading:

		- Name - [string], task name
		- Jobs - [object[]], task jobs
		- Started - [DateTime], task start time

		In Exit-BuildTask
	    - Error - error which stopped the task
	    - Elapsed - [TimeSpan], task duration

	The variable $_ may be exposed. In special cases it is used as an input.
	In other cases build scripts should not assume anything about its value.

	BUILD BLOCKS

	Scripts may define the following build blocks. They are invoked:

		Enter-Build {} - before all tasks
		Exit-Build {} - after all tasks

		Enter-BuildTask {} - before each task
		Exit-BuildTask {} - after each task

		Enter-BuildJob {} - before each task action
		Exit-BuildJob {} - after each task action

		Set-BuildHeader {param($path)} - custom task header writer

	Nested builds do not inherit parent blocks.
	If Enter-X is called then Exit-X is called.
	Blocks are not called on WhatIf, except Set-BuildHeader.

	Enter-Build and Exit-Build are invoked in the script scope. Enter-Build is
	a good place for heavy initialization, it does not have to care of WhatIf.
	Also, unlike the top level script code, Enter-Build can output text.

	Enter-BuildTask, Exit-BuildTask, Enter-BuildJob, and Exit-BuildJob are
	invoked in the same scope, the parent of task action blocks.

	DOT-SOURCING Invoke-Build

	Build-like environment can be imported to normal scripts:

		. Invoke-Build [<root>]

	When this command is invoked from a script it

	- sets $ErrorActionPreference to Stop
	- sets $BuildFile to the invoked script path
	- sets $BuildRoot to the script directory or <root>
	- sets the current PowerShell location to $BuildRoot
	- imports utility commands
	    - assert
	    - equals
	    - exec
	    - property
	    - requires
	    - use
	    - Write-Build

	Some other build commands are also imported. They are available for getting
	help and not designed for use in normal scripts.

	PRIVATE FUNCTIONS AND VARIABLES

	Function and variable names starting with '*' are reserved for the engine.
	Scripts should avoid using functions and variables with such names.
'@

	parameters = @{
		Task = @'
		One or more tasks to be invoked. If it is not specified, null, empty,
		or equal to '.' then the task '.' is invoked if it exists, otherwise
		the first added task is invoked.

		Names with wildcard characters are reserved for special cases.

		SAFE TASKS

		If a task name is appended with "?" then the task is allowed to fail
		without stopping the build, i.e. other specified tasks are invoked.

		SPECIAL TASKS

		? - Tells to list the tasks with brief information without invoking. It
		also checks tasks and throws errors on missing or cyclic references.
		Task synopses are defined in preceding comments as # Synopsis: ...

		?? - Tells to collect and get all tasks as an ordered dictionary. It
		can be used by external tools for analysis, TabExpansion, and etc.

		Tasks ? and ?? set $WhatIf to true. Properly designed build scripts
		should not perform anything significant if $WhatIf is set to true.

		* - Tells to invoke all tasks, for example when tasks are tests.

		** - Invokes * for all files *.test.ps1 found recursively in the
		current directory or a directory specified by the parameter File.
		Other parameters except Result and Safe are ignored.

		Tasks ? and ?? can be combined with **
		?, ** - To show all test tasks without invoking.
		??, ** - To get task dictionaries for all test files.
'@
		File = @'
		A build script which defines tasks by the alias 'task' (Add-BuildTask).

		If it is not specified then Invoke-Build looks for *.build.ps1 files in
		the current location. A single file is used as the script. If there are
		more files then .build.ps1 is used if it exists, otherwise build fails.

		If the build file is not found then a script defined by the environment
		variable InvokeBuildGetFile is called with the path as an argument. For
		this location it may return the full path of a special build script.

		If the file is still not found then parent directories are searched.

		INLINE SCRIPT

		`File` is a script block which is normally used in order to assemble a
		build on the fly without creating and using an extra build script file.

		Script parameters are not supported. Use the parent scope variables
		instead, either directly or with the helpers `property` and `requires`.

		$BuildRoot is the calling script root (or the current location). If it
		is not what the build needs as its root directory, then change this
		variable in the beginning of the inline script block.

		$BuildFile is the calling script (it may be null, e.g. in jobs).
		This variable is rarely used, just keep in mind the difference.

		Persistent and parallel builds are not supported.
'@
		Result = @'
		Tells to output build information using a variable. It is either a name
		of variable to be created or any object with the property Value to be
		assigned (e.g. [ref] or [hashtable]).

		Result object properties:

			All - all available tasks
			Error - a terminating build error
			Tasks - invoked tasks including nested
			Errors - error objects including nested
			Warnings - warning objects including nested
			Redefined - list of original redefined tasks

		Tasks is a list of objects:

			Name - task name
			Jobs - task jobs
			Error - task error
			Started - start time
			Elapsed - task duration
			InvocationInfo - task location (.ScriptName and .ScriptLineNumber)

		Errors is a list of objects:

			Error - original error record
			File - current $BuildFile
			Task - current $Task or null for non-task errors

		Warnings is a list of objects:

			Message - warning message
			File - current $BuildFile
			Task - current $Task or null for non-task warnings

		These data should be used for reading only.
		Other result and task data should not be used.
'@
		Safe = @'
		Tells to catch a build failure, store an error as the property Error of
		Result and return quietly. A caller should use Result and check Error.

		Some exceptions are possible even in the safe mode. They show serious
		errors, not build failures. For example, a build script is missing.

		When Safe is used together with the special task ** (invoke *.test.ps1)
		then task failures stop current test scripts, not the whole testing.
'@
		Summary = @'
		Tells to show summary information after the build. It includes task
		durations, names, locations, and error messages.
'@
		WhatIf = @'
		Tells to show preprocessed tasks and their scripts instead of invoking
		them. If a script does anything but adding and configuring tasks then
		it should check for $WhatIf and skip some significant actions.
'@
	}

	outputs = @(
		@{
			type = 'Text'
			description = @'
		Build process log which includes task starts, ends with durations,
		warnings, errors, and output of tasks and commands that they invoke.

		Output is expected from tasks and blocks. But script scope code should
		not output anything. Unexpected output causes warnings, in the future
		it may be treated as an error.
'@
		}
	)

	examples = @(
		@{code={
	# Invoke the default task ('.' or the first added) in the default script
	# (a single file like *.build.ps1 or .build.ps1 if there are two or more)

	Invoke-Build
		}}

		@{code={
	# Invoke tasks Build and Test from the default script with parameters.
	# The script defines parameters Output and WarningLevel by param().

	Invoke-Build Build, Test -Output log.txt -WarningLevel 4
		}}

		@{code={
	# Show tasks in the default script and the specified script

	Invoke-Build ?
	Invoke-Build ? Project.build.ps1

	# Custom formatting is possible, too

	Invoke-Build ? | Format-Table -AutoSize
	Invoke-Build ? | Format-List Name, Synopsis
		}}

		@{code={
	# Get task names without invoking for listing, TabExpansion, etc.

	$all = Invoke-Build ??
	$all.Keys
		}}

		@{code={
	# Invoke all in Test1.test.ps1 and all in Tests\...\*.test.ps1

	Invoke-Build * Test1.test.ps1
	Invoke-Build ** Tests
		}}

		@{code={
	# Using the build results, e.g. for performance analysis

	# Invoke the build and keep results in the variable Result
	Invoke-Build -Result Result

	# Show invoked tasks ordered by Elapsed with ScriptName included
	$Result.Tasks |
	Sort-Object Elapsed |
	Format-Table -AutoSize Elapsed, @{
		Name = 'Task'
		Expression = {$_.Name + ' @ ' + $_.InvocationInfo.ScriptName}
	}
		}}

		@{code={
	# Using the build results, e.g. for tasks summary

	try {
		# Invoke the build and keep results in the variable Result
		Invoke-Build -Result Result
	}
	finally {
		# Show task summary information after the build
		$Result.Tasks | Format-Table Elapsed, Name, Error -AutoSize
	}
		}}
	)

	links = @(
		@{ text = 'Wiki'; URI = 'https://github.com/nightroman/Invoke-Build/wiki' }
		@{ text = 'Project'; URI = 'https://github.com/nightroman/Invoke-Build' }
		# aliases
		@{ text = 'task      (Add-BuildTask)' }
		@{ text = 'exec      (Invoke-BuildExec)' }
		@{ text = 'assert    (Assert-Build)' }
		@{ text = 'equals    (Assert-BuildEquals)' }
		@{ text = 'property  (Get-BuildProperty)' }
		@{ text = 'requires  (Test-BuildAsset)' }
		@{ text = 'use       (Use-BuildAlias)' }
		@{ text = 'error     (Get-BuildError)' }
		# functions
		@{ text = 'Get-BuildSynopsis' }
		@{ text = 'Resolve-MSBuild' }
		@{ text = 'Write-Build' }
		# external
		@{ text = 'Build-Checkpoint' }
		@{ text = 'Build-Parallel' }
	)
}

### Add-BuildTask
@{
	command = 'Add-BuildTask'
	synopsis = '(task) Defines a build task and adds it to the task list.'

	description = @'
	Scripts use its alias 'task'. This is the main feature of build scripts. At
	least one task must be added. Normally it is used in the build script scope
	but it can be called anywhere, e.g. imported, created dynamically, and etc.

	In fact, this function is literally all that build scripts really need.
	Other build functions are just helpers, scripts do not have to use them.

	Task help-comments are special comments preceding task definitions

		# Synopsis: ...
		task ...

	Synopsis lines are used in task information returned by the command

		Invoke-Build ?
'@

	parameters = @{
		Name = @'
		The task name. Wildcard characters are deprecated and "?" must not be
		the first character. Duplicated names are allowed, each added task
		overrides previously added with the same name.
'@
		Jobs = @'
		Specifies the task jobs. Jobs are other task references and own
		actions. Any number of jobs is allowed. Jobs are invoked in the
		specified order.

		Valid jobs are:

			[string] - an existing task name, normal reference
			[string] "?TaskName" - reference to a task allowed to fail
			[scriptblock] - action, a script block invoked for this task
'@
		After = @'
		Tells to add this task to the end of the specified task job lists.

		Altered tasks are defined as by their names or by the command 'job'.
		In the latter case options are applied to the added task reference.

		Parameters After and Before are used in order to alter task jobs in
		special cases when direct changes in task source code are not suitable.
'@
		Before = @'
		Tells to add this task to job lists of the specified tasks. It is
		inserted before the first script job, if any, or added to the end.
		Note that Before tasks are added before After tasks.

		See After for details.
'@
		If = @{default = '$true'; description = @'
		Specifies the optional condition to be evaluated. If the condition
		evaluates to false then the task is not invoked. The condition is
		defined in one of two ways depending on the requirements.

		Using standard Boolean notation (parenthesis) the condition will only
		be evaluated when the task is loaded into the build engine. A use case
		for this notation might be evaluating parameters that are passed into
		the build.

			Example:
				task SomeTask -If ($SomeCondition) {...}

		Using script block notation (curly braces) the condition will be
		evaluated dynamically on task invocation. If a task is referenced by
		several tasks then the condition is evaluated each time until it gets
		true and the task is invoked. The script block notation is normally
		used for a condition that may be defined or changed during the build.

			Example:
				task SomeTask -If {$SomeCondition} {...}

		On WhatIf:
		- Boolean conditions are evaluated and treated accordingly.
		- Script block conditions are treated as true without invocation.
'@}
		Inputs = @'
		Specifies the input items, tells to process the task as incremental,
		and requires the parameter Outputs with the optional switch Partial.

		Inputs are file items or paths or a script block which gets them.

		Outputs are file paths or a script block which gets them.
		A script block is invoked with input paths piped to it.

		Automatic variables for incremental task actions:

			$Inputs - full input paths, array of strings
			$Outputs - result of the evaluated Outputs

		With the switch Partial the task is processed as partial incremental.
		There must be one-to-one correspondence between Inputs and Outputs.

		Partial task actions often contain "process {}" blocks.
		Two more automatic variables are available for them:

			$_ - full path of an input item
			$2 - corresponding output path

		See also wiki topics about incremental tasks:
		https://github.com/nightroman/Invoke-Build/wiki
'@
		Outputs = @'
		Specifies the output paths of the incremental task, either directly on
		task creation or as a script block invoked with the task. It is used
		together with Inputs. See Inputs for more details.
'@
		Partial = @'
		Tells to process the incremental task as partial incremental. It is
		used together with Inputs and Outputs. See Inputs for details.
'@
		Data = @'
		Any object attached to the task. It is not used by the engine.
		When the task is invoked the object is available as $Task.Data.
'@
		Done = @'
		Specifies the command or a script block invoked when the task is done.
		It is mostly designed for wrapper functions creating special tasks.
'@
		Source = @'
		Specifies the task source. It is used by wrapper functions in order to
		provide the actual source for location messages and task help synopsis.
'@
	}

	examples = @(
		### Job combinations
		@{
			code={
	# Dummy task with no jobs
	task Task1

	# Alias of another task
	task Task2 Task1

	# Combination of tasks
	task Task3 Task1, Task2

	# Simple action task
	task Task4 {
	    # action
	}

	# Typical complex task: referenced task(s) and one own action
	task Task5 Task1, Task2, {
	    # action after referenced tasks
	}

	# Possible complex task: actions and tasks in any required order
	task Task6 {
	    # action before Task1
	},
	Task1, {
	    # action after Task1 and before Task2
	},
	Task2
			}
			remarks = @'
	This example shows various possible combinations of task jobs.
'@
		}

		### Splatting helper
		@{
			code={
	# Helper for tasks with complex parameters composed as hashtables
	function taskx($Name, $Param) {task $Name @Param -Source $MyInvocation}

	# Synopsis: Complex task with parameters as a hashtable.
	taskx MakeDocs @{
		Inputs = {Get-Item *.md}
		Outputs = {Get-Item *.htm}
		Partial = $true
		Jobs = 'Task1', {
			#...
		}
	}

	# Synopsis: Simple task with usual parameters.
	task Task1 {
		#...
	}
			}
			remarks = @'
	Tasks with complex parameters are often difficult to compose in a readable
	way. Use PowerShell splatting or add the above helper `taskx` to a script
	in order to compose parameters as hashtables.
'@
		}
	)

	links = @(
		@{ text = 'Get-BuildError' }
		@{ URI = 'https://github.com/nightroman/Invoke-Build/wiki' }
	)
}

### Get-BuildError
@{
	command = 'Get-BuildError'
	synopsis = '(error) Gets the specified task error if it has failed.'

	description = @'
	Scripts use its alias 'error'. It is used when some tasks are referenced as
	'?TaskName' in order to get and analyse their errors on allowed failures.
'@

	parameters = @{
		Task = @'
		Name of the task which error is requested.
'@
	}

	outputs = @(
		@{
			type = 'Error'
			description = @'
		The error object or null if the task has no errors.
'@
		}
	)

	links = @(
		@{ text = 'Add-BuildTask' }
	)
}

### Assert-Build
@{
	command = 'Assert-Build'
	synopsis = '(assert) Checks for a condition.'

	description = @'
	Scripts use its alias 'assert'. This command checks for a condition and if
	it is not true throws an error with the default or a specified message.

	NOTE: Consider to use 'equals X Y' instead of 'assert (X -eq Y)'. It is
	easier to type, it avoids subtle PowerShell conversions, and its error
	message is more informative.
'@

	parameters = @{
		Condition = @'
		The condition.
'@
		Message = @'
		An optional message describing the assertion condition.
'@
	}

	links = @(
		@{ text = 'Assert-BuildEquals' }
	)
}

### Assert-BuildEquals
@{
	command = 'Assert-BuildEquals'
	synopsis = '(equals) Verifies that two specified objects are equal.'

	description = @'
	Scripts use its alias 'equals'. This command verifies that two specified
	objects are equal using [Object]::Equals(). If objects are not equal the
	command fails with a message showing object values and types.

	NOTE: Comparison of strings is case sensitive. For case insensitive
	comparison use 'assert (X -eq Y)'.
'@

	parameters = @{
		A = 'The first object.'
		B = 'The second object.'
	}

	links = @(
		@{ text = 'Assert-Build' }
	)
}

### Get-BuildProperty
@{
	command = 'Get-BuildProperty'
	synopsis = '(property) Gets the session or environment variable or the default.'

	description = @'
	Scripts use its alias 'property'. The command returns:

		- session variable value if it is not $null or ''
		- environment variable if it is not $null or ''
		- default value if it is not $null
		- error
'@

	parameters = @{
		Name = @'
		Specifies the session or environment variable name.
'@
		Value = @'
		Specifies the default value. If it is omitted or null then the variable
		must exist with a not empty value. Otherwise an error is thrown.
'@
	}

	outputs = @(
		@{
			type = 'Object'
			description = 'Requested property value.'
		}
	)

	examples = @(
		@{code={
	# Inherit an existing value or throw an error

	$OutputPath = property OutputPath
		}}

		@{code={
	# Get an existing value or use the default

	$WarningLevel = property WarningLevel 4
		}}
	)

	links = @(
		@{ text = 'Test-BuildAsset' }
	)
}

### Get-BuildSynopsis
@{
	command = 'Get-BuildSynopsis'
	synopsis = 'Gets the task synopsis.'

	description = @'
	Gets the specified task synopsis if it is available.
	Task synopsis is defined in preceding comments as # Synopsis: ...
'@

	parameters = @{
		Task = @'
		The task object. During the build, the current task is available as the
		automatic variable $Task.
'@
		Hash = @'
		Any hashtable to be used as a cache. Build scripts do not have to
		specify it, it is designed for external tools.
'@
	}

	outputs = @(
		@{
			type = 'String'
			description = 'Task synopsis line.'
		}
	)

	examples = @(
		@{code={
	# Print task path and synopsis
	Set-BuildHeader {
		param($Path)
		Write-Build Cyan "Task $Path : $(Get-BuildSynopsis $Task)"
	}

	# Synopsis: Show task data useful for headers
	task Task1 {
		$Task.Name
		$Task.InvocationInfo.ScriptName
		$Task.InvocationInfo.ScriptLineNumber
	}
}}
	)
}

### Invoke-BuildExec
@{
	command = 'Invoke-BuildExec'
	synopsis = '(exec) Invokes an application and checks $LastExitCode.'

	description = @'
	Scripts use its alias 'exec'. It invokes the specified script block which
	is supposed to call an executable. Then $LastExitCode is checked. If it
	does not fit to the specified values (0 by default) an error is thrown.

	It is often used with .NET tools, e.g. MSBuild. See Use-BuildAlias.
'@

	parameters = @{
		Command = @'
		Command that invokes an executable which exit code is checked. It must
		invoke an application directly (.exe) or not (.cmd, .bat), otherwise
		$LastExitCode is not set or contains an exit code of another command.
'@
		ExitCode = @{default = '@(0)'; description = @'
		Valid exit codes (e.g. 0..3 for robocopy).
'@}
	}

	outputs = @(
		@{
			type = 'Objects'
			description = @'
		Output of the specified command.
'@
		}
	)

	examples = @(
		@{code={
	# Call robocopy (0..3 are valid exit codes)

	exec { robocopy Source Target /mir } (0..3)
		}}
	)

	links = @(
		@{ text = 'Use-BuildAlias' }
	)
}

### Test-BuildAsset
@{
	command = 'Test-BuildAsset'
	synopsis = '(requires) Checks for required build assets.'

	description = @'
	Scripts use its alias 'requires'. This command tests the required build
	assets. It fails if something is missing or invalid. It is used either
	in script code (common assets) or in tasks (individual assets).
'@

	parameters = @{
		Variable = @'
		Specifies session variable names and tells to fail if a variable is
		missing or its value is null or an empty string.
'@
		Environment = @'
		Specifies environment variable names and tells to fail if a variable is
		not defined or its value is an empty string.
'@
		Property = @'
		Specifies session or environment variable names and tells to fail if a
		variable is missing or its value is null or an empty string. It makes
		sense to use `property` later with tested names without defaults.
'@
	}

	links = @(
		@{ text = 'Get-BuildProperty' }
	)
}

### Use-BuildAlias
@{
	command = 'Use-BuildAlias'
	synopsis = '(use) Sets framework or directory tool aliases.'

	description = @'
	Scripts use its alias 'use'. Invoke-Build does not change the system path
	in order to make framework tools available by names. This is not suitable
	for using mixed framework tools (in different tasks, scripts, parallel
	builds). Instead, this function is used for setting tool aliases in the
	scope where it is called from.

	This function is often called from a build script and all tasks use script
	scope aliases. But it can be called from tasks in order to use more tools
	including other framework or tool directories.
'@

	parameters = @{
		Path = @'
		Specifies the tools directory.

		If it is * or it starts with digits followed by a dot then the MSBuild
		path is resolved using the package script Resolve-MSBuild.ps1. Build
		scripts may invoke it directly by the provided alias Resolve-MSBuild.
		The optional suffix x86 tells to use 32-bit MSBuild.

		If it is like Framework* then it is assumed to be a path relative to
		Microsoft.NET in the Windows directory.

		Otherwise it is a full or relative literal path of any directory.

		Examples: *, 4.0, Framework\v4.0.30319, .\Tools
'@
		Name = @'
		Specifies the tool names. They become aliases in the current scope.
		If it is a build script then the aliases are created for all tasks.
		If it is a task then the aliases are available just for this task.
'@
	}

	examples = @(
		@{code={
	# Use .NET 4.0 tools MSBuild, csc, ngen. Then call MSBuild.

	use 4.0 MSBuild, csc, ngen
	exec { MSBuild Some.csproj /t:Build /p:Configuration=Release }
		}}
	)

	links = @(
		@{ text = 'Invoke-BuildExec' }
		@{ text = 'Resolve-MSBuild' }
	)
}

### Write-Build
@{
	command = 'Write-Build'
	synopsis = 'Writes text using colors if they are supported.'

	description = @'
	This function is used in order to output colored text, e.g. to a console.
	Unlike Write-Host it is suitable for redirected output, e.g. to a file.
	If the current host does not support colors then just text is written.
'@

	parameters = @{
		Color = @'
		[System.ConsoleColor] value or its string representation.
'@
		Text = @'
		Text to be printed using colors if they are supported.
'@
	}

	outputs = @(
		@{
			type = 'String'
		}
	)
}

### Get-BuildFile
@{
	command = 'Get-BuildFile'
	synopsis = 'Gets full path of the default build file.'

	description = @'
	This function is not designed for build scripts and tasks.
	It is used by the engine and exposed for related tools.
'@

	parameters = @{
		Path = @'
		A full directory path used to get the default build file.
'@
	}

	outputs = @{ type = 'String' }
}

### Build-Parallel.ps1
@{
	command = 'Build-Parallel.ps1'
	synopsis = 'Invokes parallel builds by Invoke-Build'

	description = @'
	This script invokes build scripts simultaneously using Invoke-Build.ps1
	which has to be in the same directory. Number of simultaneous builds is
	limited by the number of processors by default.
'@

	parameters = @{
		Build = @'
		Build parameters defined as hashtables with these keys/data:

			Task, File, ... - Invoke-Build.ps1 and script parameters
			Log - Tells to write build output to the specified file

		Any number of builds is allowed, including 0 and 1. The maximum number
		of parallel builds is the number of processors by default. It can be
		changed by the parameter MaximumBuilds.
'@
		Result = @'
		Tells to output build results using a variable. It is either a name of
		variable to be created for results or any object with the property
		Value to be assigned ([ref], [hashtable]).

		Result properties:

			Tasks - tasks (*)
			Errors - errors (*)
			Warnings - warnings (*)
			Started - start time
			Elapsed - build duration

		(*) see: help Invoke-Build -Parameter Result
'@
		Timeout = @'
		Maximum overall build time in milliseconds.
'@
		MaximumBuilds = @{default = 'Number of processors.'; description = @'
		Maximum number of builds invoked at the same time.
'@}
		FailHard = @'
		Tells to abort all builds if any build fails.
'@
	}

	outputs = @{
		type = 'Text'
		description = 'Output of invoked builds and other log messages.'
	}

	examples = @(
		@{
			code = {
	Build-Parallel @(
		@{File='Project1.build.ps1'}
		@{File='Project2.build.ps1'; Task='MakeHelp'}
		@{File='Project2.build.ps1'; Task='Build', 'Test'}
		@{File='Project3.build.ps1'; Log='C:\TEMP\Project3.log'}
		@{File='Project4.build.ps1'; Configuration='Release'}
	)
			}
			remarks = @'
	Five parallel builds are invoked with various combinations of parameters.
	Note that it is fine to invoke the same build script more than once if
	build flows specified by different tasks do not conflict.
'@
		}
	)

	links = @(
		@{ text = 'Invoke-Build' }
	)
}

### Build-Checkpoint.ps1
@{
	command = 'Build-Checkpoint.ps1'
	synopsis = 'Invokes persistent builds with checkpoints.'
	description = @'
	This command invokes the build specified by the hashtable Build so that it
	writes checkpoints to the file specified by Checkpoint. If the build fails
	then it may be resumed later, use the switch Resume in addition to the
	original Checkpoint parameter. The build is resumed at the failed task.

	Not every build may be persistent, right away or at all:

		- Think carefully of what the persistent build state is.
		- Some data are not suitable for persistence in clixml files.
		- Changes in stopped build scripts may cause incorrect resuming.
		- Checkpoint files must not be used with different engine versions.

	CUSTOM EXPORT AND IMPORT

	By default, the command saves and restores build tasks, script path, and
	all parameters declared by the build script, not just specified by Build.
	Tip: consider to declare some script variables as artificial parameters
	in order to make them persistent.

	If this is not enough for saving and restoring the build state then use
	custom export and import blocks. The export block is called on writing
	checkpoints, i.e. on each task. The import block is called on resuming
	once, before the task to be resumed.

	The export block is defined as

		Set-BuildData Checkpoint.Export {
			$script:var1
			$script:var2
		}

	The import block is defined as

		Set-BuildData Checkpoint.Import {
			param($data)
			$var1, $var2 = $data
		}

	Note that the import block is called in the script scope. In the example,
	variables $var1, $var2 are the script variables, you may but do not have
	to use the prefix `$script:`. The parameter $data is the data written by
	Checkpoint.Export, exported to clixml and then imported from clixml.
'@
	parameters = @{
		Checkpoint = @'
		Specifies the checkpoint file (clixml). The checkpoint file is removed
		after successful builds. If a build fails and it is not going to be
		resumed then delete the checkpoint file manually.
'@
		Build = @'
		Specifies the build and script parameters. WhatIf is not supported.
		On Resume tasks, script path, and script parameters are ignored.
'@
		Resume = @'
		Tells to resume the build from the existing checkpoint file.
'@
	}
	outputs = @{
		type = 'Text'
		description = 'Output of the invoked build.'
	}
	examples = @(
		@{code={
	# Invoke a persistent sequence of steps defined as tasks.
	Build-Checkpoint temp.clixml @{Task = '*'; File = 'Steps.build.ps1'}

	# Given the above failed, resume at the failed step.
	Build-Checkpoint temp.clixml -Resume
		}}
	)
	links = @(
		@{ text = 'Invoke-Build' }
	)
}