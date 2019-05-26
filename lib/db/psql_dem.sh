#!/bin/bash



#-- directory path at top
RPATH=$(cd $(dirname $0)/../../;pwd)

#-- read filesystem
. ${RPATH}/config/filesystem.conf

#-- read filesystem
. ${RPATH}/config/database.conf

#--- read options
OPT=`getopt -o " " -l project: -- "$@"`
if [ "$?" -ne 0  -o "`echo ${OPT}`" == "--" ]; then
      echo "Usage: $0 "
      echo "      [--project=character] (project name)"
      exit
fi

eval set -- "$OPT"

until [ "$1" == "--" ]; do

      case $1 in
            --project)
                  project=$2
                  ;;
      esac
      shift
done



projectpath=`dirname ${project}`
projectname=`basename ${project}`
dempath="${projectpath}/${projectname}_relief_4326.png"

lon=`gdalinfo ${projectpath}/${projectname}_relief_4326.tif | grep "Center" | sed 's/\s\+/ /g;s/(//g;s/)/,/g;s/Center//g;s/ //g'| awk -F',' 'NR==1 {print $1}'`
lat=`gdalinfo ${projectpath}/${projectname}_relief_4326.tif | grep "Center" | sed 's/\s\+/ /g;s/(//g;s/)/,/g;s/Center//g;s/ //g'| awk -F',' 'NR==1 {print $2}'`

if [ ! -n "${lon}" -o ! -n "${lat}" ]; then
    echo "$0 : cannot get lat,lon value"
    exit
fi

#-- check file existence
val=`psql -h ${DB_SERVER} -p ${DB_PORT} -U postgres -d ${DB_NAME} -t -A << __EOF__
    
    \set ON_ERROR_STOP TRUE
    
    BEGIN;
    
    /* update record in table if target did not exist in table */
    /* if not, do INSERT */
    UPDATE ${DTB_DEM}
        SET projectname = '${projectname}',projectpath = '${projectpath}',dempath = '${dempath}',lat = '${lat}',lon = '${lon}'
        WHERE 
            projectname = '${projectname}'
            AND projectpath = '${projectpath}'
            AND dempath = '${dempath}';
            
    /* insert record in table if target did not exist in table */
    INSERT INTO ${DTB_DEM}
        (projectname,projectpath,dempath,lat,lon)
        SELECT '${projectname}','${projectpath}','${dempath}','${lat}','${lon}'
        WHERE
            NOT EXISTS (
                SELECT projectname,projectpath,dempath
                FROM ${DTB_DEM}
                WHERE 
                    projectname = '${projectname}'
                    AND projectpath = '${projectpath}'
                    AND dempath = '${dempath}'
            );
    
    COMMIT;
    
__EOF__`

ERRCODE=$?
        
if [ ${ERRCODE} -eq 0 ]; then
    echo " [DB:OK]"
    
elif [ ${ERRCODE} -eq 3 ]; then
    echo " [DB:ERROR]"

    exit 99
fi
exit 0


