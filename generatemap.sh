#!/bin/bash


wgetfile=""   # path to pdf file, example: http://download.geofabrik.de/europe/slovakia-latest.osm.pbf 
NSISpath=""   # path to NSIS program (to run install wine!), example: /home/jankohrasko/.wine/drive_c/Program files/NSIS/
splitterpath=""   # path to splitter, example: /home/jankohrasko/OSM/splitter-r202/
mkgmappath=""   # path to mkgmap, example: /home/jankohrasko/OSM/mkgmap-r2383/
osmosispath=""   # apth to osmosis, example: /home/jankohrasko/OSM/osmosis-0.41/bin/
jmcpath=""   # path to jmc (map for MAC OS X)

outdir="out"   # output dir, relative or absolute to sript path

down=0        # download new file 
merge=0       # merge contours and data 
split=0       # split
gen=0         # generate map (UTF))
exe=0         # create Windows installer (UTF)
gmap=0        # create MAC OSX installer (UTF)
zip=0         # pack gmapsupp.img (UTF)
genlatin=0    # generate map (latin) 
exelatin=0    # create Windows installer (latin))
gmaplatin=0   # create MAC OSX installer (latin)
ziplatin=0    # pack gmapsupp.img (latin)
clean=0       # delete temp/work files

checkdate=0

function PrintUsage {
    echo "Generate garmin map (.exe installer and zip with gmapsupp.img) from OSM data.
WARNING! Script expect contours (look phyghtmap - http://wiki.osm.org/wiki/Phyghtmap) and args file for mkgmap.
"
    echo "parameters:     -down           - download input .osm.pbf
                -merge          - merge sata with contours
                -split          - split map data to smaller chunks
                -gen            - create garmin map (UTF)
                -exe            - create .exe installer (UTF)
                -gmap           - create gmap for OS X (UTF)
                -zip            - create .zip with gmapsupp.img )UTF)
                -genlatin       - create garmin map (latin)
                -exelatin       - create .exe intaller (latin)
                -gmaplatin      - create gmap for OS X (latin)
                -ziplatin       - create zip with gmapsupp.img (latin)

                -utf            - shortcut for: gen, exe, gmap, zip 
                -latin          - shortcut for: genlatin, exelatin, gmaplatin.ziplatin
                -complete       - run all "
    exit
}

if [ $# == 0 ];  then
  PrintUsage
fi

for ARG in $*
do
  if [ "$ARG" == "-h" ] || [ "$ARG" == "-help" ] || [ "$ARG" == "/h" ] || [ "$ARG" == "/help" ]; then PrintUsage; fi
  if [ "$ARG" == "-down" ]; then down=1; fi
  if [ "$ARG" == "-merge" ]; then merge=1; fi
  if [ "$ARG" == "-split" ]; then split=1; fi
  if [ "$ARG" == "-gen" ]; then gen=1; fi
  if [ "$ARG" == "-exe" ]; then exe=1; fi
  if [ "$ARG" == "-gmap" ]; then gmap=1; fi
  if [ "$ARG" == "-zip" ]; then zip=1; fi
  if [ "$ARG" == "-upload" ]; then upload=1; fi
  if [ "$ARG" == "-utf" ]; then gen=1; exe=1; gmap=1; zip=1; fi
  if [ "$ARG" == "-genlatin" ]; then genlatin=1; fi
  if [ "$ARG" == "-exelatin" ]; then exelatin=1; fi
  if [ "$ARG" == "-ziplatin" ]; then ziplatin=1; fi
  if [ "$ARG" == "-gmaplatin" ]; then gmaplatin=1; fi
  if [ "$ARG" == "-latin" ]; then genlatin=1; exelatin=1; gmaplatin=1; ziplatin=1; fi
  if [ "$ARG" == "-complete" ]; then down=1;merge=1;split=1;gen=1;exe=1;gmap=1;zip=1; fi
  if [ "$ARG" == "-clean" ]; then clean=1; fi
done

processdata=1;

# downlod new pbf file
if [ $down == 1 ]; then
  echo -e "\e[01;32mDownload map data...\e[00m"
  wget $wgetfile -O inputdata/inputfile.osm.pbf
else
  echo -e "\e[00;32mSkipping download...\e[00m"
fi

if [ $processdata == 1 ]; then

# merge countours with OSM data
  if [ $merge == 1 ]; then
    echo -e "\e[01;32mMerging map data with countours...\e[00m"
    rm inputdata/merged.osm.pbf
    ${osmosispath}osmosis --read-pbf file=inputdata/inputfile.osm.pbf --read-pbf file=inputdata/10m-100-50_SRTM1_SK.osm.pbf --merge --bp file=fixdata/slovakia2.poly --write-pbf file=inputdata/merged.osm.pbf omitmetadata=yes
  else
    echo -e "\e[00;32mSkippng map data merging with contours ...\e[00m"
  fi

# split large input file to small files
  if [ $split == 1 ]; then
    echo -e "\e[01;32mSplit map...\e[00m"
    java -jar "${splitterpath}"splitter.jar inputdata/merged.osm.pbf --split-file=fixdata/template.areas.list --description=freemapSKtopo --output-dir=out/
  else
    echo -e "\e[00;32mSkipping map split...\e[00m"
  fi

# create sk.args
cat fixdata/template.sk.args >out/sk.args
cat out/template.args >>out/sk.args
cp fm_hiking.typ fmsktopo.typ
cp fm_hiking.typ out/fmsktopo.typ

# generate map 
if [ $gen == 1 ]; then
  rm out/utf/*
  rm out/utf/gmapsupp/*
  echo -e "\e[01;32mCreating garmin map ...\e[00m"
  java -Xmx3000M -jar "${mkgmappath}"mkgmap.jar --max-jobs=2 --keep-going --code-page=65001  --output-dir=out/utf/ -c out/sk.args
  mv out/utf/gmapsupp.img out/utf/gmapsupp/gmapsupp.img
else
  echo -e "\e[00;32mSkipping garmin map...\e[00m"
fi

# create licence file with date
cat fixdata/template.license1.txt >out/license.txt
date +"%d.%m.%Y" >>out/license.txt
cat fixdata/template.license2.txt >>out/license.txt

# create info file 
cat fixdata/template.informacia1.txt >out/informacia.txt
date +"%d.%m.%Y" >>out/informacia.txt                      
cat fixdata/template.informacia2.txt >>out/informacia.txt

# create Windows installer
if [ $exe == 1 ]; then
  echo -e "\e[01;32mCreating .exe installer...\e[00m"
  cp fmsktopo.typ out/utf/
  cp out/license.txt out/utf/
  cp out/informacia.txt out/utf/
  cp fixdata/template.freemapSKtopo.nsi out/utf/
  cp fixdata/changelog.txt out/utf/
  cd out/utf/

  wine "${NSISpath}"makensis.exe template.freemapSKtopo.nsi
  if [ ! $? == 0 ]; then
    echo -e "\e[01;31mERROR!\e[00m"
    exit
  fi
  cd ../..
  cp out/utf/freemapSKtopo.exe out/upload/
else
  echo -e "\e[00;32mSkipping .exe instraller...\e[00m"
fi

# create MAC OS X installer
if [ $gmap == 1 ]; then
  echo -e "\e[01;32mCreating gmap...\e[00m"
  rm out/upload/freemapSKtopo.gmapi.zip
  rm -r out/utf/freemapSKtopo.gmapi/freemapSKtopo.gmap/*
  ${jmcpath}jmc_cli -src=out/utf/ -dest=out/utf/freemapSKtopo.gmapi -bmap=fmsktopo.img -gmap="freemapSKtopo.gmap" 
  cd out/utf/
  zip -9 -r ../upload/freemapSKtopo.gmapi.zip freemapSKtopo.gmapi/*
  cd ../..
else
  echo -e "\e[00;32mSkipping gmap...\e[00m"
fi

# pack gmapsupp.img with info.txt and change.log
if [ $zip == 1 ]; then
  echo -e "\e[01;32mCreating zip with gmapsupp.img...\e[00m"
  rm out/upload/freemapSKtopo.gmapsupp.zip
  zip -9 -j out/upload/freemapSKtopo.gmapsupp.zip out/utf/gmapsupp/gmapsupp.img fixdata/info.txt fixdata/changelog.txt
else
  echo -e "\e[00;32mSkipping zip with gmapsupp.img...\e[00m"
fi

if [ $genlatin == 1 ]; then
  rm out/latin1/*
  rm out/latin1/gmapsupp/*
  echo -e "\e[01;32mCreating garmin map...\e[00m"
  java -Xmx3000M -jar "${mkgmappath}"mkgmap.jar --max-jobs=6 --keep-going --code-page=latin1  --output-dir=out/latin1/ -c out/sk.args
  mv out/latin1/gmapsupp.img out/latin1/gmapsupp/gmapsupp.img
else
  echo -e "\e[00;32mSkipping garmin map...\e[00m"
fi


if [ $exelatin == 1 ]; then
  echo -e "\e[01;32mCreating .exe installer...\e[00m"
  cp fmsktopo.typ out/latin1/
  cp out/license.txt out/latin1/
  cp out/informacia.txt out/latin1/
  cp fixdata/template.freemapSKtopo.nsi out/latin1/
  cp fixdata/changelog.txt out/latin1/
  cd out/latin1/
  wine "${NSISpath}"makensis.exe template.freemapSKtopo.nsi
  if [ ! $? == 0 ]; then
    echo -e "\e[01;31mERROR!\e[00m"
    exit
  fi
  cd ../..
  cp out/latin1/freemapSKtopo.exe out/upload/freemapSKtopo.latin1.exe
else
  echo -e "\e[00;32mSkipping .exe installer ...\e[00m"
fi

if [ $gmaplatin == 1 ]; then
  echo -e "\e[01;32mCreating gmap...\e[00m"
  rm out/upload/freemapSKtopo.gmapi.latin1.zip
  rm -r out/latin1/freemapSKtopo.gmapi/freemapSKtopo.gmap/*
  ${jmcpath}jmc_cli -src=out/latin1/ -dest=out/latin1/freemapSKtopo.gmapi -bmap=fmsktopo.img -gmap="freemapSKtopo.gmap"
  cd out/latin1/
  zip -9 -r ../upload/freemapSKtopo.gmapi.latin1.zip freemapSKtopo.gmapi/*
  cd ../..
else
  echo -e "\e[00;32mSkipping gmap...\e[00m"
fi

if [ $ziplatin == 1 ]; then
  echo -e "\e[01;32mCreating zip with gmapsupp.img...\e[00m"
  rm out/upload/freemapSKtopo.gmapsupp.latin1.zip
  zip -9 -j out/upload/freemapSKtopo.gmapsupp.latin1.zip out/latin1/gmapsupp/gmapsupp.img fixdata/info_latin1.txt fixdata/changelog.txt
else
  echo -e "\e[00;32mSkipping zip...\e[00m"
fi


# clean temp/work files 
if [ $clean == 1 ]; then
  echo -e "\e[01;32mclean temp files...\e[00m"
  rm /home/myth/OSM/garmin/out/latin1/*.*
  rm /home/myth/OSM/garmin/out/latin1/gmapsupp/*.*
  rm /home/myth/OSM/garmin/out/utf/*.*
  rm /home/myth/OSM/garmin/out/utf/gmapsupp/*.*
  rm /home/myth/OSM/garmin/out/*.*
fi


fi 
