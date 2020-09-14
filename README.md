#freemapSKtopo
Custom style for mkgmap

generatemap.sh - script to run all steps to generate garmin map from OSM data

you need:
* JAVA - https://www.java.com/en/download/ - to run osmosis, splitter, mkgmap, JMC
* osmosis - http://wiki.openstreetmap.org/wiki/Osmosis
* splitter and mkgmap - http://www.mkgmap.org.uk/download/mkgmap.html 
* wine - http://www.winehg.org - to run NSIS (create Windows installer)
* NSIS - http://nsis.sourceforge.net/Main_Page - to create Windows installer
* JaVaWa MapConverter CLI - http://www.javawa.nl/advanced.html - to create MAC OS X installer* 

## Missing **fixdata/template.areas.list** file.
The map for a given territory is usually too large for Garmin devices, so it is necessary to divide it into smaller parts.
The splitter.jar program is used for this task. In order to repeatedly generate map, that is divided in the same parts, the area.list file is required.

* run java -jar splitter.jar data_file.osm 
* copy areas.list file into fixdata/template.areas.list