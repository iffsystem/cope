#!/bin/bash


#--- read options
OPT=`getopt -o " " -l in: -l west: -l north: -l east: -l south: -l target:  -- "$@"`
if [ "$?" -ne 0  -o "`echo ${OPT}`" == "--" ]; then
      echo "Usage: $0 "
      echo "      [--in=<path+file>] (geotif)"
      echo "      [--west=value] (coordinate)"
      echo "      [--north=value] (coordinate)"
      echo "      [--east=value] (coordinate)"
      echo "      [--south=value] (coordinate)"
      echo "      [--target=<path+file>] (target directory)"
      exit
fi

eval set -- "$OPT"

until [ "$1" == "--" ]; do

      case $1 in
            --in)
                  infile=$2
                  ;;
            --west)
                  west=$2
                  ;;
            --north)
                  north=$2
                  ;;
            --east)
                  east=$2
                  ;;
            --south)
                  south=$2
                  ;;
            --target)
                  target=$2
                  ;;
      esac
      shift
done

px=`gdalinfo ${infile} | grep "Pixel Size" | sed 's/(//g;s/)//g;s/Pixel//g;s/Size//g;;s/ //g;s/=//g'| awk -F',' 'NR==1 {print $1}'`
py=`gdalinfo ${infile} | grep "Pixel Size" | sed 's/(//g;s/)//g;s/Pixel//g;s/Size//g;s/ //g;s/=//g'| awk -F',' 'NR==1 {print $2}'`

gdalwarp -of "GTiff" -tr ${px} ${py} -te ${west} ${south} ${east} ${north} -r cubic ${infile} ${target} -overwrite

exit 0




