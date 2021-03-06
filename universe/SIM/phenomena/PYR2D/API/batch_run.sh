#!/bin/bash


#-- directory path at top
RPATH=$(cd $(dirname $0)/../../../../../;pwd)

#-- directory path at this script
CPATH=$(cd $(dirname $0)/;pwd)

#-- read filesystem
. ${RPATH}/config/filesystem.conf



#--- read options
OPT=`getopt -o " " -l project: -l target: -l retry: -- "$@"`
if [ "$?" -ne 0  -o "`echo ${OPT}`" == "--" ]; then
      echo "Usage: $0 "
      echo "      [--project=character] (project name)"
      echo "      [--target=<path>] (target directory)"
      echo "      [--retry=value] (retry flag)"
      exit
fi

eval set -- "$OPT"

until [ "$1" == "--" ]; do

      case $1 in
            --project)
                  project=$2
                  ;;
            --target)
                  target=$2
                  ;;
            --retry)
                  retry=$2
                  ;;
      esac
      shift
done

echo "project = "$project
echo "target(queue) = "$target
echo "retry = "$retry
echo

touch ${target}/.calc.on
trap 'touch ${target}/.calc.err ; sleep 5 && [[ "$dummy" ]] && tar cfvz $dummy.tar.gz $dummy && rm -rf $dummy' ERR 1 2 3 15

unset dummy
dummy=$(mktemp -d ${target}/`basename $0`_XXXXX)

start_batch=`date "+%Y%m%d %H:%M.%S"`
echo "[START BATCH @ ${start_batch}]"


# ******************************************************************
#   register database
# ******************************************************************
echo "[PROC START] registration of information to logical Databae"

bash ${D_API}/db/psql_result.sh --project ${project} --chain ${target} --status 1


#******************************************************************
#   get variables from case file
#******************************************************************
echo "[Proc] get variables from case file"

basedir=`echo $target | awk -F'/chain/' '{print $1}'`
sim_ID=$(basename $target)
sim_type=`echo ${sim_ID} | awk -F'_case' '{print $1}'`
casefile="${basedir}/case/${sim_type}/${sim_ID}.json"


#--- get variables
list=`cat $casefile | jq -rc 'paths'| grep val | sed -e 's/,/./g' -e 's/\[//g' -e 's/\]//g'`
nn=0
for i in ${list[*]}
do
    nn=$((nn+1))
    xx=`cat $casefile | jq -r '.'${i}''`
    echo $nn: $i : $xx
    
    if [ `echo $xx|grep phenomena` ]; then
        echo "  phenomena"
        
    elif [ `echo $xx|grep magma` ]; then
        echo "  magma"
        fric=`cat ${basedir}/condition/magma/${xx} | jq -r '.field.condition.ejector.domeCollapse.frictionFactor.value' | awk '{pi=4.0*atan2(1,1);xx=atan2($1,1)*180/pi;print xx}'`
        diam=`cat ${basedir}/condition/magma/${xx} | jq -r '.field.condition.ejector.domeCollapse.particleDiameter.value' | awk '{print $1*100}'`
        vol=`cat ${basedir}/condition/magma/${xx} | jq -r '.field.condition.ejector.domeCollapse.volume.value' | awk '{print $1*1.0}'`
        dur=`cat ${basedir}/condition/magma/${xx} | jq -r '.field.condition.ejector.domeCollapse.duration.value'`
        shape=`cat ${basedir}/condition/magma/${xx} | jq -r '.field.condition.ejector.domeCollapse.waveform.value'`
        wid=`cat ${basedir}/condition/magma/${xx} | jq -r '.field.condition.ejector.domeCollapse.width.value'`
        dir=`cat ${basedir}/condition/magma/${xx} | jq -r '.field.condition.ejector.domeCollapse.azimuth.value' | awk '{if($1-90 < 1) {print $1-90+360} else if($1>=360){print $1-360} else {print $1-90} }'`
        x=`cat ${basedir}/condition/magma/${xx} | jq -r '.field.condition.ejector.domeCollapse.point.lon.value'`
        y=`cat ${basedir}/condition/magma/${xx} | jq -r '.field.condition.ejector.domeCollapse.point.lat.value'`
        
    elif [ `echo $xx|grep topography` ]; then
        echo "  topography"
        DEM=`cat ${basedir}/condition/topography/${xx} | jq -r '.field.condition.dem.file.path.value'`
        w=`cat ${basedir}/condition/topography/${xx} | jq -r '.field.condition.dem.extent."lon-NW".value'`
        n=`cat ${basedir}/condition/topography/${xx} | jq -r '.field.condition.dem.extent."lat-NW".value'`
        e=`cat ${basedir}/condition/topography/${xx} | jq -r '.field.condition.dem.extent."lon-SE".value'`
        s=`cat ${basedir}/condition/topography/${xx} | jq -r '.field.condition.dem.extent."lat-SE".value'`
    fi
done

# get accumulated volume
ppath=`echo $target | awk -F'/chain/' '{print $2}'| tr -t '/' ' ' `

accvol=0
for case in $ppath
do
    xx=`echo $case | awk -F'_case' '{print $1}'`
    if [ "${xx}" == "${sim_type}" ]; then
        cons=`cat ${basedir}/case/${sim_type}/${case}.json | jq -r '.condition|length'`
        for i in `seq 1 $cons`
        do
            condf=`cat ${basedir}/case/${sim_type}/${case}.json | jq -r '.condition."'${i}'".val'`
            xx=`echo $condf | awk -F'_' '{print $1}'`
            
            if [ "${xx}" == "magma" ]; then
                vol=`cat ${basedir}/condition/magma/${condf} | jq -r '.field.condition.ejector.domeCollapse.volume.value' | awk '{print $1*1.0}'`
                accvol=`echo $accvol $vol | awk '{xx=$1*1.0+$2*1.0;print xx}'`
                
                break 1
            fi
            
        done
    fi
done


echo
echo "ppath = "$ppath
echo "accvol = "$accvol

# ******************************************************************
#   update database
# ******************************************************************
echo "[SET ACC VOLUME] update information to logical Databae"

bash ${D_API}/db/psql_result.sh --project ${project} --chain ${target} --accvol ${accvol} --status 1

echo "  OK: get variables from case file"
#--------------------------------------------------------------------

#******************************************************************
#   read sim config file
#******************************************************************
echo "[Proc] read sim. config file"
# read shell variables defined in config file
. ${D_ENGINE}/${sim_type}/API/setting/${sim_type}.conf

# get path of engine
xx="D_${sim_type}"
engine_dir=${!xx}

# get filename of array setting in simulation
xx="${sim_type}_finc"
farray_setting=${!xx}

# get filename of output contents setting in simulation
xx="${sim_type}_fout"
fout_setting=${!xx}


if [ ! -e "${fout_setting}" ]; then
    echo
    echo "ERROR: file of output contents list is not exist: ${fout_setting}"
    echo "quit"
    echo
    exit 99
fi
echo "  OK: read sim. config file"
#--------------------------------------------------------------------

#******************************************************************
#   set output prepost setting
#******************************************************************
echo "[Proc] set output contents"
# read output contents list & prepost setting
cnt=0
while read line || [ -n "${line}" ]
do
    # skip commentout(#) and empty line
    num=`echo ${line} | grep -v -e '^\s*#' -e '^\s*$'| wc -l`
    if [ ${num} -eq 0 ]; then
        continue
    fi
    
    
    cname[${cnt}]=`echo ${line}| awk -F',' '{print $1}'`
    cabbreviation[${cnt}]=`echo ${line}| awk -F',' '{print $2}'`
    cvmin[${cnt}]=`echo ${line}| awk -F',' '{print $3}'`
    cvmax[${cnt}]=`echo ${line}| awk -F',' '{print $4}'`
    cunit[${cnt}]=`echo ${line}| awk -F',' '{print $5}'`
    cdraw[${cnt}]=`echo ${line}| awk -F',' '{print $6}'`
    cseries[${cnt}]=`echo ${line}| awk -F',' '{print $7}'`
    cshow[${cnt}]=`echo ${line}| awk -F',' '{print $8}'`
    
    cnt=$((cnt+1))
done < ${fout_setting}

echo "  OK: set output contents"
#--------------------------------------------------------------------


#******************************************************************
#   set physical conttant/coefficient
#******************************************************************
echo "[Proc] set physical constant/coefficient file"

conffile=${dummy}/param.dat

rsync -a ${engine_dir}/engine/ref_parameters.dat ${conffile}

lnum=`cat ${conffile} | grep -n ' fai ' |awk -F':' '{print $1}'`
sed -i ${conffile} -e ''$lnum's/xxx/'${fric}'/g'

lnum=`cat ${conffile} | grep -n ' dm ' |awk -F':' '{print $1}'`
sed -i ${conffile} -e ''$lnum's/xxx/'${diam}'/g'


echo "  OK: set physical constant/coefficient file"
#--------------------------------------------------------------------


#******************************************************************
#   set DEM 
#******************************************************************
echo "[Proc] set DEM file"

epsg_utm=`ls ${basedir}/condition/topography/DEM | grep .epsg | sed -e 's/.epsg//g'`


# get domain of original dem
w0=`gdalinfo ${DEM} | grep "Upper Left" | sed 's/(//g;s/)//g;s/Upper//g;s/Left//g;s/\,//g' | awk -F' ' 'NR==1 {print $1}'`
n0=`gdalinfo ${DEM} | grep "Upper Left" | sed 's/(//g;s/)//g;s/Upper//g;s/Left//g;s/\,//g' | awk -F' ' 'NR==1 {print $2}'`
e0=`gdalinfo ${DEM} | grep "Lower Right" | sed 's/(//g;s/)//g;s/Lower//g;s/Right//g;s/\,//g' | awk -F' ' 'NR==1 {print $1}'`
s0=`gdalinfo ${DEM} | grep "Lower Right" | sed 's/(//g;s/)//g;s/Lower//g;s/Right//g;s/\,//g' | awk -F' ' 'NR==1 {print $2}'`


# convert value corresponded by EPSG
lon=$w
lat=$n
w=`bash ${D_API}/gis/conv_point_EPSG.sh --t_epsg ${epsg_utm} --lon ${lon} --lat ${lat}| awk -F',' 'NR==2{print $1}'`
n=`bash ${D_API}/gis/conv_point_EPSG.sh --t_epsg ${epsg_utm} --lon ${lon} --lat ${lat}| awk -F',' 'NR==2{print $2}'`
lon=$e
lat=$s
e=`bash ${D_API}/gis/conv_point_EPSG.sh --t_epsg ${epsg_utm} --lon ${lon} --lat ${lat}| awk -F',' 'NR==2{print $1}'`
s=`bash ${D_API}/gis/conv_point_EPSG.sh --t_epsg ${epsg_utm} --lon ${lon} --lat ${lat}| awk -F',' 'NR==2{print $2}'`

# update dem (add parent's thickness of sedimentation at last time)
parent_dir=`dirname ${target}`

xx=`ls ${parent_dir} | grep "next_initial_condition" | grep .tif | sort -r | head -n 1`

if [ ! -z "${xx}" ]; then
    initialcon="${parent_dir}/${xx}"
fi

echo
echo "--west ${w0} --north ${n0} --east ${e0} --south ${s0}"
echo 

if [ -e "${initialcon}" ]; then
    # clip updated DEM for this event
    bash ${D_API}/gis/clip_dem.sh --in ${initialcon} --west ${w} --north ${n} --east ${e} --south ${s} --target ${dummy}/dem.tif
else
    # clip original dem
    bash ${D_API}/gis/clip_dem.sh --in ${DEM} --west ${w} --north ${n} --east ${e} --south ${s} --target ${dummy}/dem.tif
fi

# convert to ASCII & set header info
bash ${D_API}/gis/conv_geotiff2asc.sh --in ${dummy}/dem.tif --data ${dummy}/dem.dat --header ${dummy}/header.dat

px=`gdalinfo ${dummy}/dem.tif | grep "Pixel Size" | sed 's/(//g;s/)//g;s/Pixel//g;s/Size//g;;s/ //g;s/=//g'| awk -F',' 'NR==1 {print $1}'`
py=`gdalinfo ${dummy}/dem.tif | grep "Pixel Size" | sed 's/(//g;s/)//g;s/Pixel//g;s/Size//g;s/ //g;s/=//g'| awk -F',' 'NR==1 {print $2}'`

ipx=`cat ${dummy}/header.dat| awk -F' ' 'NR==6 {print $2}'`
ipy=`cat ${dummy}/header.dat| awk -F' ' 'NR==5 {print $2}'`

# clip & convert to ASCII original dem
bash ${D_API}/gis/clip_dem.sh --in ${DEM} --west ${w} --north ${n} --east ${e} --south ${s} --target ${dummy}/base_dem.tif
bash ${D_API}/gis/conv_geotiff2asc.sh --in ${dummy}/base_dem.tif --data ${dummy}/base_dem.dat --header ${dummy}/base_header.dat 

echo "  OK: set DEM file"
#--------------------------------------------------------------------


#******************************************************************
#   set inflow condition
#******************************************************************
echo "[Proc] set inflow condition file"


lon=$x
lat=$y
x=`bash ${D_API}/gis/conv_point_EPSG.sh --t_epsg ${epsg_utm} --lon ${lon} --lat ${lat}| awk -F',' 'NR==2{print $1}'`
y=`bash ${D_API}/gis/conv_point_EPSG.sh --t_epsg ${epsg_utm} --lon ${lon} --lat ${lat}| awk -F',' 'NR==2{print $2}'`


# set inflow point meshes
mx=`bash ${D_API}/gis/conv_point_mesh.sh  --dem ${dummy}/dem.tif --t_epsg ${epsg_utm} --x ${x} --y ${y} | awk -F',' 'NR==2 {print $1}'`
my=`bash ${D_API}/gis/conv_point_mesh.sh  --dem ${dummy}/dem.tif --t_epsg ${epsg_utm} --x ${x} --y ${y} | awk -F',' 'NR==2 {print $2}'`


bash ${engine_dir}/API/make_ipp.sh --mx ${mx} --my ${my} --width ${wid} --direction ${dir} --out ${dummy}/ipp.dat

# set coefficient of time step calculation based on CFL condition
CFL_coe=`cat ${engine_dir}/API/setting/ref_CFL_coe.dat | awk -F'[, ]' 'NR=='$((${retry}+1))' {print $1}'`

if [ -z "${CFL_coe}" ]; then
    CFL_coe=0.1
fi

# convert min to sec
xx=`echo ${dur} | awk '{printf ("%.0f",$1 * 60)}'`

if [ -n "${peaktime}" -a -n "${dur}" ]; then
    peaktime=`echo ${dur} ${peaktime} | awk '{printf ($2/$1)}'`
fi

# set hydrograoh
#-- rec
if [ "${shape}" == "rectangle" ]; then
    shape=2
#-- tri
elif [ "${shape}" == "triangle" ]; then
    shape=1
fi

echo "${shape} ${CFL_coe}" > ${dummy}/hyd.dat
echo "------------" >> ${dummy}/hyd.dat
echo "DURATION-TIME_tt_[sec]，TOTAL-VOLUME [m^3]" >> ${dummy}/hyd.dat
#-- rec
if [ ${shape} -eq 2 ]; then
    echo "${xx} ${vol}" >> ${dummy}/hyd.dat
#-- tri
elif [ ${shape} -eq 1 ]; then
    
    echo "${xx} ${vol}" >> ${dummy}/hyd.dat
    echo "${peaktime}" >> ${dummy}/hyd.dat
fi
echo "0.0 0.0" >> ${dummy}/hyd.dat

cat ${dummy}/hyd.dat
echo "  OK: set inflow condition file"
#--------------------------------------------------------------------



#******************************************************************
#   make input file list
#******************************************************************
echo "[Proc] set i/o file list"
# input file&path
echo "header.dat"               >  ${dummy}/flist.dat
echo "'./'"                     >> ${dummy}/flist.dat
echo "param.dat"                >> ${dummy}/flist.dat
echo "'./'"                     >> ${dummy}/flist.dat
echo "hyd.dat"                  >> ${dummy}/flist.dat
echo "'./'"                     >> ${dummy}/flist.dat
echo "ipp.dat"                  >> ${dummy}/flist.dat
echo "'./'"                     >> ${dummy}/flist.dat
echo "base_dem.dat"             >> ${dummy}/flist.dat
echo "'./'"                     >> ${dummy}/flist.dat
echo "dem.dat"                  >> ${dummy}/flist.dat
echo "'./'"                     >> ${dummy}/flist.dat
echo "----------------"         >> ${dummy}/flist.dat
#output file&path
for i in ${cabbreviation[@]}
do
    echo "${sim_ID}_${i}@"      >> ${dummy}/flist.dat      
    echo "'./'"                 >> ${dummy}/flist.dat
done

echo "  OK: set i/o file list"
#--------------------------------------------------------------------

echo
echo "-------------------------"
echo "  ${cabbreviation[@]}"
echo "-------------------------"
echo

#******************************************************************
#   run simulation
#******************************************************************
# copy source codes to working directory
rsync -a ${engine_dir}/engine/* ${dummy}/
cd ${dummy}/

# set array size in config file of simulation program

ipx=$((ipx+6))
ipy=$((ipy+6))


sed -i ${dummy}/${farray_setting} -e '2,2d'
sed -i ${dummy}/${farray_setting} -e "2i       *parameter( in =  ${ipx} , jn = ${ipy} , nh =200 )"
sed -i ${dummy}/${farray_setting} -e '2s/*/      /g'

# execute simulation
make clean
make
tstart=`date "+%Y%m%d %H:%M.%S"`

echo "[Proc simulation start @ ${tstart}]"

./exec

tend=`date "+%Y%m%d %H:%M.%S"`
echo "[Proc simulation end   @ ${tend}] (start: ${tstart})"

make clean
cd ${CPATH}
#--------------------------------------------------------------------

#sleep 600
if [ -e ${target}/".calc.err" ]; then
    # force quit by using error command
    echo " ERROR in simulation"
    tar cfvz ${target}/log_`date "+%Y%m%d%H%M%S"`.tar.gz ${target}/.log.*
    ls /exec-ls-to-no-exist-directory-to-quit-forcibly
    sleep 3
    exit -1
fi

#******************************************************************
#   manage output results
#******************************************************************

mapfile=${target}/layer.map
jsonfile=${target}/setting.json

#-- open mapfile + wirte header
bash ${D_API}/prepost/add_mapfile_header.sh --target ${mapfile}
#-- open jsonfile
echo "[" > ${jsonfile}


#-- set baselayer
basemap=${basedir}/condition/topography/DEM/${project}_relief_4326.tif

rsync -a ${basemap} ${target}/basemap.tif
echo "    LAYER" >> ${mapfile}
bash ${D_API}/prepost/add_mapfile_layer.sh --target ${mapfile} --name "basemap" --data "basemap.tif" --status "ON"
echo "    END" >> ${mapfile}

bash ${D_API}/prepost/add_jsonfile_layer.sh --target ${jsonfile} --name "basemap" --olayer "basemap" --mslayer "basemap" --ltype "static" --step "null" --interval "60" --show "true"



echo ${cabbreviation[@]}


#-- format output results to contain database and to show on WEB-GIS
cnt=0
for i in ${cabbreviation[@]}
do
    list=`ls ${dummy}/ | grep .out | grep "_${i}@"`
    list_num=`ls ${dummy}/ | grep .out | grep "_${i}@" | wc -l`
    
    echo "[Proc] management results (convert format, visualize, register database etc.): ${i}"
    echo "${list}"

    
    #-- treat files in same contents
    for j in ${list}
    do
        
        echo ${j}
        
        fname0=`basename ${j} .out`
        fname_raw=`basename ${j} .out`_raw.tif
        fname_view=`basename ${j} .out`.tif
        
        
        # convert ascii to geotiff
        bash ${D_API}/gis/conv_asc2geotiff.sh  --in "${dummy}/${j}" --epsg ${epsg_utm} --out "${target}/${fname_raw}"
        
        # draw figure
        if [ ${cdraw[${cnt}]} -eq 1 ]; then
            
            
            echo " unit:${cunit[${cnt}]}, cbar_min= ${cvmin[${cnt}]}, cbar_max= ${cvmax[${cnt}]}"
        
            #-- visualize (output RGBA geotiff without background)
            bash ${D_API}/prepost/view_geotiff.sh --script ${D_API}/prepost/geotiff2png.py --in "${target}/${fname_raw}" --epsg ${epsg_utm} --vmin ${cvmin[${cnt}]} --vmax ${cvmax[${cnt}]} --odir "${target}" --oname "${fname_view}"

                        
            #-- set map file for WEB-GIS
            status=OFF
            if [ ${cdraw[${cnt}]} -eq 1 ]; then
                status=ON
            fi
            
            echo "    LAYER" >> ${mapfile}
            
            bash ${D_API}/prepost/add_mapfile_layer.sh --target ${mapfile} --name "${fname0}" --data "${fname_view}" --status "${status}"
            echo "    END" >> ${mapfile}
            
            
        fi        
    done
    
    echo
    echo "  OK: CONV , VIEW GEOTIFF & SET MAPFILE"
    echo
    
    #-- make thumbnail (gif)
    if [ "${i}@" == "fdepthmax@" ]; then
        
        
        #-- expand size from parent domain to original domain for making thumbnail
        bash ${D_API}/gis/clip_dem.sh --in "${target}/${fname_raw}" --west ${w0} --north ${n0} --east ${e0} --south ${s0} --target "${dummy}/${fname_view}"
        
        
        # get file in last time in series
        fname_thumb=`basename ${j} .out`_thumb.png
        
        echo " [${fname_thumb}] unit:${cunit[${cnt}]},cbar_min= ${cvmin[${cnt}]}, cbar_max= ${cvmax[${cnt}]}"
        
        #-- visualize (output png with relief background for thumbnail)
        bash ${D_API}/prepost/view_thumbnail.sh --script ${D_API}/prepost/geotiff2png_thumb.py --in "${dummy}/${fname_view}" --epsg ${epsg_utm} --relief ${basemap} --unit ${cunit[${cnt}]} --vmin ${cvmin[${cnt}]} --vmax ${cvmax[${cnt}]} --path ${target} --odir "${dummy}" --oname "${fname_thumb}"
          
        #-- add new png in antecedent(=parent) gif
        xx=`ls "${parent_dir}" | grep "fdepthmax_thumb.gif" | sort -r | head -n 1`

        if [ ! -z "${xx}" ]; then
            bash ${D_API}/prepost/make_gif.sh --ante "${parent_dir}/${xx}" --delay "120" --add "${dummy}/${fname_thumb}" --odir "${target}" --oname "fdepthmax_thumb.gif"
        else
            bash ${D_API}/prepost/make_gif.sh --ante "null" --delay "120" --add "${dummy}/${fname_thumb}" --odir "${target}" --oname "fdepthmax_thumb.gif"
        fi
        
    fi
    
    echo "  SET JSON"
    
    #--set json file for WEB-GIS
    # set boolean
    if [ ${cshow[${cnt}]} -eq 1 ]; then
        show="true"
    else
        show="false"
    fi
    # write contents information (time-series/static)
    if [ ${cdraw[${cnt}]} -eq 1 -a ${cseries[${cnt}]} -eq 1 ]; then
        xx="${sim_ID}_${i}"
        yy="${sim_ID}_${i}@_[hhh]h[mm]m[ss]s"
        
        bash ${D_API}/prepost/add_jsonfile_layer.sh --target ${jsonfile} --name "${cname[${cnt}]}" --olayer "${xx}" --mslayer "${yy}" --ltype "timeSeries" --step ${list_num} --interval "60" --show ${show}
    
    elif [ ${cdraw[${cnt}]} -eq 1 -a ${cseries[${cnt}]} -eq 0 ];then
        xx="${sim_ID}_${i}"
        
        bash ${D_API}/prepost/add_jsonfile_layer.sh --target ${jsonfile} --name "${cname[${cnt}]}" --olayer "${xx}" --mslayer "${xx}@" --ltype "static" --step "null" --interval "60" --show ${show}
    fi
    
    echo
    echo "  OK: SET JSON"
    echo
    
    cnt=$((cnt+1))
done

#-- end map file
echo "END" >> ${mapfile}
#-- end json file
sed -i ${jsonfile} -e '$','$'d
sed -i ${jsonfile} -e '$a\  }'
echo "]" >> ${jsonfile}


echo "[UPDATE DEM]"

xx=`ls ${target} | grep _depo@ | grep _raw.tif | LANG=C sort -r | head -n 1`

if [ -e "${initialcon}" ]; then
    
    if [ -e "${target}/${xx}" ]; then
        # expand size from parent domain to original domain for calculation
        bash ${D_API}/gis/clip_dem.sh --in "${target}/${xx}" --west ${w0} --north ${n0} --east ${e0} --south ${s0} --target ${dummy}/dem_add.tif
        
        # (parent's elevation before calculation) + (this event's deposition thickness)
        gdal_calc.py -A ${initialcon} -B ${dummy}/dem_add.tif --outfile=${target}/next_initial_condition.tif --calc="A+B" 
        
        echo "   found parent event's initial condition. updated next initial condition by this event result"
    else
        rsync -a ${initialcon} ${target}/next_initial_condition.tif
        echo "   found parent event's initial condition. no-updated next initial condition due to no result of this event" 
    fi
    
else
    
    if [ -e "${target}/${xx}" ]; then
        # expand size from parent domain to original domain for calculation
        bash ${D_API}/gis/clip_dem.sh --in "${target}/${xx}" --west ${w0} --north ${n0} --east ${e0} --south ${s0} --target ${dummy}/dem_add.tif
        
        # (initial elevation) + (this event's deposition thickness)
        gdal_calc.py -A ${DEM} -B ${dummy}/dem_add.tif --outfile=${target}/next_initial_condition.tif --calc="A+B" 
        echo "   cannot find parent event's initial condition. updated next initial condition by this event result"
    else
        rsync -a ${DEM} ${target}/next_initial_condition.tif
        echo "   cannot find parent event's initial condition. no-updated next initial condition due to no result of this event" 
    fi
fi


echo "  OK: management results"
#--------------------------------------------------------------------

# ******************************************************************
#   register database
# ******************************************************************
echo "[PROC END] registration information to logical Databae"

bash ${D_API}/db/psql_result.sh --project ${project} --chain ${target} --accvol ${accvol} --status 0
#-------------------------------------------------------------------- 

end_batch=`date "+%Y%m%d %H:%M.%S"`
echo "[END BATCH @ ${end_batch}] (start_batch @ ${start_batch})"


if [ -e "$dummy" ]; then
    tar cfvz $dummy.tar.gz $dummy
    rm -rf $dummy
fi

if [ -e "${target}/.calc.err" ]; then
    echo "NG"
    touch "${target}/.proc.err"
else
    echo "OK"
    touch "${target}/.state.done"
fi

#--- set permission
chmod 777 ${target}/*

exit 0


