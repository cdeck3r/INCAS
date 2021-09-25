# Script-Server UI

[Script-Server](https://github.com/bugy/script-server) is a Web UI for running shell  scripts. It comes with an execution management.

The script-server UI implements various scripts implementing the main services the user interacts with.

* Status check
* Take a snapshot

## Status check

Performs various checks and determines the system status. Checks include

* Required tool check
* Existence of important scripts and test whether they are executable
* Checks for running [snapshots jobs](periodic-snapshots)
* Test for log directory and list all logfiles
* Various tests in the context of image storage
   * test for _www-image_ directory
   * check filesize for each image to detect problems when taking image
   * _www-image_ directories's storage consumption

## Take a snapshot

Basically, this is a UI to the [snapshot.sh](../takeimg) script.

## Periodic Snapshots

The script-server UI implememts snapshots in periodic intervals. It combines [`at`]() and [`watch`]() with the UI.

* `at` submits a script / comand as job to the system
* `watch` repeatably runs a script every x seconds

**Note:** The script submits periodic snapshot jobs into the _s_ queue by `at -q s ...`.

The next figure displays the design. 

![Design to run periodic snapshots]()

We expect periodic snapshots to run for hours. So, the design decouples long-running jobs from script-server. Still, one can query the status and easily kill a periodic snapshot job using `atq` and `atrm` commands. 


