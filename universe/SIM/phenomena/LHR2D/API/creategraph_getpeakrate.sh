#!/bin/bash

#-- directory path at top
RPATH=$(cd $(dirname $0)/../../../../../;pwd)


#-- read filesystem
. ${RPATH}/config/filesystem.conf


paramlist=$1

#---- set variables from file
. ${paramlist}

odir=`dirname ${paramlist}`

mkdir -p ${odir}


trap '[[ "$dummy" ]] && rm -rf $dummy && echo -1;exit' ERR 1 2 3 15

dummy=$(mktemp -d ${odir}/`basename $0`_XXXXX)


fname1=hydro
fname2=hyeto

#--- clean tmp
rm -f ${odir}/${fname1}_*

#------------------------------
# 
# mode=0 : input volume, wave shape, peak-rate and peak-time uses for hydrograph 
#
# mode=1 : input volume, wave shape, peak-rate and peak-time uses for hydetograph
#              hydrograph is ecaluated by input area and hyetograph by Nakayasu's unit graph method
#
#------------------------------

mode=0
if [ ! "${drainagearea}" == "xxx" -a ! "${utime1}" == "xxx" -a ! "${utime03}" == "xxx" ]; then
    # make hydrograph from drainage area and rainfall intensity
    mode=1
fi

if [ ${type} -eq 1 ]; then
    # triangle
    shape=1
elif [ ${type} -eq 2 ]; then
    # rectangle
    shape=2
fi


if [ "${runoffrate}" == "xxx" ]; then
    runoffrate=1.0
fi


function PLT_rec(){
    
    local fname=$1
    
    local range_time=$2
    local range_val=$3
    
    #--- draw figure
    gnuplot <<EOF
    set terminal postscript eps color enhanced "Helvetica" 18
    set output "/dev/null"
    set nokey
    set xzeroaxis
    set xrange [0:${range_time}]
    set yrange [0:${range_val}]
    set xlabel "Duration [min]" offset 0,0 font "Helvetica,22"
    set ylabel "Discharge Rate [m^3/sec]" offset 1,0 font "Helvetica,22"
    set mxtics 5
    set mytics 5
    #set xtics add ("${range_time}" "${range_time}")
    #set ytics add ("${range_val}" "${range_val}")
    set grid mxtics lw 0.1 lt -1 noxtics
    set grid mytics lw 0.1 lt -1 noytics
    set grid xtics lw 0.5 lt -1
    set grid ytics lw 0.5 lt -1
    plot    '${dummy}/${fname}.d' using 1:2:3 w boxes fs solid 1 border 0 lw 0 lt 1 lc rgb "red" noti              
    set output "${dummy}/${fname}.eps"
    replot
EOF

}

function PLT_tri(){
    
    local fname=$1
    
    local range_time=$2
    local range_val=$3
    
    #--- draw figure
    gnuplot <<EOF
    set terminal postscript eps color enhanced "Helvetica" 18
    set output "/dev/null"
    set nokey
    set xzeroaxis
    set xrange [0:${range_time}]
    set yrange [0:${range_val}]
    set xlabel "Duration [min]" offset 0,0 font "Helvetica,22"
    set ylabel "Discharge Rate [m^3/sec]" offset 1,0 font "Helvetica,22"
    set mxtics 5
    set mytics 5
    #set xtics add ("${range_time}" "${range_time}")
    #set ytics add ("${range_val}" "${range_val}")
    set grid mxtics lw 0.1 lt -1 noxtics
    set grid mytics lw 0.1 lt -1 noytics
    set grid xtics lw 0.5 lt -1
    set grid ytics lw 0.5 lt -1
    plot    '${dummy}/${fname}.d' using 1:2 w filledcurves x1 lw 0 lt 1 lc rgb "red" noti
    set output "${dummy}/${fname}.eps"
    replot
EOF

}



echo -n > ${odir}/DEBUG

echo ${paramlist} &>> ${odir}/DEBUG
echo "PROJECT="${project} &>> ${odir}/DEBUG

if [ ${mode} -eq 0 ]; then
    if [ ${shape} -eq 1 ]; then
        # triangle
        
        if [ "${vol}" == "xxx" ]; then
            vol=`echo ${duration} ${peakrate} | awk '{printf (0.5*$1*$2*60.0)}'`
        fi
        
        if [ "${duration}" == "xxx" ]; then
            dur=`echo ${vol} ${peakrate} | awk '{printf (2.0*$1/$2/60.0)}'`
        else
            dur=${duration} # min    
        fi
        
        if [ "${peakrate}" == "xxx" ]; then
            peakrate=`echo ${vol} ${dur} | awk '{printf (2.0*$1/$2/60.0)}'`
        fi
        
        
        
        # graph range
        tmax=`echo ${dur} | awk '{printf ("%.5f",$1 * 1.3)}'`
        qmax=`echo ${peakrate} | awk '{printf ("%.5f",$1 * 1.5)}'`
        
        # set hydro profile
        echo -n > ${dummy}/${fname1}.d
        
        echo "0 0" >> ${dummy}/${fname1}.d
        echo "${peaktime} ${peakrate}" >> ${dummy}/${fname1}.d
        echo "${dur} 0" >> ${dummy}/${fname1}.d
        
        # draw hydro and output its image
        PLT_tri ${fname1} ${tmax} ${qmax}
        
        
    elif [ ${shape} -eq 2 ]; then
        # rectangule
        
        if [ "${vol}" == "xxx" ]; then
            vol=`echo ${duration} ${peakrate} | awk '{printf ($1*$2*60.0)}'`
        fi
        
        if [ "${duration}" == "xxx" ]; then
            dur=`echo ${vol} ${peakrate} | awk '{printf ($1/$2/60.0)}'`
        else
            dur=${duration} # min    
        fi
        
        if [ "${peakrate}" == "xxx" ]; then
            peakrate=`echo ${vol} ${dur} | awk '{printf ($1/$2/60.0)}'`
        fi
        
        
        # graph range
        tmax=`echo ${dur} | awk '{printf ("%.5f",$1 * 1.3)}'`
        qmax=`echo ${vol} ${dur} | awk '{printf ("%.5f",$1/$2/60.0 * 1.5)}'`
        
        # set hydro profile
        echo -n > ${dummy}/${fname1}.d
        xx=`echo ${dur} | awk '{printf ($1 * 0.5)}'`    
        echo "${xx} ${peakrate} ${dur}" >> ${dummy}/${fname1}.d
        
        # draw hydro and output its image
        PLT_rec ${fname1} ${tmax} ${qmax}
    fi
    
elif [ ${mode} -eq 1 ]; then

    # draw hydrograph from rainfall intensity and drainage area by using Nakayasu
    
    utime1=`echo ${utime1} | awk '{printf ($1/60.0)}'` # convert min to hour
    utime03=`echo ${utime03} | awk '{printf ($1/60.0)}'` # convert min to hour
    
    if [ ${shape} -eq 1 ]; then
        # triangle
        
        if [ "${vol}" == "xxx" ]; then
            vol=`echo ${duration} ${peakrate} | awk '{printf (0.5*$1*$2/60.0)}'`    # mm
        fi
        
        if [ "${duration}" == "xxx" ]; then
            dur=`echo ${vol} ${peakrate} | awk '{printf (2.0*$1/$2/60.0)}'`     # min
        else
            dur=${duration}
        fi
        
        if [ "${peakrate}" == "xxx" ]; then
            peakrate=`echo ${vol} ${dur} | awk '{printf (2.0*$1/$2*60.0)}'` # mm/h
        
        elif [ ! "${vol}" == "xxx" -a ! "${peakrate}" == "xxx" ]; then
            peakrate=`echo ${vol} ${dur} | awk '{printf (2.0*$1/$2*60.0)}'` # mm/h
        fi
        
        
        itr=`echo ${dur} | awk '{printf int($1)}'` # int(min)
        
        peakit=`echo ${peaktime} | awk '{printf int($1)}'` # int(min)
        
        if [ ${peakit} -gt ${itr} ]; then
            peakit=${itr}
        fi
        
        # set hyeto profile
        echo -n > ${dummy}/${fname2}.d
        echo "${dur} ${drainagearea} ${runoffrate}" >> ${dummy}/${fname2}.d
        echo "${utime1}" >> ${dummy}/${fname2}.d
        echo "${utime03}" >> ${dummy}/${fname2}.d
        echo "---" >> ${dummy}/${fname2}.d
        
        for i in `seq 0 ${itr}`
        do
            xx=0.0
            if [ ${i} -eq 0 -a ${peakit} -eq 0 ]; then
                xx=${peakrate}
                
            elif  [ ${i} -eq ${itr} -a ${peakit} -eq ${itr} ]; then
                xx=0.0
            elif [ ${i} -le ${peakit} ]; then
                xx=` echo ${peakrate} ${peaktime} ${i} | awk '{printf ($1/$2*$3)}'`
            else
                
                aa=` echo ${peakrate} ${peakit} ${itr} | awk '{printf ($1/($2-$3))}'`
                xx=` echo ${peakrate} ${peakit} ${i} ${aa} | awk '{printf ($4*$3-$4*$2+$1)}'`
                
                bool=`echo ${xx} | awk '{if ($1 <= 0.0) res=1;else res=0;print res}'`
                if [ ${bool} -eq 1 ]; then
                    xx=0.0
                fi
            fi
            
            echo "${xx}" >> ${dummy}/${fname2}.d
            
        done
        
        
        rsync -a ${D_ENGINE}/LHR2D/API/nakayasu/ ${dummy}/
        
        cd ${dummy}
        
        #--- calc hydro by Nakayasu's unit graph
        make clean &>> ${odir}/DEBUG
        make &>> ${odir}/DEBUG
        ./exec &>> ${odir}/DEBUG
        
        #--- draw
        bash view_hydro.sh . hydro ${peakrate} &>> ${odir}/DEBUG
        
    elif [ ${shape} -eq 2 ]; then
        # rectangule
        
        if [ "${vol}" == "xxx" ]; then
            vol=`echo ${duration} ${peakrate} | awk '{printf ($2*$1/60.0)}'` # mm
        fi
        
        if [ "${duration}" == "xxx" ]; then
            dur=`echo ${vol} ${peakrate} | awk '{printf ($1/$2/60.0)}'` # min
        else
            dur=${duration}
        fi
        
        if [ "${peakrate}" == "xxx" ]; then
            peakrate=`echo ${vol} ${dur} | awk '{printf ($1/$2*60.0)}'` # mm/h
        
        elif [ ! "${vol}" == "xxx" -a ! "${peakrate}" == "xxx" ]; then
            peakrate=`echo ${vol} ${dur} | awk '{printf ($1/$2*60.0)}'` # mm/h
        fi
        
        itr=`echo ${dur} | awk '{printf int($1)}'` # int(min)
        
        echo $vol $dur $peakrate &>> ${odir}/DEBUG

        # set hyeto profile
        echo -n > ${dummy}/${fname2}.d
        echo "${dur} ${drainagearea} ${runoffrate}" >> ${dummy}/${fname2}.d
        echo "${utime1}" >> ${dummy}/${fname2}.d
        echo "${utime03}" >> ${dummy}/${fname2}.d
        echo "---" >> ${dummy}/${fname2}.d
        
        for i in `seq 0 ${itr}`
        do
            xx=${peakrate}
            
            echo "${xx}" >> ${dummy}/${fname2}.d
            
        done
        
        rsync -a ${D_ENGINE}/LHR2D/API/nakayasu/ ${dummy}/ &>> ${odir}/DEBUG
        
        cd ${dummy}
        
        #--- calc hydro by Nakayasu's unit graph
        make clean &>> ${odir}/DEBUG
        make &>> ${odir}/DEBUG
        ./exec &>> ${odir}/DEBUG
        
        
        #--- draw
        bash view_hydro.sh . hydro ${peakrate} &>> ${odir}/DEBUG
        
    fi
    
fi

#get peak rate
xx=`cat ${odir}/DEBUG | grep "Peak rate" |awk -F'[=[]' '{print $2}'`

echo "$xx" 2>&1 | tee -a ${odir}/DEBUG



if [[ "$dummy" ]] ;then    
    rm -rf $dummy
fi

exit 0


