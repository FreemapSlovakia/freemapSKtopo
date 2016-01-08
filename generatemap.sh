#!/bin/bash
#	== freemapSKtopo ==

wgetfile=""   # path to pdf file, example: http://download.geofabrik.de/europe/slovakia-latest.osm.pbf 
NSISpath=""   # path to NSIS program (to run install wine!), example: /home/jankohrasko/.wine/drive_c/Program files/NSIS/
splitterpath=""   # path to splitter, example: /home/jankohrasko/OSM/splitter-r202/
mkgmappath=""   # path to mkgmap, example: /home/jankohrasko/OSM/mkgmap-r2383/
osmosispath=""   # apth to osmosis, example: /home/jankohrasko/OSM/osmosis-0.41/bin/
jmcpath=""   # path to jmc (map for MAC OS X)
scpPort=""                    # port na server pre poslanie suborov
scpServer=""                    # user@server
scpPath=""                      # cesta kam sa na server ulozit data, napr. /home/jankohrasko

outdir="out"   # output dir, relative or absolute to sript path

down=0        # download new file 
merge=0       # merge contours and data 
split=0       # split
gen=0         # generate map (UTF))
exe=0         # create Windows installer (UTF)
gmap=0        # create MAC OSX installer (UTF)
zip=0         # pack gmapsupp.img (UTF)
upload=0      # upload files (not working)
genlatin=0    # generate map (latin) 
exelatin=0    # create Windows installer (latin))
gmaplatin=0   # create MAC OSX installer (latin)
ziplatin=0    # pack gmapsupp.img (latin)
clean=0       # delete temp/work files

checkdate=0

function PrintUsage {
    echo "Skript vynegeneruje garmin mapu (exe instalator a zip gmapsupp.img) z OSM podkladov.
POZOR! Skript ocakava ze bude mat k dispozicii v priecinku pripravene vrstevnice programom phyghtmap (http://wiki.osm.org/wiki/Phyghtmap) a tiez args subor pre mkgmap.
"
    echo "parametre:      -down           - stahnutie .osm.pbf suboru
                -merge          - spajanie s vrstevnicami
                -split          - rozdelenie na viac casti
                -gen            - vygenerovanie mapy mkgmap-om kodovanie unicode
                -exe            - vytvorenie exe instalatora
                -gmap           - vytvorenie gmap pre OS X
                -zip            - vytvorenie zip suboru s gmapsupp.img
                -upload         - uploadne subor na server
                -genlatin       - vygenerovanie mapy mkgmap-om kodovanie latin
                -exelatin       - vytvorenie exe instalatora
                -gmaplatin      - vytvorenie gmap pre OS X
                -ziplatin       - vytvorenie zip suboru s gmapsupp.img

                -utf            - skratka pre nasledovne parametre: gen, exe, gmap, zip 
                -latin          - skratka pre nasledovne parametre: genlatin, exelatin, gmaplatin.ziplatin
                -complete       - spusti vsetky akcie okrem upload "
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
  echo -e "\e[01;32mstiahnutie noveho mapoveho suboru...\e[00m"
  wget $wgetfile -O inputdata/inputfile.osm.pbf
else
  echo -e "\e[00;32mvynechavam stahovanie...\e[00m"
fi

if [ $processdata == 1 ]; then

# merge countours with OSM data
  if [ $merge == 1 ]; then
    echo -e "\e[01;32mpridanie vrstevnic k mape...\e[00m"
    rm inputdata/merged.osm.pbf
    ${osmosispath}osmosis --read-pbf file=inputdata/inputfile.osm.pbf --read-pbf file=inputdata/10m-100-50_SRTM1_SK.osm.pbf --merge --bp file=fixdata/slovakia2.poly --write-pbf file=inputdata/merged.osm.pbf omitmetadata=yes
  else
    echo -e "\e[00;32mvynechavam spajanie s vrstevnicami...\e[00m"
  fi

# split large input file to small files
  if [ $split == 1 ]; then
    echo -e "\e[01;32mrozdelenie mapy na mensie casti...\e[00m"
    java -jar "${splitterpath}"splitter.jar inputdata/merged.osm.pbf --split-file=fixdata/template.areas.list --description=freemapSKtopo --output-dir=out/
  else
    echo -e "\e[00;32mvynechavam rozdelenie...\e[00m"
  fi

# create sk.args
cat fixdata/template.sk.args >out/sk.args
cat out/template.args >>out/sk.args
# copy hiking style to freemapSKtopo (old map has hiking and cycle style, now only hiking style)
cp fm_hiking.typ fmsktopo.typ
cp fm_hiking.typ out/fmsktopo.typ

# generate map 
if [ $gen == 1 ]; then
  rm out/utf/*
  rm out/utf/gmapsupp/*
  echo -e "\e[01;32mgenerovanie mapy...\e[00m"
  java -Xmx3000M -jar "${mkgmappath}"mkgmap.jar --max-jobs=2 --keep-going --code-page=65001  --output-dir=out/utf/ -c out/sk.args
  mv out/utf/gmapsupp.img out/utf/gmapsupp/gmapsupp.img
else
  echo -e "\e[00;32mvynechavam generovanie mapy...\e[00m"
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
  echo -e "\e[01;32mvytvorenie .exe instalatora...\e[00m"
  cp fmsktopo.typ out/utf/
  cp out/license.txt out/utf/
  cp out/informacia.txt out/utf/
  cp fixdata/template.freemapSKtopo.nsi out/utf/
  cp fixdata/changelog.txt out/utf/
  cd out/utf/

  wine "${NSISpath}"makensis.exe template.freemapSKtopo.nsi
  if [ ! $? == 0 ]; then
    echo -e "\e[01;31mCHYBA pri vytvarani instalatora!\e[00m"
    exit
  fi
  cd ../..
  cp out/utf/freemapSKtopo.exe out/upload/
else
  echo -e "\e[00;32mvynechavam vytvorenie instalatora...\e[00m"
fi

# create MAC OS X installer
if [ $gmap == 1 ]; then
  echo -e "\e[01;32mvytvorenie gmap...\e[00m"
  rm out/upload/freemapSKtopo.gmapi.zip
  rm -r out/utf/freemapSKtopo.gmapi/freemapSKtopo.gmap/*
  ${jmcpath}jmc_cli -src=out/utf/ -dest=out/utf/freemapSKtopo.gmapi -bmap=fmsktopo.img -gmap="freemapSKtopo.gmap" 
  cd out/utf/
  zip -9 -r ../upload/freemapSKtopo.gmapi.zip freemapSKtopo.gmapi/*
  cd ../..
else
  echo -e "\e[00;32mvynechavam vytvorenie gmap...\e[00m"
fi

# pack gmapsupp.img with info.txt and change.log
if [ $zip == 1 ]; then
  echo -e "\e[01;32mvytvorenie zip s gmapsupp.img...\e[00m"
  rm out/upload/freemapSKtopo.gmapsupp.zip
  zip -9 -j out/upload/freemapSKtopo.gmapsupp.zip out/utf/gmapsupp/gmapsupp.img fixdata/info.txt fixdata/changelog.txt
else
  echo -e "\e[00;32mvynechavam vytvorenie zip...\e[00m"
fi

if [ $genlatin == 1 ]; then
  rm out/latin1/*
  rm out/latin1/gmapsupp/*
  echo -e "\e[01;32mgenerovanie mapy...\e[00m"
  java -Xmx3000M -jar "${mkgmappath}"mkgmap.jar --max-jobs=6 --keep-going --code-page=latin1  --output-dir=out/latin1/ -c out/sk.args
  mv out/latin1/gmapsupp.img out/latin1/gmapsupp/gmapsupp.img
else
  echo -e "\e[00;32mvynechavam generovanie mapy...\e[00m"
fi


if [ $exelatin == 1 ]; then
  echo -e "\e[01;32mvytvorenie .exe instalatora...\e[00m"
  cp fmsktopo.typ out/latin1/
  cp out/license.txt out/latin1/
  cp out/informacia.txt out/latin1/
  cp fixdata/template.freemapSKtopo.nsi out/latin1/
  cp fixdata/changelog.txt out/latin1/
  cd out/latin1/
  wine "${NSISpath}"makensis.exe template.freemapSKtopo.nsi
  if [ ! $? == 0 ]; then
    echo -e "\e[01;31mCHYBA pri vytvarani instalatora!\e[00m"
    exit
  fi
  cd ../..
  cp out/latin1/freemapSKtopo.exe out/upload/freemapSKtopo.latin1.exe
else
  echo -e "\e[00;32mvynechavam vytvorenie instalatora...\e[00m"
fi

if [ $gmaplatin == 1 ]; then
  echo -e "\e[01;32mvytvorenie gmap...\e[00m"
  rm out/upload/freemapSKtopo.gmapi.latin1.zip
  rm -r out/latin1/freemapSKtopo.gmapi/freemapSKtopo.gmap/*
  ${jmcpath}jmc_cli -src=out/latin1/ -dest=out/latin1/freemapSKtopo.gmapi -bmap=fmsktopo.img -gmap="freemapSKtopo.gmap"
  cd out/latin1/
  zip -9 -r ../upload/freemapSKtopo.gmapi.latin1.zip freemapSKtopo.gmapi/*
  cd ../..
else
  echo -e "\e[00;32mvynechavam vytvorenie gmap...\e[00m"
fi

if [ $ziplatin == 1 ]; then
  echo -e "\e[01;32mvytvorenie zip s gmapsupp.img...\e[00m"
  rm out/upload/freemapSKtopo.gmapsupp.latin1.zip
  zip -9 -j out/upload/freemapSKtopo.gmapsupp.latin1.zip out/latin1/gmapsupp/gmapsupp.img fixdata/info_latin1.txt fixdata/changelog.txt
else
  echo -e "\e[00;32mvynechavam vytvorenie zip...\e[00m"
fi


# upload file to server 
if [ $upload == 1 ]; then
  echo -e "\e[01;32mupload suboru...\e[00m"
# funguje ale treba pisat heslo
#scp -P"${scpPort}" freemapSKtopo.exe freemapSKtopo.gmapsupp.zip freemapSKtopo.gmapi.zip "${scpServer}":"${scpPath}"

#spawn scp -P"${scpPort}" freemapSKtopo.exe freemapSKtopo.gmapsupp.zip "${scpServer}":"${scpPath}"
#
#expect{
#-re ".*es.*o.*:" {
#exp_send "yes\r"
#exp_continue
#}
#-re ".*sword.*" {
#exp_send ""
#}
#}
#interact
else
  echo -e "\e[00;32mneuploadujem subor...\e[00m"
fi

# clean temp/work files 
if [ $clean == 1 ]; then
  echo -e "\e[01;32mcistenie nepotrebnych suborov...\e[00m"
  rm /home/myth/OSM/garmin/out/latin1/*.*
  rm /home/myth/OSM/garmin/out/latin1/gmapsupp/*.*
  rm /home/myth/OSM/garmin/out/utf/*.*
  rm /home/myth/OSM/garmin/out/utf/gmapsupp/*.*
  rm /home/myth/OSM/garmin/out/*.*
fi


fi 
