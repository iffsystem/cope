#!/bin/bash


#-- directory path at top
RPATH=$(cd $(dirname $0)/../../;pwd)


#-- read filesystem
. ${RPATH}/config/filesystem.conf


#--- read options
OPT=`getopt -o " " -l target: -- "$@"`
if [ "$?" -ne 0  -o "`echo ${OPT}`" == "--" ]; then
      echo "Usage: $0 "
      echo "      [--target=<path+file>] (layer.map)"
      exit
fi

eval set -- "$OPT"

until [ "$1" == "--" ]; do

      case $1 in
            --target)
                  target=$2
                  ;;
      esac
      shift
done

cat  << _EOF > ${target}
MAP
    STATUS ON

     EXTENT -180 -90 180 90
	
    UNITS DD 
    IMAGECOLOR 0 0 0
    IMAGETYPE PNG 

    PROJECTION
        "init=epsg:4326"
    END

    OUTPUTFORMAT
       NAME "geojson"
       DRIVER "OGR/GEOJSON"
       MIMETYPE "application/json; subtype=geojson"
       FORMATOPTION "STORAGE=stream"
       FORMATOPTION "FORM=SIMPLE"
    END

    WEB
        IMAGEPATH "/var/www/html/"
        IMAGEURL  "/tmp/"
        EMPTY  "/opt/map.template/nodata.html"
        METADATA
            "ows_enable_request"   "*"
        	"wms_enable_request"   "*"
            "wms_title"           "MDW WMS Server"
            "wms_onlineresource"  "/cgi-bin/map/mapserv?map=/opt/map/layer.map"
            "ows_onlineresource"  "/cgi-bin/map/mapserv?map=/opt/map/layer.map"
            "wms_srs"             "EPSG:4612 EPSG:4326 EPSG:3857" 
            "wms_feature_info_mime_type" "text/html"
            "LABELCACHE_MAP_EDGE_BUFFER" "-20"
            "ows_encoding" "utf8"
            "wms_encoding" "utf8"
        END
        TEMPLATE ""
    END
_EOF

exit 0


