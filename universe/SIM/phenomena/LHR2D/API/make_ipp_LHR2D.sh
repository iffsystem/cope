#!/bin/bash


#-- directory path at top
RPATH=$(cd $(dirname $0)/../../../../../;pwd)


#-- read filesystem
. ${RPATH}/config/filesystem.conf



#--- read options
OPT=`getopt -o " " -l mx: -l my: -l width: -l direction: -l riverwidth: -l slope: -l out:  -- "$@"`
if [ "$?" -ne 0  -o "`echo ${OPT}`" == "--" ]; then
      echo "Usage: $0 "
      echo "      [--mx=value] (int)"
      echo "      [--my=value] (int)"
      echo "      [--width=value] (int)"
      echo "      [--direction=value]  (int;0-359)"
      echo "      [--riverwidth=value] (river width at inflow [m])"
      echo "      [--slope=value] (slope angle at inflow [degree])"
      echo "      [--out=<path+fname>]"
      exit
fi

eval set -- "$OPT"

until [ "$1" == "--" ]; do

      case $1 in
            --mx)
                  mx=$2
                  ;;
            --my)
                  my=$2
                  ;;
            --width)
                  wid=$2
                  ;;
            --direction)
                  dir=$2
                  ;;
            --riverwidth)
                  rivwid=$2
                  ;;
            --slope)
                  slope=$2
                  ;;
            --out)
                  out=$2
                  ;;
      esac
      shift
done

mxnum=`awk 'BEGIN {xx='${wid}';yy='${dir}';pi=atan2(0,-0);print int(xx*sin(yy*pi/180.0))}'`
mynum=`awk 'BEGIN {xx='${wid}';yy='${dir}';pi=atan2(0,-0);print int(xx*cos(yy*pi/180.0))}'`

slu=`echo ${slope}|awk 'pi=atan2(0,-0) {print sin($1*pi/180.0)/cos($1*pi/180.0)}'`


ax=`echo ${mxnum} | awk '{print sqrt($1*$1)}'`
ay=`echo ${mynum} | awk '{print sqrt($1*$1)}'`

dx=`awk 'BEGIN {xx='${wid}';yy='${dir}';pi=atan2(0,-0);print int(0.5*xx*sin(yy*pi/180.0))}'`
dy=`awk 'BEGIN {xx='${wid}';yy='${dir}';pi=atan2(0,-0);print int(0.5*xx*cos(yy*pi/180.0))}'`
dx=`echo ${dx} | awk '{print sqrt($1*$1)}'`
dy=`echo ${dy} | awk '{print sqrt($1*$1)}'`


echo -n > ${out}
cnt=0
px=0
py=0


if [ ${mxnum} -eq 0 -a ${mynum} -eq 0 ]; then
    px=${mx}
    py=${my}
    echo "${px} ${py}" >> ${out}
        
    cnt=$((cnt+1))
    
elif [ ${ax} -ge ${ay} ]; then
    
    if [ ${mxnum} -gt 0 ]; then
    
        mx=$((mx-dx))
        
        if [ ${mynum} -gt 0 ]; then
            my=$((my-dy)) 
        else
            my=$((my+dy))
        fi
        
        for i in `seq 1 ${mxnum}`
        do
            
            xx=`awk 'BEGIN {num='${i}';yy='${dir}';pi=atan2(0,-0);print int(num*cos(yy*pi/180.0))}'`
            
            px=$((${mx}+${i}-1))
            py=$((${my}+${xx}))
            echo "${px} ${py}" >> ${out}
                
            cnt=$((cnt+1))              
        done
    else
        
        mx=$((mx+dx))
        
        if [ ${mynum} -gt 0 ]; then
            my=$((my-dy)) 
        else
            my=$((my+dy))
        fi
        
        for i in `seq -1 -1 ${mxnum}`
        do
            xx=`awk 'BEGIN {num='${i}';yy='${dir}';pi=atan2(0,-0);print int(num*cos(yy*pi/180.0))}'`
            
            px=$((${mx}+${i}+1))
            py=$((${my}-${xx}))
            echo "${px} ${py}" >> ${out}
                
            cnt=$((cnt+1))              
        done 
    fi
else
    if [ ${mynum} -ge 0 ]; then
        
        my=$((my-dy))
        
        if [ ${mxnum} -gt 0 ]; then
            mx=$((mx-dx)) 
        else
            mx=$((mx+dx))
        fi
        
        for i in `seq 1 ${mynum}`
        do
            yy=`awk 'BEGIN {num='${i}';yy='${dir}';pi=atan2(0,-0);print int(num*sin(yy*pi/180.0))}'`
            
            px=$((${mx}+${yy}))
            py=$((${my}+${i}-1))
            echo "${px} ${py}" >> ${out}
                
            cnt=$((cnt+1))              
        done
    else
        my=$((my+dy))
        
        if [ ${mxnum} -gt 0 ]; then
            mx=$((mx-dx)) 
        else
            mx=$((mx+dx))
        fi
        
        for i in `seq -1 -1 ${mynum}`
        do
            yy=`awk 'BEGIN {num='${i}';yy='${dir}';pi=atan2(0,-0);print int(num*sin(yy*pi/180.0))}'`
            
            px=$((${mx}+${yy}))
            py=$((${my}+${i}+1))
            echo "${px} ${py}" >> ${out}
                
            cnt=$((cnt+1))              
        done
    fi
fi


sed -i ${out} -e "1i ${cnt} ${dir} ${rivwid} ${slu}  :point_num, flow direction [deg.]"

exit 0
