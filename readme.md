# Ninja Ripper Max Importer

An improved Ninja Ripper importer for 3D Studio Max.

# Installation

 - Clone this repo to a folder (eg. the Max Script folder)
 - Run `ninja_ripper_import.ms` in Max

# Changelist

## 2016.04.25 (1.3 beta7 alpha2) by Dave Newson
 - Multi/sub texture import enabled, removed TexNum
 - Multi UV map support
 - Prevented bad/missing UV maps crashing the import
 - Fixed issues with

## 2013.03.03 (1.3 beta7 alpha1) by CarLuver69
- You can now flip on the XZ axis if your models appear inverted!
- Added progress bar
- Removed a lot of unnecessary information being printed
- End of script will show a popup message with how long it took to import
- "Debug" mode allows you to turn on useless print messages, VERY SLOW.
- Program no longer hangs when importing many objects :D
- Imports are now 50 - 75% faster. I was able to import 2,001 objects in 1 minute and 30 seconds!

## 2013.01.09 (1.3 beta7):
- added uv Scale function
- improved model Scale function

# Future features (todo)

## Predefined profiles

Keep some predefined profiles for rippable games, making importing easier.

## Match by texture name

Max has the capacity to search in files for text. This could be used to loop over a directories work of .rip files and find the ones that use a particular texture.
See http://docs.autodesk.com/3DSMAX/15/ENU/MAXScript-Help/index.html?url=files/GUID-BA196B48-8ECA-4E0C-AE2E-F7EFAAF39844.htm,topicNumber=d30e701493

## Guess mesh name (categorisation)

In some games, the first texture for the .rip file, when in a Normals draw call, is a 1x1 texture.
This makes it easy to identify a .rip which is for Normals and not Diffuse.
Detect these by examining the first texture in the file, if it's a 1x1 then prefix the name with "norm_".

## Position distribution

For each .rip file imported, place it at x+=10 on the grid. 
This would make importing batches of models a lot easier to deal with as they won't sit ontop of eachother.

