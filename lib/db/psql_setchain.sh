#!/bin/bash


#-- directory path at top
RPATH=$(cd $(dirname $0)/../../;pwd)


#-- read filesystem
. ${RPATH}/config/filesystem.conf

#-- read filesystem
. ${RPATH}/config/database.conf


#--- read options
OPT=`getopt -o " " -l project: -l chainlist: -- "$@"`
if [ "$?" -ne 0  -o "`echo ${OPT}`" == "--" ]; then
      echo "Usage: $0 "
      echo "      [--project=character] (project name)"
      echo "      [--chainlist=character] (file containing fullpath of chains e.g. .ready_chain.list)"
      exit
fi

eval set -- "$OPT"

until [ "$1" == "--" ]; do

      case $1 in
            --project)
                  project=$2
                  ;;
            --chainlist)
                  chainlist=$2
                  ;;
      esac
      shift
done

xx=`cat $chainlist | awk -F' ' 'NR==1 {print $2}'`
project_dir=`echo $xx | awk -F'/chain' '{print $1}'`



realdempath=${project_dir}/condition/topography/DEM/${project}_relief_4326.png

xx=`ls ${realdempath} 2>/dev/null | wc -l`
if [ ${xx} -eq 0 ]; then
    echo "ERROR in $0"
    echo " cannot find DEM file : $realdempath"
    echo " project = $project"
    exit
fi




projectid=`psql -h ${DB_SERVER} -p ${DB_PORT} -U postgres -d ${DB_NAME} -t -A << __EOF__
        
        \set ON_ERROR_STOP TRUE
        
        SELECT projectid
            FROM ${DTB_DEM}
            WHERE
                projectname = '${project}'
                AND dempath = '${realdempath}';
    
__EOF__`


echo "projectid=${projectid}"

#--- get cumlative volume of same phenomena from chains
trap '[[ "$dummy" ]] && rm -rf $dummy' ERR 1 2 3 15


#--- register chains information in logical DB
lnum=`cat ${chainlist} | awk 'END{print NR}'`

for i in `seq 1 ${lnum}`
do
    xx=`cat ${chainlist} | awk -F' ' 'NR=='${i}'{print}'`
    chainpath=`cat ${chainlist} | awk -F' ' 'NR=='${i}'{$1="";print}' | sed -e 's/^ //g'`
    
    echo ${chainpath}
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
    
    
    date_now=`date "+%Y-%m-%d %H:%M:%S"`
    
    
    val=`psql -h ${DB_SERVER} -p ${DB_PORT} -U postgres -d ${DB_NAME} -t -A << __EOF__
    
    BEGIN;
    
    /* update record in table if target did not exist in table */
    /* if not, do INSERT */
    UPDATE ${DTB_RES}
        --SET totalVolume = '${accvol}',update = '${date_now}'
        SET update = '${date_now}'
        WHERE 
            projectid = '${projectid}'
            AND chainpath = '${chainpath}'
            AND phenomenonid = '${phenomenonid}'
            AND calcprogress is NULL;
    
    
         
    /* insert record in table if target did not exist in table */
    INSERT INTO ${DTB_RES}
        (projectid,chainpath,phenomenonid,update)
        SELECT '${projectid}','${chainpath}','${phenomenonid}','${date_now}'
        WHERE
            NOT EXISTS (
                SELECT projectid,chainpath,phenomenonid,update
                FROM ${DTB_RES}
                WHERE 
                    projectid = '${projectid}'
                    AND chainpath = '${chainpath}'
                    AND phenomenonid = '${phenomenonid}'
                    AND calcprogress is NULL
            );

    COMMIT;
__EOF__`

done


ERRCODE=$?
        
if [ ${ERRCODE} -eq 0 ]; then
    echo " [DB:OK]"
    
elif [ ${ERRCODE} -eq 3 ]; then
    echo " [DB:ERROR]"

    exit 99
fi
exit 0


