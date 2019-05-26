#!/bin/bash


#-- directory path at top
RPATH=$(cd $(dirname $0)/../../;pwd)

#-- read filesystem
. ${RPATH}/config/filesystem.conf


#--- read options
OPT=`getopt -o " " -l ante: -l add: -l delay: -l odir: -l oname:  -- "$@"`
if [ "$?" -ne 0  -o "`echo ${OPT}`" == "--" ]; then
      echo "Usage: $0 "
      echo "      [--ante=<path+file>] (antecedent gif)"
      echo "      [--add=<path+file>] (png file for making gif)"
      echo "      [--delay=value] (interval for each figure in the gif [1/100 sec])"
      echo "      [--odir=<path>] (output)"
      echo "      [--oname=<file>] (output: RGBA geotiff without background)"
      exit
fi

eval set -- "$OPT"

until [ "$1" == "--" ]; do

      case $1 in
            --ante)
                  ante=$2
                  ;;
            --add)
                  add=$2
                  ;;
            --delay)
                  delay=$2
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


if [ "${ante}" == "null" ]; then
    convert -delay ${delay} -loop 0 ${add} ${odir}/${oname}
else
    convert -delay ${delay} -loop 0 ${ante} ${add} ${odir}/${oname}
    
    echo "ADD ${add} in ${ante}"

fi


exit 0


