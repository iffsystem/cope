#!/bin/bash


#-- directory path at top
RPATH=$(cd $(dirname $0)/../../;pwd)


#-- read filesystem
. ${RPATH}/config/filesystem.conf

#-- read filesystem
. ${RPATH}/config/database.conf

#--- read options
OPT=`getopt -o " " -l project: -l chain: -l status: -l accvol: -- "$@"`
if [ "$?" -ne 0  -o "`echo ${OPT}`" == "--" ]; then
      echo "Usage: $0 "
      echo "      [--project=character] (project name)"
      echo "      [--chain=character] (full path of a processed chain)"
      echo "      [--status=number] (0:calculated, 1:calculating)"
      echo "      [--accvol=number] (accumulated volume to set index of database)"
      exit
fi

eval set -- "$OPT"

until [ "$1" == "--" ]; do

      case $1 in
            --project)
                  project=$2
                  ;;
            --chain)
                  chainpath=$2
                  ;;
            --status)
                  status=$2
                  ;;
            --accvol)
                  accvol=$2
                  ;;
      esac
      shift
done

if [ -z "${accvol}" ]; then
    accvol=0
fi

xx=`echo $chainpath | awk -F'/chain' '{print $1}'`

realdempath="${xx}/condition/topography/DEM/${project}_relief_4326.png"

if [ ! -e "${realdempath}" ]; then
    echo "ERROR in $0"
    echo "cannot find base layer file: $realdempath"
    echo "project : $project"
    echo "chainpath : $chainpath"
    sleep 1
    exit
fi


#--- get project ID from logical DB
projectid=`psql -h ${DB_SERVER} -p ${DB_PORT} -U postgres -d ${DB_NAME} -t -A << __EOF__
        
        \set ON_ERROR_STOP TRUE


        SELECT projectid
            FROM ${DTB_DEM}
            WHERE
                projectname = '${project}'
                AND dempath = '${realdempath}';
    
__EOF__`



#--- get phenomenon ID from logical DB 

xx=`basename ${chainpath}`
sim_type=`echo ${xx} | awk -F'_case' '{print $1}'`

pnum=`cat ${D_ENGINE}/program.json 2>/dev/null | jq '.program| length'`
phenomenonid=0
for j in `seq 1 $pnum`
do
    cc=`cat ${D_ENGINE}/program.json 2>/dev/null  | jq -r '.program."'${j}'".name'`
    if [ "${cc}" == "${sim_type}" ]; then
        phenomenonid=${j}
        break 1
    fi
done


xx=`echo ${chainpath} | sed -e  's#'${RPATH}/'##g'`
samnailimgpath="/${xx}/fdepthmax_thumb.gif"

#--- register chains information in logical DB
date_now=`date "+%Y-%m-%d %H:%M:%S"`

val=`psql -h ${DB_SERVER} -p ${DB_PORT} -U postgres -d ${DB_NAME} -t -A << __EOF__

    BEGIN;
    
    /* update record in table if target did not exist in table */
    /* if not, do INSERT */
    UPDATE ${DTB_RES}
        SET samnailimgpath = '${samnailimgpath}',totalvolume = '${accvol}' ,calcprogress = '${status}', update = '${date_now}'
        WHERE 
            projectid = '${projectid}'
            AND chainpath = '${chainpath}'
            AND phenomenonid = '${phenomenonid}';
    
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
