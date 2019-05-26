#!/bin/bash


dname=$1
dfig=$2

range_rain=`echo $3 | awk '{printf ("%.5e",$1 * 5)}'`


file=`ls ${dname} | grep hydro.out$`

    
start=`cat ${dname}/${file} | awk 'NR==2 {print $1}'`
end=`cat ${dname}/${file} | awk 'END {print $1}'`

peak=`cat ${dname}/${file} | awk 'NR==1 {print $1}'`

range_val=`echo ${peak} | awk '{printf ("%.5e",$1 * 1.5)}'`
range_time=`echo ${end} | awk '{printf ("%.5e",$1 * 1.3)}'`

echo $start $end $peak $range_val $range_time

epsname=`basename ${file} .out`.eps


gnuplot << __EOF__
set terminal postscript eps color enhanced "Helvetica" 16
set output "/dev/null"
set nokey
#set datafile separator ','
#set xdata time
#set timefmt "%Y-%m-%d %H:%M"
set xtics rotate by 50 offset -2,-1.2
set ytics
set y2tics
set format x "%4.0f"
set format y "%3.0f"
set format y2 "%3.0f"
set xrange ["${start}":"${end}"]
set yrange [0:${range_val}]
set y2range [${range_rain}:0]
set mxtics 5
set mytics 5
#set xtics add ("${range_time}" "${range_time}")
#set ytics add ("${range_val}" "${range_val}")
#set y2tics add ("${range_rain}" "${range_rain}")
set grid xtics mxtics lw 0.1 lt -1 #noxtics
set grid ytics mytics lw 0.1 lt -1 #noytics
set xlabel "Duration [min]" font "Helvetica,22"
set ylabel "Discharge rate (red) [m^3/sec]" font "Helvetica,22"
set y2label "Rainfall Intensity (blue) [mm/h]" font "Helvetica,22"
set size 1.2,1.0
plot "${dname}/${file}" every ::1 using 1:3 w filledcurves x2 lt 1 lc rgb"blue" axes x1y2
replot "${dname}/${file}" every ::1 using 1:2 w filledcurves x1 lt 1 lc rgb"red" axes x1y1
set output "${dname}/${epsname}"
    replot
__EOF__
    
   

exit 0
