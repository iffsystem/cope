#!/bin/bash


#--- get my process ID
_PID=$$

#-- directory path at top
RPATH=$(cd $(dirname $0)/../../;pwd)


#-- read filesystem
. ${RPATH}/config/filesystem.conf


#--- read options
OPT=`getopt -o " " -l target: -l name: -l data: -l status: -- "$@"`
if [ "$?" -ne 0  -o "`echo ${OPT}`" == "--" ]; then
      echo "Usage: $0 "
      echo "      [--target=<path+file>] (layer.map)"
      echo "      [--name=character] "
      echo "      [--data=<path+file>] "
      echo "      [--status=<ON/OFF>]"
      exit
fi

eval set -- "$OPT"

until [ "$1" == "--" ]; do

      case $1 in
            --target)
                  target=$2
                  ;;
            --name)
                  name=$2
                  ;;
            --data)
                  data=$2
                  ;;
            --status)
                  status=$2
                  ;;
      esac
      shift
done

cat  << _EOF >> ${target}
      NAME "${name}"
      DATA "${data}"
      TYPE RASTER
      STATUS ${status}
      PROJECTION
          "init=epsg:4326"
      END
      OFFSITE 0 0 0
      PROCESSING  "EXTENT_PRIORITY = WORLD"
_EOF

exit 0


