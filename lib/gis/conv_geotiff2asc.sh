#!/bin/bash


#--- read options
OPT=`getopt -o " " -l in: -l data: -l header:  -- "$@"`
if [ "$?" -ne 0  -o "`echo ${OPT}`" == "--" ]; then
      echo "Usage: $0 "
      echo "      [--in=<path+file>] (geotif)"
      echo "      [--data=<path+file>] (target directory)"
      echo "      [--header=<path+file>] (target directory)"
      exit
fi

eval set -- "$OPT"

until [ "$1" == "--" ]; do

      case $1 in
            --in)
                  infile=$2
                  ;;
            --data)
                  data=$2
                  ;;
            --header)
                  header=$2
                  ;;
      esac
      shift
done

#--- convert GeoTiff to ERSI-ASCII format
gdal_translate -of "AAIGrid" ${infile} ${data}

cat ${data} | sed -e 's/  */ /g' | sed -e 's/^  *//g' > ${data}.out2

mv -f ${data}.out2 ${data}

w=`gdalinfo ${infile} | grep "Upper Left" | sed 's/(//g;s/)//g;s/Upper//g;s/Left//g;s/\,//g' | awk -F' ' 'NR==1 {print $1}'`
n=`gdalinfo ${infile} | grep "Upper Left" | sed 's/(//g;s/)//g;s/Upper//g;s/Left//g;s/\,//g' | awk -F' ' 'NR==1 {print $2}'`
e=`gdalinfo ${infile} | grep "Lower Right" | sed 's/(//g;s/)//g;s/Lower//g;s/Right//g;s/\,//g' | awk -F' ' 'NR==1 {print $1}'`
s=`gdalinfo ${infile} | grep "Lower Right" | sed 's/(//g;s/)//g;s/Lower//g;s/Right//g;s/\,//g' | awk -F' ' 'NR==1 {print $2}'`

cols=`gdalinfo ${infile} | grep "Size is" | sed 's/Size//g;s/is//g;s/ //g' | awk -F',' 'NR==1 {print $1}'`
rows=`gdalinfo ${infile} | grep "Size is" | sed 's/Size//g;s/is//g;s/ //g' | awk -F',' 'NR==1 {print $2}'`

dlx=`gdalinfo ${infile} | grep "Pixel" | sed 's/(//g;s/)//g;s/Pixel//g;s/Size//g;s/=//g;s/ //g' | awk -F',' 'NR==1 {print $1}'`
dly=`gdalinfo ${infile} | grep "Pixel" | sed 's/(//g;s/)//g;s/Pixel//g;s/Size//g;s/=//g;s/ //g' | awk -F',' 'NR==1 {print $2}'`

echo "north: ${n}" > ${header}
echo "south: ${s}" >> ${header}
echo "east: ${e}" >> ${header}
echo "west: ${w}" >> ${header}
echo "rows: ${rows}" >> ${header}
echo "cols: ${cols}" >> ${header}
echo "dlx: ${dlx}" >> ${header}
echo "dly: ${dly}" >> ${header}

#--- check number of header lines of ERSI-ASCII format
cnt=0
for i in ncols nrows cellsize xllcorner yllcorner nodata_value nbits pixeltype byteorder
do
    xx=`cat ${data} | head -10 | grep -i ${i} | wc -l`
    
    if [ "${xx}" -eq 1 ]; then
        cnt=$((cnt+1))
    fi
done 

#--- cut header part of ERSI-ASCII format
sed -i ${data} -e "1,${cnt}d"

#--- replace header as GRASS-ASCII format
sed -i ${data} -e "1i cols: ${cols}"
sed -i ${data} -e "1i rows: ${rows}"
sed -i ${data} -e "1i west: ${w}"
sed -i ${data} -e "1i east: ${e}"
sed -i ${data} -e "1i south: ${s}"
sed -i ${data} -e "1i north: ${n}"





exit 0




