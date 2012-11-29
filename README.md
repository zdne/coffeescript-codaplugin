# CoffeeScript Plug-in for Coda
by Zdeněk Němec

# Overview
CoffeeScript Plug-in for Coda offers a convenient way to build and run CoffeeScript directly from within Coda 2. It offers 'Compile to Javascript' (⇧⌘M) and 'Run' (⇧⌘U) commands as well as automatic on-save syntax check.

![Compile](http://zdne.org/codaplugin/img/compile_success.png)
![Run](http://zdne.org/codaplugin/img/run.png)
![Error](http://zdne.org/codaplugin/img/compile_error.png)
![Settings](http://zdne.org/codaplugin/img/settings.png)

# Requirements
* The plug-in requires Coda 2
* CoffeeScript
* Tested on 10.8.2 

# Build & Install
Open the project using Xcode 4.5. Set target to release and build. Run script build phase should copy the plug-in into appropriate directory - `${USER_LIBRARY_DIR}/Application Support/Coda 2/Plug-ins/`.

# Version History
## v1.0 - Initial Release
* Binary available in [Downloads](https://github.com/zdne/coffeescript-codaplugin/downloads).
* Settings fully functional, use it to set shell variables (PATH, NODE_PATH, etc.), current working directory and whether the plug-in should check syntax on save. 

## v0.91 - Settings 
* Added settings datamodel and its serialization
* Added (dummy for now) settings UI
* Added support for working directory
* Improved stability and user interaction, plug-in now informs user when there is no coffee command available.

## v0.9 - Initial Revision
* Compile
* Run
* On-save Syntax Check

# License

Copyright ©2012, Zdenek Nemec (http://zdne.org)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

# Acknowledgement

This work uses parts of the Kelan Champagne's YRKSpinningProgressIndicator (https://github.com/kelan/yrk-spinning-progress-indicator).
