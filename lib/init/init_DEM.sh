#!/bin/bash

#--- get my process ID
_PID=$$

#-- directory path at top
RPATH=$(cd $(dirname $0)/../../;pwd)


#-- directory path at executing of this script
NPATH=`pwd`


#-- read filesystem
. ${RPATH}/config/filesystem.conf


#--- checking command existence
err=0
if [ -x /usr/bin/jq ]; then
        result="command check : [OK] jq"
else
        result="[ERROR] /usr/bin/jq is not found"
        err=1
fi
echo "  "${result}

if [ -x /usr/bin/gdalinfo ]; then
        result="command check : [OK] gdalinfo"
else
        result="[ERROR] /usr/bin/gdalinfo is not found"
        err=1
fi
echo "  "${result}

if [ -x /usr/bin/gdalsrsinfo ]; then
        result="command check : [OK] gdalsrsinfo"
else
        result="[ERROR] /usr/bin/gdalsrsinfo is not found"
        err=1
fi
echo "  "${result}

if [ -x /usr/bin/gdalwarp ]; then
        result="command check : [OK] gdalwarp"
else
        result="[ERROR] /usr/bin/gdalwarp is not found"
        err=1
fi
echo "  "${result}

if [ -x /usr/bin/gdal_translate ]; then
        result="command check : [OK] gdal_translate"
else
        result="[ERROR] /usr/bin/gdal_translate is not found"
        err=1
fi
echo "  "${result}

if [ -x /usr/bin/gdaldem ]; then
        result="command check : [OK] gdaldem"
else
        result="[ERROR] /usr/bin/gdaldem is not found"
        err=1
fi
echo "  "${result}

if [ -x /usr/bin/gdal_contour ]; then
        result="command check : [OK] gdal_contour"
else
        result="[ERROR] /usr/bin/gdal_contour is not found"
        err=1
fi
echo "  "${result}

if [ -x /usr/bin/gdaladdo ]; then
        result="command check : [OK] gdaladdo"
else
        result="[ERROR] /usr/bin/gdaladdo is not found"
        err=1
fi
echo "  "${result}

if [ -x /usr/bin/ogr2ogr ]; then
        result="command check : [OK] ogr2ogr"
else
        result="[ERROR] /usr/bin/ogr2ogr is not found"
        err=1
fi
echo "  "${result}

if [ -x /usr/bin/convert ]; then
        result="command check : [OK] convert"
else
        result="[ERROR] /usr/bin/convert is not found"
        err=1
fi
echo "  "${result}

if [ ${err} -eq 1 ]; then
      echo "Please install and setup all command : ${err}"
      exit 1
else
      echo " [Success] : Command checking is OK"
fi

#--- read options
OPT=`getopt -o " " -l in: -l field: -l date: -l epsg: -l overwrite: -l cores: -- "$@"`
if [ $? -ne 0 -o "`echo ${OPT}`" == "--"  ]; then
      echo "Usage: $0 "
      echo "      [--field character] (field name e.g. merapi)"
      echo "      [--date character] (date name e.g. 201010)"
      echo "      [--in character] (input DEM file: it must be used as geotiff including EPSG code)"
      echo "      [--epsg value'] (this EPSG code must be set as WGS84-UTM)"
      echo "      [--overwrite <ON>] (option for overwriting)"
      echo "      [--cores value] (option for number of CPU)"
      exit
fi

eval set -- "$OPT"

until [ "$1" == "--" ]; do

      case $1 in
            --in)
                  infile=$2
                  ;;
            --field)
                  field=$2
                  ;;
            --date)
                  datedir=$2
                  ;;
            --epsg)
                  epsg=$2
                  ;;
            --overwrite)
                  overwrite=$2
                  ;;
            --cores)
                  cores=$2
                  ;;
      esac
      shift
done


#--- view input results
echo
echo " input dem file = "${infile}
if [ ! -n "${infile}" ]; then
      echo
      echo "ERROR: cannot find input file"
      echo "quit"
      echo
      exit
fi

if [ ! -n "${field}" ]; then
      echo
      echo "ERROR: input of field name is necessary"
      echo "quit"
      echo
      exit
fi

if [ ! -n "${datedir}" ]; then
    datedir=none
fi


xx=`basename ${infile}`
xx=`echo $xx | awk -F[.] '{print $1}'`
regname=${field}-${datedir}-${xx}


odir=${D_FIELD}/${field}/${datedir}/condition/topography/DEM


echo " name for registration in database = "${regname}
echo " output directory = "${odir}
echo

if [ -e ${odir} -a -z "${overwrite}" ]; then
    echo
    echo "  !!! project name is already exist !!!"
    echo "  project directory: ${odir}"
    echo "  Please set other project name or manually delete exist project directory"
    echo "  EXIT"
    echo
    exit 0
fi

#--- rollback if any error exists
trap '[[ "$dumdir" ]] && rm -rf $dumdir;echo " EXIT"' 0 1 2 3 15
trap '[ -z "$flag" -a $chknum -eq 0 ] && sed -i ${RPATH}/config/filesystem.conf -e '${lnum},${lnum}d' && echo && echo "not edited filesystem.conf (Rollback)"' ERR 1 2 3 15
trap '[ -z "$flag" ] && rm -rf ${odir}/ && echo && echo "not created new project (Rollback)"; exit' ERR 1 2 3 15


if [ -e "${odir}" ]; then
    flag=ON
fi

if [ ! -n "${cores}" ]; then
    cores=1
fi


#--- create project directory
mkdir -p ${odir}





#--- set working directory
unset dumdir
dumdir=$(mktemp -d ${odir}/`basename $0`_XXXX)




#----- GET EPSG code
dummy=dum_epsg_${_PID}.d
echo -n > ${dumdir}/${dummy}

gdalsrsinfo ${infile} | grep "EPSG" | awk 'END {print}' > ${dumdir}/${dummy}

srs_epsg=`cat ${dumdir}/${dummy} | sed -e 's/AUTHORITY//g' -e 's/EPSG//g' -e 's/\"//g' -e 's/\,//g' -e 's/\[//g' -e 's/\]//g' -e 's/ //g'`

#-- check input EPSG code (UTM) in config file has WGS84 and UTM coordinate system
xx=0
for i in `seq 1 120`
do      
    num=`cat ${D_CONFIG}/EPSG_code_WGS84UTM.list | awk -F' ' 'NR=='${i}' {print $1}'`
    
    if [ ${epsg} -eq ${num} ]; then
        xx=1
    fi
    
done
if [ ${xx} -eq 0 ]; then
      echo
      echo "ERROR : incorrect EPSG code in your input"
      echo " EPSG code = ${epsg}"
      echo " It is must be set as WGS84-UTM"
      echo
      exit 99
fi


#--- convert coordinate system to WGS84-UTM
echo " [CONVERT/MOVE geotiff to EPSG:${epsg}]"
if [ ${srs_epsg} -eq ${epsg} ]; then
    echo " SKIP"
    rsync -a ${infile} ${dumdir}/${regname}_${epsg}.tif
else
    gdalwarp -of "GTiff" -s_srs EPSG:${srs_epsg} -t_srs EPSG:${epsg} -r cubic ${infile} ${dumdir}/${regname}_${epsg}.tif  -overwrite
fi

#--- convert coordinate system to WGS84-LatLon
echo " [CONVERT/MOVE geotiff to EPSG:4326]"
if [ ${srs_epsg} -eq 4326 ]; then
    echo " SKIP"
    rsync -a ${infile} ${dumdir}/${regname}_4326.tif
else
    gdalwarp -of "GTiff" -s_srs EPSG:${srs_epsg} -t_srs EPSG:4326 -r cubic ${infile} ${dumdir}/${regname}_4326.tif  -overwrite
fi


#--- get header of the converted file
echo " [GET information of geotiff]"
gdalinfo -mm ${dumdir}/${regname}_${epsg}.tif > ${dumdir}/${regname}_${epsg}.geoinfo
gdalinfo -mm ${dumdir}/${regname}_4326.tif > ${dumdir}/${regname}_4326.geoinfo

#--- get geo information
w=`gdalinfo ${dumdir}/${regname}_4326.tif | grep "Upper Left" | sed 's/(//g;s/)//g;s/Upper//g;s/Left//g;s/\,//g' | awk -F' ' 'NR==1 {print $1}'`
n=`gdalinfo ${dumdir}/${regname}_4326.tif | grep "Upper Left" | sed 's/(//g;s/)//g;s/Upper//g;s/Left//g;s/\,//g' | awk -F' ' 'NR==1 {print $2}'`
e=`gdalinfo ${dumdir}/${regname}_4326.tif | grep "Lower Right" | sed 's/(//g;s/)//g;s/Lower//g;s/Right//g;s/\,//g' | awk -F' ' 'NR==1 {print $1}'`
s=`gdalinfo ${dumdir}/${regname}_4326.tif | grep "Lower Right" | sed 's/(//g;s/)//g;s/Lower//g;s/Right//g;s/\,//g' | awk -F' ' 'NR==1 {print $2}'`
px=`cat ${dumdir}/${regname}_4326.geoinfo | grep "Pixel Size" | sed 's/(//g;s/)//g;s/Pixel//g;s/Size//g;s/ //g;s/=//g'| awk -F',' 'NR==1 {print $1}'`
py=`cat ${dumdir}/${regname}_4326.geoinfo | grep "Pixel Size" | sed 's/(//g;s/)//g;s/Pixel//g;s/Size//g;s/ //g;s/=//g'| awk -F',' 'NR==1 {print $2}'`


#--- make hillshade as geotiff (must be use as WGS84-UTM)
echo " [GET hillshade file as geotiff]"
gdaldem hillshade ${dumdir}/${regname}_${epsg}.tif ${dumdir}/${regname}_hillshade_${epsg}.tif
gdalwarp -of "GTiff" -s_srs EPSG:${epsg} -t_srs EPSG:4326 -tr ${px} ${py} -te ${w} ${s} ${e} ${n} -r cubic ${dumdir}/${regname}_hillshade_${epsg}.tif ${dumdir}/${regname}_hillshade_4326.tif  -overwrite

#--- make slope as geotiff (must be use as WGS84-UTM)
echo " [GET slope file as geotiff]"
gdaldem slope ${dumdir}/${regname}_${epsg}.tif ${dumdir}/${regname}_slope_${epsg}.tif
gdalwarp -of "GTiff" -s_srs EPSG:${epsg} -t_srs EPSG:4326 -tr ${px} ${py} -te ${w} ${s} ${e} ${n} -r cubic ${dumdir}/${regname}_slope_${epsg}.tif ${dumdir}/${regname}_slope_4326.tif  -overwrite


#--- make contour as ESRI shapefile (WGS84-UTM)
echo " [GET contour shapefile in 10m interval]"
gdal_contour -a elev ${dumdir}/${regname}_4326.tif ${dumdir}/${regname}_con10_4326 -i 10 -nln contour10_4326
echo " [GET contour shapefile in 100m interval]"
gdal_contour -a elev ${dumdir}/${regname}_4326.tif ${dumdir}/${regname}_con100_4326 -i 100 -nln contour100_4326
echo " [GET contour shapefile in 1000m interval]"
gdal_contour -a elev ${dumdir}/${regname}_4326.tif ${dumdir}/${regname}_con1000_4326 -i 1000 -nln contour1000_4326

ogr2ogr -f KML ${dumdir}/${regname}_con100_4326/con100.kml ${dumdir}/${regname}_con100_4326/contour100_4326.shp
ogr2ogr -f KML ${dumdir}/${regname}_con1000_4326/con1000.kml ${dumdir}/${regname}_con1000_4326/contour1000_4326.shp

#--- make pseudo red relief and it's kmz (WGS84-LatLon)
rsync -a ${D_API}/init/init_DEM.py ${dumdir}/

npath=`pwd`

cd ${dumdir}
python init_DEM.py ${regname}_4326.tif -dpi 1200 -con 100 -unit "[-]" -vmin 0 -vmax 0 -b ${regname}_4326.tif -hs ${regname}_hillshade_4326.tif -sl ${regname}_slope_4326.tif -o ${odir}


gdal_translate -of "GTiff" -a_ullr ${w} ${n} ${e} ${s} -a_srs EPSG:4326 ${regname}_4326.png dummy_red_relief.tif
gdalwarp -of "GTiff" -tr ${px} ${py} -te ${w} ${s} ${e} ${n} dummy_red_relief.tif ${regname}_relief_4326.tif -overwrite

rsync -a ${regname}_4326.png ${regname}_relief_4326.png

upleft=`gdalinfo ${dumdir}/${regname}_4326.tif | grep "Upper Left" | sed 's/ //g;s/Upper//g;s/Left//g'| awk -F'(' 'NR==1 {print $2}'`
lowright=`gdalinfo ${dumdir}/${regname}_4326.tif | grep "Lower Right" | sed 's/ //g;s/Lower//g;s/Right//g'| awk -F'(' 'NR==1 {print $2}'`
sx=`gdalinfo ${regname}_relief_4326.png | grep "Size is" | sed 's/Size//g;s/is//g;s/ //g'| awk -F',' 'NR==1 {print $1}'`
sy=`gdalinfo ${regname}_relief_4326.png | grep "Size is" | sed 's/Size//g;s/is//g;s/ //g'| awk -F',' 'NR==1 {print $2}'`

echo -n > ${odir}/geoinfo.dat
echo "extent=(${upleft}:(${lowright}" >> ${odir}/geoinfo.dat
echo "projection=4326" >> ${odir}/geoinfo.dat
echo "size=(${sx},${sy})" >> ${odir}/geoinfo.dat

#--- change kml to kmz
zip -rm ${regname}_4326.kmz ${regname}_4326.kml ${regname}_4326.png contour[10m].png contour[100m].png contour[1000m].png


echo "[OK] (WGS84-LatLon)"

#--- make pseudo red relief (WGS84-UTM)
python init_DEM.py ${regname}_${epsg}.tif -dpi 1200 -con 100 -unit "[-]" -vmin 0 -vmax 0 -b ${regname}_${epsg}.tif -hs ${regname}_hillshade_${epsg}.tif -sl ${regname}_slope_${epsg}.tif -o ${odir}

#--- make geotiff (WGS84-UTM) from png
w=`gdalinfo ${regname}_${epsg}.tif | grep "Upper Left" | sed 's/(//g;s/)//g;s/Upper//g;s/Left//g;s/\,//g' | awk -F' ' 'NR==1 {print $1}'`
n=`gdalinfo ${regname}_${epsg}.tif | grep "Upper Left" | sed 's/(//g;s/)//g;s/Upper//g;s/Left//g;s/\,//g' | awk -F' ' 'NR==1 {print $2}'`
e=`gdalinfo ${regname}_${epsg}.tif | grep "Lower Right" | sed 's/(//g;s/)//g;s/Lower//g;s/Right//g;s/\,//g' | awk -F' ' 'NR==1 {print $1}'`
s=`gdalinfo ${regname}_${epsg}.tif | grep "Lower Right" | sed 's/(//g;s/)//g;s/Lower//g;s/Right//g;s/\,//g' | awk -F' ' 'NR==1 {print $2}'`
px=`cat ${regname}_${epsg}.geoinfo | grep "Pixel Size" | sed 's/(//g;s/)//g;s/Pixel//g;s/Size//g;s/ //g;s/=//g'| awk -F',' 'NR==1 {print $1}'`
py=`cat ${regname}_${epsg}.geoinfo | grep "Pixel Size" | sed 's/(//g;s/)//g;s/Pixel//g;s/Size//g;s/ //g;s/=//g'| awk -F',' 'NR==1 {print $2}'`


#--- convert coordinate system to WGS84-UTM (correct)
echo " [CONVERT/MOVE geotiff to EPSG:${epsg}]"
gdalwarp -of "GTiff" -s_srs EPSG:${srs_epsg} -t_srs EPSG:${epsg} -tr ${px} ${py} -r cubic ${infile} ${dumdir}/${regname}_${epsg}.tif  -overwrite


echo "[OK] (WGS84-UTM)"




#--- convert '15m' reslution to investigate river channel & drainage boundary
echo ""
echo " [SET RIVER CHANNEL]"

# threshold for calculating channel
channel_thr=100

xx=`echo $px | awk '{if($1<0) x=-1.0*$1;else x=1.0*$1} {print x}'`
if [ ${xx} -gt 15 ]; then
    dl=${xx}
else
    dl=15
fi

gdalwarp -of "GTiff" -tr ${dl} ${dl} -r cubic ${dumdir}/${regname}_${epsg}.tif ${dumdir}/dummy_dem.tif  -overwrite

#---- convert format geotiff to spetial file for SAGA
dum01=dummy01.sgrd
dum02=dummy02.sgrd

echo "  [STEP 01] converting geotiff to sgrd"
saga_cmd -f=q --cores=${cores} io_gdal 0 -FILES ${dumdir}/dummy_dem.tif -GRIDS ${dumdir}/${dum01}

#---- sink removal
echo "  [STEP 02] sink removal" 
saga_cmd -f=q --cores=${cores} ta_preprocessor 2 -DEM ${dumdir}/${dum01} -DEM_PREPROC ${dumdir}/${dum02}

#---- create geotiff file processed by SAGA
echo "[STEP 03] converting sgrd to geotiff"
saga_cmd -f=q --cores=${cores} io_gdal 2 -GRIDS ${dumdir}/${dum02} -FILE ${dumdir}/${regname}_sinkremoval_${dl}m_${epsg}.tif
      
#----- get river channel
saga3=dummy_area.sgrd
saga4=dummy_channel.sgrd

#--- identifying drainage area
echo "  [STEP 04] identifying drainage area"
saga_cmd -f=q --cores=1 garden_learn_to_program 7 -ELEVATION ${dumdir}/${dum02} -AREA ${dumdir}/${saga3}

#--- identifying river channel
echo "  [STEP 05] identifying river channel"
saga_cmd -f=q --cores=${cores} ta_channels 0 -ELEVATION ${dumdir}/${dum02} -INIT_GRID ${dumdir}/${saga3} -CHNLNTWRK ${dumdir}/${saga4} -SHAPES ${dumdir}/${regname}_channel_${epsg}.shp -MINLEN ${channel_thr}

# make geotiff format of river channel
saga_cmd -f=q --cores=${cores} io_gdal 2 -GRIDS ${dumdir}/${saga4} -FILE ${dumdir}/${regname}_channel_${epsg}.tif

# make shape file on EPSG:4326
ogr2ogr -f "ESRI Shapefile" -s_srs EPSG:${epsg} -t_srs EPSG:4326 ${dumdir}/${regname}_channel_4326.shp ${dumdir}/${regname}_channel_${epsg}.shp

# make kml file on EPSQ:4326
ogr2ogr -f KML -s_srs EPSG:${epsg} -t_srs EPSG:4326 ${dumdir}/${regname}_channel_4326.kml ${dumdir}/${regname}_channel_${epsg}.shp

# convert river channel on EPSG:4326
gdalwarp -of "GTiff" -s_srs EPSG:${epsg} -t_srs EPSG:4326 ${dumdir}/${regname}_channel_${epsg}.tif ${dumdir}/dummy_channel_4326.tif  -overwrite

# get pixel resolution
w=`gdalinfo ${dumdir}/dummy_channel_4326.tif | grep "Upper Left" | sed 's/(//g;s/)//g;s/Upper//g;s/Left//g;s/\,//g' | awk -F' ' 'NR==1 {print $1}'`
n=`gdalinfo ${dumdir}/dummy_channel_4326.tif | grep "Upper Left" | sed 's/(//g;s/)//g;s/Upper//g;s/Left//g;s/\,//g' | awk -F' ' 'NR==1 {print $2}'`
e=`gdalinfo ${dumdir}/dummy_channel_4326.tif | grep "Lower Right" | sed 's/(//g;s/)//g;s/Lower//g;s/Right//g;s/\,//g' | awk -F' ' 'NR==1 {print $1}'`
s=`gdalinfo ${dumdir}/dummy_channel_4326.tif | grep "Lower Right" | sed 's/(//g;s/)//g;s/Lower//g;s/Right//g;s/\,//g' | awk -F' ' 'NR==1 {print $2}'`
px=`gdalinfo ${dumdir}/dummy_channel_4326.tif | grep "Pixel Size" | sed 's/(//g;s/)//g;s/Pixel//g;s/Size//g;s/ //g;s/=//g'| awk -F',' 'NR==1 {print $1}'`
py=`gdalinfo ${dumdir}/dummy_channel_4326.tif | grep "Pixel Size" | sed 's/(//g;s/)//g;s/Pixel//g;s/Size//g;s/ //g;s/=//g'| awk -F',' 'NR==1 {print $2}'`

# coloring channel tif
python ${D_API}/init/channel_geotiff2png.py ${dumdir}/dummy_channel_4326.tif -dpi 1200 -vmin 0 -vmax 100

#-- convert png to RGBA geotiff without background
gdal_translate -of "GTiff" -a_ullr ${w} ${n} ${e} ${s} -a_srs EPSG:4326 ${dumdir}/dummy_channel_4326.png ${dumdir}/dummy_channel_4326.tif
gdalwarp -of "GTiff" -tr ${px} ${py} -te ${w} ${s} ${e} ${n} ${dumdir}/dummy_channel_4326.tif ${dumdir}/${regname}_channel_4326.tif -overwrite

convert -quality 200 -resize ${sx}x${sy} ${dumdir}/dummy_channel_4326.png ${dumdir}/${regname}_channel_4326.png

cd ${NPATH}


#--- move necessary files
rsync -a ${dumdir}/${regname}_4326.kmz ${odir}/ 

rsync -a ${dumdir}/${regname}_4326.geoinfo ${odir}/
rsync -a ${dumdir}/${regname}_relief_4326.tif ${odir}/
rsync -a ${dumdir}/${regname}_relief_4326.png ${odir}/
rsync -a ${dumdir}/${regname}_con10_4326 ${odir}/
rsync -a ${dumdir}/${regname}_con100_4326 ${odir}/
rsync -a ${dumdir}/${regname}_con1000_4326 ${odir}/
rsync -a ${dumdir}/${regname}_${epsg}.geoinfo ${odir}/
rsync -a ${dumdir}/${regname}_4326.tif ${odir}/
rsync -a ${dumdir}/${regname}_${epsg}.tif ${odir}/
rsync -a ${dumdir}/${regname}_channel_4326* ${odir}/
rsync -a ${dumdir}/${regname}_sinkremoval_${dl}m_${epsg}.tif ${odir}/


echo -n > ${odir}/${epsg}.epsg 



#--- export geoinformation as text for WEB-UI
upleft=`gdalinfo ${odir}/${regname}_channel_4326.tif | grep "Upper Left" | sed 's/ //g;s/Upper//g;s/Left//g'| awk -F'(' 'NR==1 {print $2}'`
lowright=`gdalinfo ${odir}/${regname}_channel_4326.tif | grep "Lower Right" | sed 's/ //g;s/Lower//g;s/Right//g'| awk -F'(' 'NR==1 {print $2}'`
sx=`gdalinfo ${odir}/${regname}_channel_4326.png | grep "Size is" | sed 's/Size//g;s/is//g;s/ //g'| awk -F',' 'NR==1 {print $1}'`
sy=`gdalinfo ${odir}/${regname}_channel_4326.png | grep "Size is" | sed 's/Size//g;s/is//g;s/ //g'| awk -F',' 'NR==1 {print $2}'`

echo -n > ${odir}/geoinfo_channel.dat
echo "extent=(${upleft}:(${lowright}" >> ${odir}/geoinfo_channel.dat
echo "projection=4326" >> ${odir}/geoinfo_channel.dat
echo "size=(${sx},${sy})" >> ${odir}/geoinfo_channel.dat


#--- export geoinformation as json for setting condition
lon1=`echo $upleft | awk -F'[,)]' '{print $1}'`
lat1=`echo $upleft | awk -F'[,)]' '{print $2}'`
lon2=`echo $lowright | awk -F'[,)]' '{print $1}'`
lat2=`echo $lowright | awk -F'[,)]' '{print $2}'`
px1=`gdalinfo ${dumdir}/${regname}_4326.tif | grep "Pixel Size" | awk -F'[(,]' '{print $2}'`
px2=`gdalinfo ${dumdir}/${regname}_${epsg}.tif | grep "Pixel Size" | awk -F'[(,]' '{print $2}'`

fpath=${odir}/${regname}_${epsg}.tif

echo
echo "  [set geoinfo.json]"

echo -n > ${dumdir}/geoinfo.json
echo "{" >> ${dumdir}/geoinfo.json
echo "    \"file\":{ \"path\":{\"value\":\"${fpath}\"},\"name\":{\"value\":\"${regname}\"} }," >> ${dumdir}/geoinfo.json
echo "    \"extent\":{ \"lon-NW\":{\"value\":\"${lon1}\",\"unit\":\"degree\"},\"lat-NW\":{\"value\":\"${lat1}\",\"unit\":\"degree\"},\"lon-SE\":{\"value\":\"${lon2}\",\"unit\":\"degree\"},\"lat-SE\":{\"value\":\"${lat2}\",\"unit\":\"degree\"} }," >> ${dumdir}/geoinfo.json
echo "    \"resolution\":{ \"latlon\":{\"value\":\"${px1}\",\"unit\":\"degree\"},\"utm\":{\"value\":\"${px2}\",\"unit\":\"m\"} }" >> ${dumdir}/geoinfo.json
echo "}" >> ${dumdir}/geoinfo.json

cat ${dumdir}/geoinfo.json | jq . > ${odir}/geoinfo.json

echo "  [set geoinfo.json]:done"
echo

#--- add pyramid in DEM to smooth display on WEB-UI
echo "Add pyramid in DEM (it takes time corresponding to mesh number)" 
gdaladdo -r cubic ${odir}/${regname}_relief_4326.tif 2 4 8 16
gdaladdo -r cubic ${odir}/${regname}_relief_4326.png 2 4 8 16 2> /dev/null

gdaladdo -r cubic ${odir}/${regname}_channel_4326.tif 2 4 8 16
gdaladdo -r cubic ${odir}/${regname}_channel_4326.png 2 4 8 16 2> /dev/null



#--- register this project=DEM in config file
echo "Add project"
if [ -e ${RPATH}/config/project.conf ]; then
    chknum=`cat ${RPATH}/config/project.conf | grep "D_${regname}=" | wc -l`

    if [  ${chknum} -eq 0 ]; then
        
        echo "D_${regname}=${odir}" >> ${RPATH}/config/project.conf
        lnum=`grep -n "D_${regname}=${odir}" ${RPATH}/config/project.conf | cut -d ":" -f 1`
    fi  
fi



#--- register layer definition for the WEB-UI
echo -n > ${odir}/layer.dat
echo "DEM=${regname}_relief_4326.png:geoinfo.dat" >> ${odir}/layer.dat
echo "Layer1=${regname}_channel_4326.png:geoinfo_channel.dat" >> ${odir}/layer.dat


#--- set permission
chmod 755 -R ${odir}
mkdir -p ${D_FIELD}/${field}/${datedir}/tmp
chmod 777 ${D_FIELD}/${field}/${datedir}/tmp


#--- register logical DB
echo "registration information to logical Databae"
#--------------------------------------
bash ${D_API}/db/psql_dem.sh --project ${odir}/${regname}
#--------------------------------------

echo "[DONE] registration of DEM & Project"
exit 0

