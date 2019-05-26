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
OPT=`getopt -o " " -l t_epsg: -l lon: -l lat: -- "$@"`
if [ "$?" -ne 0  -o "`echo ${OPT}`" == "--" ]; then
      echo "Usage: $0 "
      echo "      [--t_epsg=value] (WGS84-UTM)"
      echo "      [--lon=value] (coordinate : WGS84-LatLon)"
      echo "      [--lat=value] (coordinate : WGS84-LatLon)"
      exit
fi

eval set -- "$OPT"

until [ "$1" == "--" ]; do

      case $1 in
            --t_epsg)
                  t_epsg=$2
                  ;;
            --lon)
                  lon=$2
                  ;;
            --lat)
                  lat=$2
                  ;;
      esac
      shift
done

unset dumdir
trap '[[ "$dumdir" ]] && rm -rf $dumdir' 0 1 2 3 15

dumdir=$(mktemp -d /tmp/`basename $0`_XXXXX)

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



echo "${lon},${lat},[lon,lat@4326]"

echo "xx,yy" > ${dumdir}/point.csv      
echo "${lon},${lat}" >> ${dumdir}/point.csv

# set config file for ogr2ogr
echo "<OGRVRTDataSource>" > ${dumdir}/point.vrt
echo "<OGRVRTLayer name='point'>" >> ${dumdir}/point.vrt
echo "<SrcDataSource>${dumdir}/point.csv</SrcDataSource>" >> ${dumdir}/point.vrt
echo "<GeometryType>wkbPoint</GeometryType>" >> ${dumdir}/point.vrt
echo "<LayerSRS>EPSG:4326</LayerSRS>" >> ${dumdir}/point.vrt
echo "<GeometryField encoding='PointFromColumns' x='xx' y='yy'/>" >> ${dumdir}/point.vrt
echo "</OGRVRTLayer>" >> ${dumdir}/point.vrt
echo "</OGRVRTDataSource>" >>${dumdir}/point.vrt

ogr2ogr -f "CSV" -t_srs EPSG:${t_epsg} -lco GEOMETRY=AS_XY ${dumdir}/point_UTM ${dumdir}/point.vrt -overwrite


px=`cat ${dumdir}/point_UTM/point.csv | awk -F',' 'NR==2 {print $1}'`
py=`cat ${dumdir}/point_UTM/point.csv | awk -F',' 'NR==2 {print $2}'`
      
echo "${px},${py},[x,y@${t_epsg}]"

exit 0


