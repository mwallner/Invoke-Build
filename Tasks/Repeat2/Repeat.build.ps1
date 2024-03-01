<#
.Synopsis
	Example of `repeat` tasks.

.Description
	This script is a demo of the custom repeat-task.
	See "Repeat.tasks.ps1" for the details of `repeat`.

.Example
	Invoke-Build * Repeat.build.ps1

	This command checks all scheduled tasks and invokes some of them as needed.
	It is supposed to be invoked periodically, manually or scheduled. In order
	to reset all times remove the file "Repeat.build.ps1.Repeat.clixml".
#>

# Import repeat-task definitions.
. ./Repeat.tasks.ps1

# Synopsis: Repeat every minute.
task task1 (repeat -Minutes 1 {
	"Doing $($Task.Name)..."
})

# Synopsis: Repeat every hour.
task task2 (repeat -Hours 1 {
	"Doing $($Task.Name)..."
})

# Synopsis: Repeat every day.
task task3 (repeat -Days 1 {
	"Doing $($Task.Name)..."
})
