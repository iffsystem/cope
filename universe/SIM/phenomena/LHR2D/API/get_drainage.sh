#!/bin/bash


#-- directory path at top
RPATH=$(cd $(dirname $0)/../../../../../;pwd)


#-- read filesystem
. ${RPATH}/config/filesystem.conf



#--- read options
OPT=`getopt -o " " -l dempath: -l odir: -l lat: -l lon: -- "$@"`
if [ "$?" -ne 0  -o "`echo ${OPT}`" == "--" ]; then
      echo "Usage: $0 "
      echo "      [--dempath=character] (path of dem file)"
      echo "      [--odir=character] (directory path for output)"
      echo "      [--lat=value] (coordinate of inflow point as latitude on EPSG:4326)"
      echo "      [--lon=value] (coordinate of inflow point as longitude on EPSG:4326)"
      exit
fi

eval set -- "$OPT"

until [ "$1" == "--" ]; do

      case $1 in
            --dempath)
                  dempath=$2
                  ;;
            --odir)
                  odir=$2
                  ;;
            --lat)
                  lat=$2
                  ;;
            --lon)
                  lon=$2
                  ;;
      esac
      shift
done


mkdir -p ${odir}


trap '[[ "$dummy" ]] && rm -rf $dummy && echo "-1";exit' ERR 1 2 3 15

dummy=$(mktemp -d ${odir}/`basename $0`_XXXXX)

#--- clean tmp
rm -f ${odir}/drainage_*

debug=${odir}/drainage_DEBUG
echo -n > ${debug}

if [ ! -e "${dempath}" ]; then
    echo
    echo " ERROR: cannot find dem pth : ${dempath}"
    echo " please check file existence"
    echo " quit"
    echo
    echo "no dem" > ${debug}
    echo "dem: $dem" >> ${debug}
    echo "project: $project" >> ${debug}    
    
    ls /forcibly/quit/this/script
fi

resol=`gdalinfo ${dempath} | grep "Pixel Size" | sed 's/(//g;s/)//g;s/Pixel//g;s/Size//g;s/ //g;s/=//g'| awk -F',' 'NR==1 {print $1}'`

function Conv_lonlat2xy(){
    
    local lat=$1
    local lon=$2
    
    echo "xx,yy" > ${dummy}/point.csv
    echo "${lon},${lat}" >> ${dummy}/point.csv
    
    echo "<OGRVRTDataSource>" > ${dummy}/point.vrt
    echo "<OGRVRTLayer name='point'>" >> ${dummy}/point.vrt
    echo "<SrcDataSource>${dummy}/point.csv</SrcDataSource>" >> ${dummy}/point.vrt
    echo "<GeometryType>wkbPoint</GeometryType>" >> ${dummy}/point.vrt
    echo "<LayerSRS>EPSG:4326</LayerSRS>" >> ${dummy}/point.vrt
    echo "<GeometryField encoding='PointFromColumns' x='xx' y='yy'/>" >> ${dummy}/point.vrt
    echo "</OGRVRTLayer>" >> ${dummy}/point.vrt
    echo "</OGRVRTDataSource>" >> ${dummy}/point.vrt


    ogr2ogr -f "CSV" -t_srs EPSG:${epsg} -lco GEOMETRY=AS_XY ${dummy}/point_UTM ${dummy}/point.vrt -overwrite
          
    rm -f ${dummy}/point.vrt
    rm -f ${dummy}/point.csv

    mv -f ${dummy}/point_UTM/point.csv ${dummy}/
    rm -rf ${dummy}/point_UTM

    #--- set gloval variables
    x=`cat ${dummy}/point.csv | awk -F',' 'NR==2 {print $1}' `
    y=`cat ${dummy}/point.csv | awk -F',' 'NR==2 {print $2}' `

    rm -f ${dummy}/point.csv
    
}


gdalsrsinfo ${dempath} | grep "EPSG" | awk 'END {print}' > ${dummy}/srsinfo

epsg=`cat ${dummy}/srsinfo | sed -e 's/AUTHORITY//g' -e 's/EPSG//g' -e 's/\"//g' -e 's/\,//g' -e 's/\[//g' -e 's/\]//g' -e 's/ //g'`


#--- convert lon,lat to x,y
Conv_lonlat2xy ${lat} ${lon} &>> ${debug}

saga_cmd -f=q --cores=1 io_gdal 0 -FILES ${dempath} -GRIDS ${dummy}/dum01.sgrd &>> ${debug}

#---- sink removal
saga_cmd -f=q --cores=1 ta_preprocessor 2 -DEM ${dummy}/dum01.sgrd -DEM_PREPROC ${dummy}/dum02.sgrd &>> ${debug}

#---- create geotiff file processed by SAGA
saga_cmd -f=q --cores=1 io_gdal 2 -GRIDS ${dummy}/dum02.sgrd -FILE ${dummy}/sinkremoval_${epsg}.tif &>> ${debug}
      
      
#-- get drainage area [(recommend) method=0, convergence=0.001]
saga_cmd -f=q --cores=1 ta_hydrology 4 -TARGET_PT_X ${x} -TARGET_PT_Y ${y} -ELEVATION ${dummy}/sinkremoval_${epsg}.tif -AREA ${dummy}/area.sgrd -METHOD 0 -CONVERGE 0.001 &>> ${debug}
 
#-- convert sgrd to geotiff
saga_cmd -f=q --cores=1 io_gdal 2 -GRIDS ${dummy}/area.sgrd -FILE ${dummy}/dummy_drainage1234.tif   &>> ${debug}
 
#-- set null in the converted geotiff
gdal_translate -of GTiff -a_nodata 0.0 ${dummy}/dummy_drainage1234.tif ${dummy}/drainage.tif    &>> ${debug}


cd ${dummy}

#--- get drainage area & coloring drainage tif
python ${D_ENGINE}/LHR2D/API/drainage_geotiff2png.py ${dummy}/drainage.tif -dpi 600 -vmin 0 -vmax 100 &>> ${debug}



area=`cat data.txt | awk -F' ' 'NR==5{print $1}'`   # km2

rsync -a drainage.png ${odir}/ &>> ${debug}

upleft=`gdalinfo ${dempath} | grep "Upper Left" | sed 's/ //g;s/Upper//g;s/Left//g'| awk -F'(' 'NR==1 {print $2}'`
lowright=`gdalinfo ${dempath} | grep "Lower Right" | sed 's/ //g;s/Lower//g;s/Right//g'| awk -F'(' 'NR==1 {print $2}'`
sx=`gdalinfo ${odir}/drainage.png | grep "Size is" | sed 's/Size//g;s/is//g;s/ //g'| awk -F',' 'NR==1 {print $1}'`
sy=`gdalinfo ${odir}/drainage.png | grep "Size is" | sed 's/Size//g;s/is//g;s/ //g'| awk -F',' 'NR==1 {print $2}'`


echo -n > ${odir}/geoinfo_drainage.dat
echo "extent=(${upleft}:(${lowright}" >> ${odir}/geoinfo_drainage.dat
echo "projection=4326" >> ${odir}/geoinfo_drainage.dat
echo "size=(${sx},${sy})" >> ${odir}/geoinfo_drainage.dat
echo "area=${area}" >> ${odir}/geoinfo_drainage.dat


if [[ "$dummy" ]] ;then
    rm -rf $dummy
fi

echo $area ${odir}/drainage.png ${sx} ${sy}

exit 0


