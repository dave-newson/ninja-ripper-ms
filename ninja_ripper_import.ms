/* 
Ninja Ripper 1.1.2b7a2 3D Max Importer
Importer version 1.3 beta7 alpha2
*/

-- Includes
include "src/service/vars.ms"
include "src/util/debug.ms"
include "src/util/file.ms"
include "src/util/string.ms"
include "src/util/environment.ms"
include "src/service/import.ms"
include "src/ui/main.ms"

-- Reset environment
ui_reset();
util_redrawEnable();
util_fixEnvironment();

-- Display import dialog
createDialog nr_rollout 480 640 50 60