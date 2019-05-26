#!/bin/bash


#--- read options
OPT=`getopt -o " " -l in: -l epsg: -l out:  -- "$@"`
if [ "$?" -ne 0  -o "`echo ${OPT}`" == "--" ]; then
      echo "Usage: $0 "
      echo "      [--in=<path+file>] (ASCII)"
      echo "      [--epsg=value] (WGS84-UTM)"
      echo "      [--out=<path+file>] (output)"
      exit
fi

eval set -- "$OPT"

until [ "$1" == "--" ]; do

      case $1 in
            --in)
                  infile=$2
                  ;;
            --epsg)
                  epsg=$2
                  ;;
            --out)
                  out=$2
                  ;;
      esac
      shift
done

cat ${infile} | sed -e 's/  */ /g' | sed -e 's/^  *//g' > ${infile}.out2

rm -f ${infile}

gdal_translate -a_srs EPSG:${epsg} -co "COMPRESS=LZW" -co "PREDICTOR=2" ${infile}.out2 ${out}


rm -f ${infile}.out2

exit 0




