#
# Copyright (c) Adam Edwards
#
# All rights reserved.

. "$psscriptroot/presentation/format.ps1"

$commandFiles = Get-ChildItem $psscriptroot/commands -Filter *.ps1 |
  where Name -notlike '.#*' |
  where Name -notlike '*.tests.ps1'

foreach ( $commandFile in $commandFiles ) {
   . $commandFile.FullName
}
