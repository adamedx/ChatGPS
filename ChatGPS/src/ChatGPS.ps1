#
# Copyright (c), Adam Edwards
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


set-strictmode -version 2
$erroractionpreference = 'stop'

. (join-path $psscriptroot native.ps1)
. (join-path $psscriptroot services.ps1)
. (join-path $psscriptroot intent.ps1)
. (join-path $psscriptroot presentation.ps1)
. (join-path $psscriptroot shell.ps1)
. (join-path $psscriptroot function.ps1)
. (join-path $psscriptroot plugins.ps1)
. (join-path $psscriptroot config.ps1)
. (join-path $psscriptroot codegen.ps1)
. (join-path $psscriptroot commands.ps1)
. (join-path $psscriptroot aliases.ps1)

InitializeModuleSettings

