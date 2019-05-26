#!/bin/bash


#-- directory path at top
RPATH=$(cd $(dirname $0)/../../;pwd)

#-- read filesystem
. ${RPATH}/config/filesystem.conf


#--- read options
OPT=`getopt -o " " -l script: -l in: -l epsg: -l vmin: -l vmax: -l odir: -l oname:  -- "$@"`
if [ "$?" -ne 0  -o "`echo ${OPT}`" == "--" ]; then
      echo "Usage: $0 "
      echo "      [--script=<path+file>] (python script)"
      echo "      [--in=<path+file>] (geotiff)"
      echo "      [--epsg=value] (WGS84-LatLon)"
      echo "      [--vmin=value] (for colorbar range)"
      echo "      [--vmax=value] (for colorbar range)"
      echo "      [--odir=<path>] (output)"
      echo "      [--oname=<file>] (output: RGBA geotiff without background)"
      exit
fi

eval set -- "$OPT"

until [ "$1" == "--" ]; do

      case $1 in
            --script)
                  script=$2
                  ;;
            --in)
                  infile=$2
                  ;;
            --epsg)
                  epsg=$2
                  ;;
            --vmin)
                  vmin=$2
                  ;;
            --vmax)
                  vmax=$2
                  ;;
            --odir)
                  odir=$2
                  ;;
            --oname)
                  oname=$2
                  ;;
      esac
      shift
done

#--- get geo information
w=`gdalinfo ${infile} | grep "Upper Left" | sed 's/(//g;s/)//g;s/Upper//g;s/Left//g;s/\,//g' | awk -F' ' 'NR==1 {print $1}'`
n=`gdalinfo ${infile} | grep "Upper Left" | sed 's/(//g;s/)//g;s/Upper//g;s/Left//g;s/\,//g' | awk -F' ' 'NR==1 {print $2}'`
e=`gdalinfo ${infile} | grep "Lower Right" | sed 's/(//g;s/)//g;s/Lower//g;s/Right//g;s/\,//g' | awk -F' ' 'NR==1 {print $1}'`
s=`gdalinfo ${infile} | grep "Lower Right" | sed 's/(//g;s/)//g;s/Lower//g;s/Right//g;s/\,//g' | awk -F' ' 'NR==1 {print $2}'`
px=`gdalinfo ${infile} | grep "Pixel Size" | sed 's/(//g;s/)//g;s/Pixel//g;s/Size//g;;s/ //g;s/=//g'| awk -F',' 'NR==1 {print $1}'`
py=`gdalinfo ${infile} | grep "Pixel Size" | sed 's/(//g;s/)//g;s/Pixel//g;s/Size//g;s/ //g;s/=//g'| awk -F',' 'NR==1 {print $2}'`

px=`echo ${px} | awk '{printf ($1*0.5)}'`
py=`echo ${py} | awk '{printf ($1*0.5)}'`

fname=`basename ${infile} .tif`

dirname=`dirname ${infile}`

#--- make png (with/wihtout background)
python ${script} ${infile} -dpi 900 -vmin ${vmin} -vmax ${vmax}

#-- convert png to RGBA geotiff without background
gdal_translate -of "GTiff" -a_ullr ${w} ${n} ${e} ${s} -a_srs EPSG:${epsg} ${dirname}/${fname}.png ${dirname}/${fname}_${epsg}_dummy.tif
gdalwarp -of "GTiff" -tr ${px} ${py} -te ${w} ${s} ${e} ${n} -r cubic ${dirname}/${fname}_${epsg}_dummy.tif ${dirname}/${fname}_${epsg}_dummy2.tif -overwrite

gdalwarp -of "GTiff" -s_srs EPSG:${epsg} -t_srs EPSG:4326 ${dirname}/${fname}_${epsg}_dummy2.tif -co "COMPRESS=LZW" -co "PREDICTOR=2" ${odir}/${oname} -overwrite


rm -f ${dirname}/${fname}.png
rm -f ${dirname}/${fname}_${epsg}_dummy.tif
rm -f ${dirname}/${fname}_${epsg}_dummy2.tif

#-- add pylamid
gdaladdo -r cubic ${odir}/${oname} 2 4 8 16

exit 0


