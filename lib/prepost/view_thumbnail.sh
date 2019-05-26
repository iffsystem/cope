#!/bin/bash


#-- directory path at top
RPATH=$(cd $(dirname $0)/../../;pwd)


#-- read filesystem
. ${RPATH}/config/filesystem.conf


#--- read options
OPT=`getopt -o " " -l script: -l in: -l epsg: -l relief: -l unit: -l vmin: -l vmax: -l path: -l odir: -l oname:  -- "$@"`
if [ "$?" -ne 0  -o "`echo ${OPT}`" == "--" ]; then
      echo "Usage: $0 "
      echo "      [--script=<path+file>] (python script)"
      echo "      [--in=<path+file>] (geotiff)"
      echo "      [--epsg=value] (WGS84-LatLon)"
      echo "      [--relief=<path+file>] (relief map for background : RGBA geotiff : WGS84-LatLon)"
      echo "      [--unit=character] (unit for legend of colorbar)"
      echo "      [--vmin=value] (for colorbar range)"
      echo "      [--vmax=value] (for colorbar range)"
      echo "      [--path=<path>] (chain path)"
      echo "      [--odir=<path>] (output)"
      echo "      [--oname=<file>] (output: RGBA geotiff without background)"
      exit
fi

eval set -- "$OPT"

until [ "$1" == "--" ]; do

      case $1 in
            --script)
                  script=$2
                  ;;
            --in)
                  infile=$2
                  ;;
            --epsg)
                  epsg=$2
                  ;;
            --vmin)
                  vmin=$2
                  ;;
            --vmax)
                  vmax=$2
                  ;;
            --relief)
                  relief=$2
                  ;;
            --unit)
                  unit=$2
                  ;;
            --path)
                  chainpath=$2
                  ;;
            --odir)
                  odir=$2
                  ;;
            --oname)
                  oname=$2
                  ;;
      esac
      shift
done


fname=`basename ${infile} .tif`
dname=`dirname ${infile}`

xx=`ls ${script}`
yy=`ls ${infile}`
if [ ! -n "${xx}" -o ! -n "${yy}" ]; then
    echo
    echo "ERROR in $0"
    echo ${xx}
    echo ${yy}
    echo
fi


#--- output png of visualized data on relief & its colorbar
python ${script} ${infile} -dpi 600 -unit "[${unit}]" -vmin ${vmin} -vmax ${vmax} -relief ${relief}

xx=`ls ${dname}/${fname}_relief.png`
yy=`ls ${dname}/colorbar.png`

if [ ! -n "${xx}" -o ! -n "${yy}" ]; then
    echo
    echo "ERROR in $0"
    echo ${xx}
    echo ${yy}
    echo
fi

#--- resize
convert -quality 100 -resize 250x ${dname}/${fname}_relief.png ${dname}/${fname}_resized.png

#--- change size of colorbar
convert -quality 100 -resize 250x ${dname}/colorbar.png ${dname}/colorbar_resized.png

#--- append data image and colorbar
montage -quality 100 -tile 1x2 -geometry +0+0 ${dname}/colorbar_resized.png ${dname}/${fname}_resized.png ${dname}/${fname}_montaged.png

#--- add chains information on the left side of the thumbnail
path=`echo ${chainpath} | awk -F'/chain/' '{print $2}' | tr '/' '\n'`


convert -density 250 -background white -splice 120x0 ${dname}/${fname}_montaged.png ${dname}/${fname}_montaged2.png

convert -density 250 -font Helvetica -pointsize 4 -fill black -gravity north-west -annotate +7+7 "[Preview Chains]" ${dname}/${fname}_montaged2.png ${dname}/${fname}_montaged2.png

yy=25
for i in ${path}
do
    
    convert -density 250 -font Helvetica -pointsize 3.5 -fill black -gravity north-west -annotate +7+${yy} "${i}" ${dname}/${fname}_montaged2.png ${dname}/${fname}_montaged2.png
    
    yy=$((yy+15))
done


#--- rename 
rsync -a ${dname}/${fname}_montaged2.png ${odir}/${oname}

#--- clean
rm -f ${dname}/${fname}.png ${dname}/${fname}_resized.png
rm -f ${dname}/colorbar.png ${dname}/colorbar_resized.png
rm -f ${dname}/${fname}_montaged2.png
rm -f ${dname}/${fname}_montaged.png

exit 0


