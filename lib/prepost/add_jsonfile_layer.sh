#!/bin/bash


#-- directory path at top
RPATH=$(cd $(dirname $0)/../../;pwd)

#-- read filesystem
. ${RPATH}/config/filesystem.conf


#--- read options
OPT=`getopt -o " " -l target: -l name: -l olayer: -l mslayer: -l ltype: -l step: -l interval: -l show: -- "$@"`
if [ "$?" -ne 0  -o "`echo ${OPT}`" == "--" ]; then
      echo "Usage: $0 "
      echo "      [--target=<path+file>] (setting.json)"
      echo "      [--name=character] "
      echo "      [--olayer=character] "
      echo "      [--mslayer=<path+file>]"
      echo "      [--ltype=character] (timeSeries/base/static)"
      echo "      [--step=<null/value>]"
      echo "      [--interval=value]"
      echo "      [--show=<bool>] (true/false)"
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
            --olayer)
                  ol=$2
                  ;;
            --mslayer)
                  msl=$2
                  ;;
            --ltype)
                  ltype=$2
                  ;;
            --step)
                  step=$2
                  ;;
            --interval)
                  int=$2
                  ;;
            --show)
                  show=$2
                  ;;
      esac
      shift
done

cat  << _EOF >> ${target}
  {
    "displayName":"${name}",
    "olLayerName":"${ol}",
    "msLayerName":"${msl}",
    "layerType":"${ltype}",
    "timeDimension":{
      "step":${step},
      "stepInterval": ${int}
    },
    "default":${show}
  },
_EOF

exit 0


