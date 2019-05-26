#!/bin/bash


#-- directory path at top
RPATH=$(cd $(dirname $0)/../../;pwd)


#-- read filesystem
. ${RPATH}/config/filesystem.conf

#--- checking command existence
err=0
if [ -x /usr/bin/ogr2ogr ]; then
        : 
else
        result="[ERROR] /usr/bin/ogr2ogr is not found"
        err=1
fi



if [ ${err} -eq 1 ]; then
      echo "Please install and setup all command : ${err}"
      exit 1
else
      :
fi


#--- read options
OPT=`getopt -o " " -l dem: -l t_epsg: -l x: -l y: -- "$@"`
if [ "$?" -ne 0  -o "`echo ${OPT}`" == "--" ]; then
      echo "Usage: $0 "
      echo "      [--dem=<path+fname>] (WGS84-UTM)"
      echo "      [--t_epsg=value] (WGS84-UTM)"
      echo "      [--x=value] (coordinate : WGS84-UTM)"
      echo "      [--y=value] (coordinate : WGS84-UTM)"
      exit
fi

eval set -- "$OPT"

until [ "$1" == "--" ]; do

      case $1 in
            --dem)
                  dem=$2
                  ;;
            --t_epsg)
                  t_epsg=$2
                  ;;
            --x)
                  x=$2
                  ;;
            --y)
                  y=$2
                  ;;
      esac
      shift
done


#-- check input EPSG code (UTM) in config file has WGS84 and UTM coordinate system
xx=0
for i in `seq 1 120`
do      
    num=`cat ${D_CONFIG}/EPSG_code_WGS84UTM.list | awk -F' ' 'NR=='${i}' {print $1}'`
    
    if [ ${t_epsg} -eq ${num} ]; then
        xx=1
    fi
    
done
if [ ${xx} -eq 0 ]; then
      echo
      echo "ERROR : incorrect EPSG code in your input"
      echo " EPSG code = ${t_epsg}"
      echo " It is must be set as WGS84-UTM"
      echo
      exit 99
fi

echo "${x},${y},[x,y@${t_epsg}]"

mx=`gdallocationinfo ${dem} -l_srs EPSG:${t_epsg} ${x} ${y} | grep Location | sed -e 's/Location//g' -e 's/://g' -e 's/(//g' -e 's/)//g' -e 's/P//g' -e 's/L//g' -e 's/^  *//g' -e 's/  */ /g' | awk -F',' '{print $1}'`
my=`gdallocationinfo ${dem} -l_srs EPSG:${t_epsg} ${x} ${y} | grep Location | sed -e 's/Location//g' -e 's/://g' -e 's/(//g' -e 's/)//g' -e 's/P//g' -e 's/L//g' -e 's/^  *//g' -e 's/  */ /g' | awk -F',' '{print $2}'`

echo "${mx},${my},[mx,my@${dem}]"

exit 0


