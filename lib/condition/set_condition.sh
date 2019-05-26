#!bin/bash


#-- directory path at top
RPATH=$(cd $(dirname $0)/../../;pwd)

#-- read filesystem
. ${RPATH}/config/filesystem.conf



# select directory
function selectDir() {

    local input2
    input2=0

    sdir=$1
    stype=$2
    dget=$3



    get=$(ls -p ${sdir}  | grep "/" | cut -f1  -d'/' | ${D_API}/condition/sentaku/sentaku)
    xx=${sdir}/$get

    if [ -e "${xx}" ]; then
        dget=${xx}
        echo "  OK"
    else
        echo "  !!! ERROR : directory is not existence !!!"
    fi

    return
}

function selectKey() {

    local keys
    local item

    keys=("$@")

    PS3="   Select item >> "
    select item in ${keys[@]}
    do
        if [ "${REPLY}" = "q" ]; then
            exit -1
        fi
        if [ -z "$REPLY" ] ; then
            continue
        fi
        break
    done

    echo $REPLY
}


function getkeys() {
    local len=$1
    local ifile=$2

    list=`cat $ifile | jq -cr 'paths'| awk -F'[[]]' '{print}' | sed -e 's/,/./g' -e 's/\[//g' -e 's/\]//g'`

    local unset array1
    local unset array9

    cnt=1
    cnt1=1
    cnt9=1
    for i in $list
    do
        cnt=$((cnt+1))

        xx=`echo $i | cut -d '.' -f $((len+1))-`

        val=`cat  $ifile | jq -cr '.'${i}''`

        if [[ "$val" =~ ^[0-9]+$ ]];then
            if [ $val -eq 1 ]; then
                array1[$cnt1]="$val;$xx;[necessary]"
                cnt1=$((cnt1+1))
            elif [ $val -eq 9 ]; then
                array9[$cnt9]="$val;$xx;[option]"
                cnt9=$((cnt9+1))
            fi
        else
            :
        fi

    done

    for i in `seq 1 ${#array1[@]}`
    do
        echo ${array1[$i]}
    done
    for i in `seq 1 ${#array9[@]}`
    do
        echo ${array9[$i]}
    done
}

function setDEMvalue() {
    local ddem=$1
    local target=$2

    extent=`cat $ddem | jq -c '.extent' 2>/dev/null`
    resol=`cat $ddem | jq -c '.resolution.utm' 2>/dev/null`
    finfo=`cat $ddem | jq -c '.file' 2>/dev/null`

    cp -f ${target} ${target}.bak

    OIFS=$IFS
    IFS=$'\n'

    cat ${target} | jq -r '.field.condition.dem.file |= '${finfo}'' > ${dumdir}/dummy.json
    chk1=$?
    cat $dumdir/dummy.json > ${target}
    chk2=$?

    IFS=$OIFS

    #-- check necessary setting
    if [ $chk1 -ne 0 -a $chk2 -ne 0 ]; then
        echo " error : set $target"
        :
    else
        echo " set OK"
    fi
    
    OIFS=$IFS
    IFS=$'\n'

    cat ${target} | jq -r '.field.condition.dem.extent |= '${extent}'' > ${dumdir}/dummy.json
    chk1=$?
    cat $dumdir/dummy.json > ${target}
    chk2=$?

    IFS=$OIFS

    #-- check necessary setting
    if [ $chk1 -ne 0 -a $chk2 -ne 0 ]; then
        echo " error : set $target"
        :
    else
        echo " set OK"
    fi

    OIFS=$IFS
    IFS=$'\n'

    cat ${target} | jq -r '.field.condition.dem.resolution |= '${resol}'' > ${dumdir}/dummy.json
    chk1=$?
    cat $dumdir/dummy.json > ${target}
    chk2=$?

    IFS=$OIFS
    #-- check necessary setting
    if [ $chk1 -ne 0 -a $chk2 -ne 0 ]; then
        echo " error : set $target"
        :
    else
        echo " set OK"
    fi

}

function chkExtent() {
    local vv=$1
    local extent=$2

    lon1=`echo $vv | jq -r '."lon-NW"."value"'`
    lat1=`echo $vv | jq -r '."lat-NW"."value"'`
    lon2=`echo $vv | jq -r '."lon-SE"."value"'`
    lat2=`echo $vv | jq -r '."lat-SE"."value"'`

    dlon1=`cat $extent | jq -r '."extent"."lon-NW"."value"'`
    dlat1=`cat $extent | jq -r '."extent"."lat-NW"."value"'`
    dlon2=`cat $extent | jq -r '."extent"."lon-SE"."value"'`
    dlat2=`cat $extent | jq -r '."extent"."lat-SE"."value"'`

    x1=`echo ${lon1} ${dlon1} | awk '{if ($1<$2) {print 1} else {print 0}}'`
    y1=`echo ${lat1} ${dlat1} | awk '{if ($1>$2) {print 1} else {print 0}}'`
    x2=`echo ${lon2} ${dlon2} | awk '{if ($1>$2) {print 1} else {print 0}}'`
    y2=`echo ${lat2} ${dlat2} | awk '{if ($1<$2) {print 1} else {print 0}}'`


    if [ $x1 -ne 0 -o $y1 -ne 0 -o $x2 -ne 0 -o $y2 -ne 0 ]; then
        # error
        echo 1
    else
        # OK
        echo 0
    fi
}

function chkPoint() {
    local vv=$1
    local extent=$2

    lon1=`echo $vv | jq -r '."lon"."value"'`
    lat1=`echo $vv | jq -r '."lat"."value"'`

    dlon1=`cat $extent | jq -r '."extent"."lon-NW"."value"'`
    dlat1=`cat $extent | jq -r '."extent"."lat-NW"."value"'`
    dlon2=`cat $extent | jq -r '."extent"."lon-SE"."value"'`
    dlat2=`cat $extent | jq -r '."extent"."lat-SE"."value"'`

    x1=`echo ${lon1} ${dlon1} | awk '{if ($1<$2) {print 1} else {print 0}}'`
    y1=`echo ${lat1} ${dlat1} | awk '{if ($1>$2) {print 1} else {print 0}}'`
    x2=`echo ${lon1} ${dlon2} | awk '{if ($1>$2) {print 1} else {print 0}}'`
    y2=`echo ${lat1} ${dlat2} | awk '{if ($1<$2) {print 1} else {print 0}}'`

    if [ $x1 -ne 0 -o $y1 -ne 0 -o $x2 -ne 0 -o $y2 -ne 0 ]; then
        # error
        echo 1
    else
        # OK
        echo 0
    fi
}




echo "---------------------------"
echo "|   SET condition file    |"
echo "---------------------------"

echo "#----  SELECT MODE"
sleep 0.5
mtype=("create_condition" "edit_condition")
mode=${mtype[0]}

echo $mode


echo "#----  SELECT field"
sleep 1
unset dget
selectDir ${D_FIELD} "field" $dget
dfield=$dget

echo $dfield

echo "#----  SELECT date"
sleep 1
unset dget
selectDir $dfield "date" $dget
ddate=$dget

echo $ddate


# set temporal work directory
unset dumdir
trap 'sleep 1;[[ "$dumdir" ]] && rm -rf $dumdir;echo " EXIT";exit' 0 1 2 3 15
dumdir=$(mktemp -d $ddate/tmp/`basename $0`_XXXXXXX)


echo "#----  SELECT phenomena"
sleep 1
unset dget
selectDir ${D_ENGINE} "phenomena" $dget
dpheno=$dget
ptype=`basename ${dpheno}`

echo $dpheno

# set phenomena condition
if [ ! -e "${dpheno}/template/phenomena.json" ]; then
    echo " cannot find ${dpheno}/template/phenomena.json"
    echo " this file is necessary"
    echo " quit"
    exit 1
fi
mkdir -p $ddate/condition/phenomena/${ptype}


#-- check same setting file
clist=`ls -F ${ddate}/condition/phenomena/${ptype}/ | grep .json`
end=0
if [ -z "${clist}" ]; then
    rsync -a ${dpheno}/template/phenomena.json ${ddate}/condition/phenomena/${ptype}/phenomena_0.json
    end=1
else
    for i in $clist
    do
        xx=`diff ${ddate}/condition/phenomena/${ptype}/$i ${dpheno}/template/phenomena.json`
        if [ -z "${xx}" ]; then
            echo " same condition file of phenomena is already existed. continue..."
            sleep 1.5
            end=1
            break 1
        fi
    done
fi

if [ $end -eq 0 ]; then
    #-- save file with number increment
    xx=`ls -F ${ddate}/condition/phenomena/${ptype}/ | grep .json | LANG=C sort -t _ -n -k 2 | awk 'END{print}' | awk -F'[_.]' '{print $2}'`
    if [ -z "${xx}" ]; then
        xx=0
    else
        xx=$((xx+1))
    fi

    rsync -a ${dpheno}/template/phenomena.json ${ddate}/condition/phenomena/${ptype}/phenomena_${xx}.json
fi



echo "#----  SET Condition"


if [ ! -e "${dpheno}/template/phenomena.json" ]; then
    echo " cannot find ${dpheno}/template/phenomena.json"
    echo " this file is necessary"
    echo " quit"
    exit 1
fi

ftemp=$dumdir/phenomena.json
rsync -a ${dpheno}/template/phenomena.json $ftemp


keychain0='.field.condition.input'
key0=${keychain0##*.}
nkey0=`echo $keychain0|awk -F[.] '{print NF}'`

# get keys which can set value from phenomena.json
keylist=($(getkeys ${nkey0} ${ftemp}))


# select condition type
echo " Select condition type"
sleep 1

OIFS=$IFS
IFS=$'\n'
echo "${keylist[*]}" > $dumdir/xx.d
IFS=$OIFS


cat $dumdir/xx.d | LANG=C sort -t \" -k 2,1 > $dumdir/xx2.d

ctype=($(cat $dumdir/xx2.d | sed -e 's/"//g' | awk -F'[;.]' '{print $2}' | LANG=C sort | uniq))

for i in `seq 0 $((${#ctype[@]}-1))`
do
    # set file of keys list corresponding to condition type
    cat $dumdir/xx2.d | grep ";.${ctype[$i]}." > $dumdir/${ctype[$i]}.list

    # copy template file into work directory
    rsync -a ${dpheno}/template/${ctype[$i]}.json $dumdir/${ctype[$i]}.json

    # if condition type is topography, set default value from DEM
    if [ "${ctype[$i]}" == "topography" ]; then
        setDEMvalue ${ddate}/condition/topography/DEM/geoinfo.json $dumdir/${ctype[$i]}.json
    fi
done


if [ "${mode}" == "${mtype[0]}" ]; then
    #--- create mode

    #--- select key and set value
    end1=0

    while [ ${end1} -eq 0 ];
    do
        # select condition
        choise=$(echo ${ctype[@]} | ${D_API}/condition/sentaku/sentaku)

        end2=0

        while [ ${end2} -eq 0 ];
        do

            # select key
            echo " select key"
            sleep 1
            get=$(cat $dumdir/${choise}.list | ${D_API}/condition/sentaku/sentaku)

            echo $get

            ckey=".field.condition."`echo ${get} | awk -F';' '{print $2}'| cut -d '.' -f 2-`
            ikey=`echo ${ckey##*.}| sed -e 's/"//g'`

            #--- find measure file which has same name with selected key
            mfile=""
            if [ -e "${D_MEASURE}/${ptype}/${ikey}.json" ]; then
                # priority first is measure file contain under measure/phenomena (phenomena depend)
                mfile="${D_MEASURE}/${ptype}/${ikey}.json"

            elif [ -e "${D_MEASURE}/${ikey}.json" ]; then
                # priority second is measure file contain under measure (phenomena independ)
                mfile="${D_MEASURE}/${ikey}.json"

            else
                echo " cannot find measure file ${ikey}.json in ${D_MEASURE} or ${D_MEASURE}/${ptype}"
                echo " please create measure file by json format to set value into condition file"
                echo " quit"
                exit 1
            fi

            rsync -a $mfile $dumdir/${ikey}.json

            #--- select value
            # change delimiter to treat text including any space
            OIFS=$IFS
            IFS=$'\n'
            val=`cat $dumdir/${ikey}.json | jq -rc '."'${ikey}'"[]' 2>/dev/null`

            cnt=`cat $dumdir/${ikey}.json | jq -rc '."'${ikey}'"| length' 2>/dev/null`

            #-- add choices of processing command
            list=("${val}" "back_OR_use_default_value")
            #-- get number of selection
            echo
            echo " >> Please select value in ${ckey} <<"
            echo
            sleep 1

            input2=`selectKey "${list[@]}"`

            IFS=$OIFS


            if [ $input2 -eq $((cnt+1)) ]; then
                # back or use default value
                :
            else
                #-- get value from measure file
                vv=`cat $dumdir/${ikey}.json | jq -rc '."'${ikey}'"["'${input2}'"]' 2>/dev/null`

                #-- if selected key is coordinate type, check dependency
                if [ "${ikey}" == "extent" ]; then

                    xx=$(chkExtent "$vv" "${ddate}/condition/topography/DEM/geoinfo.json")
                    if [ $xx -eq 1 ]; then
                        # error
                        echo " selected coordinate is out of DEM domain. continue..."
                        sleep 2
                        continue
                    fi

                elif [ "${ikey}" == "point" ]; then
                    xx=$(chkPoint "$vv" "${ddate}/condition/topography/DEM/geoinfo.json")
                    if [ $xx -eq 1 ]; then
                        # error
                        echo " selected coordinate is outside of DEM domain. continue..."
                        sleep 2
                        continue
                    fi
                fi

                #-- set value into condition file
                cp -f ${dumdir}/${choise}.json ${dumdir}/${choise}.json.bak
                OIFS=$IFS
                IFS=$'\n'

                cat ${dumdir}/${choise}.json | jq -r ''${ckey}' |= '${vv}'' > ${dumdir}/dummy.json
                chk1=$?
                cat $dumdir/dummy.json > ${dumdir}/${choise}.json
                chk2=$?

                IFS=$OIFS

                #-- check necessary setting
                if [ $chk1 -ne 0 -o $chk2 -ne 0 ]; then
                    echo " error. please try again"
                    cp -f ${dumdir}/${choise}.json.bak ${dumdir}/${choise}.json
                else
                    echo " set OK"
                    sleep 0.5

                    xx=`cat ${dumdir}/${choise}.list | grep -Fn "${get}"`
                    nline=`cat ${dumdir}/${choise}.list | grep -F "${get}"`";done"

                    lnum=`echo $xx | awk -F':' '{print $1}'`
                    echo $nline

                    sed -i "${lnum}d" ${dumdir}/${choise}.list
                    sed -i -e "${lnum}i ${nline}" ${dumdir}/${choise}.list
                fi
            fi


            # check set value in necessary keys
            flag=0
            lnum=`cat ${dumdir}/${choise}.list | awk 'END {print NR}'`
            for i in `seq 1 $lnum`
            do
                index=`cat ${dumdir}/${choise}.list | awk -F'[;]' 'NR=='${i}' {print $1}'`
                state=`cat ${dumdir}/${choise}.list | awk -F'[;]' 'NR=='${i}' {print $4}'`

                if [ ${index} -eq 1 -a -z "${state}" ]; then
                    flag=1
                fi
            done

            # save file or not
            if [ ${flag} -eq 0 ]; then
                list=("save_file&continue" "save_file&quit" "without-save&continue" "without-save&quit")
                #-- get number
                input1=$(echo ${list[*]} | ${D_API}/condition/sentaku/sentaku)

                #-- check valid input or not
                if [ -z "${input1}" ]; then
                    # empty
                    echo "invalid input. continue"

                elif [ "${input1}" == "${list[0]}" ]; then
                    # save file & continue
                    echo "${list[0]}"
                    sleep 1

                    mkdir -p ${ddate}/condition/${choise}

                    #-- check same setting file
                    clist=`ls -F ${ddate}/condition/${choise}/ | grep .json`
                    for i in $clist
                    do
                        xx=`diff ${ddate}/condition/${choise}/$i ${dumdir}/${choise}.json`
                        if [ -z "${xx}" ]; then
                            echo " same condition file, which has a set of values, is already existed. continue..."
                            sleep 1
                            end2=1
                            break 2
                        fi
                    done

                    #-- save file with number increment
                    xx=`ls -F ${ddate}/condition/${choise}/ | grep .json | LANG=C sort -t _ -n -k 2 | awk 'END{print}' | awk -F'[_.]' '{print $2}'`
                    if [ -z "${xx}" ]; then
                        xx=0
                        echo " file ID= $xx (new)"
                        
                    else
                        
                        xx=$((xx+1))
                        echo " file ID= $xx (add)"
                    fi

                    rsync -a ${dumdir}/${choise}.json ${ddate}/condition/${choise}/${choise}_${xx}.json

                    end2=1

                elif [ "${input1}" == "${list[1]}" ]; then
                    # save file & quit
                    echo "${list[1]}"
                    sleep 1

                    mkdir -p ${ddate}/condition/${choise}

                    #-- check same setting file
                    clist=`ls -F ${ddate}/condition/${choise}/ | grep .json`
                    for i in $clist
                    do
                        xx=`diff ${ddate}/condition/${choise}/$i ${dumdir}/${choise}.json`
                        if [ -z "${xx}" ]; then
                            echo " same condition file, which has a set of values, is already existed. quit..."
                            sleep 1
                            end2=1
                            exit 0
                        fi
                    done

                    xx=`ls -F ${ddate}/condition/${choise}/ | grep .json | LANG=C sort -t _ -n -k 2 | awk 'END{print}' | awk -F'[_.]' '{print $2}'`

                    if [ -z "${xx}" ]; then
                        xx=0
                        echo " file ID= $xx (new)"
                        
                    else
                        xx=$((xx+1))
                        echo " file ID= $xx (add)"
                        
                    fi

                    rsync -a ${dumdir}/${choise}.json ${ddate}/condition/${choise}/${choise}_${xx}.json

                    exit 0


                elif [ "${input1}" == "${list[2]}" ]; then
                    # no save file & continue
                    echo "${list[2]}"
                    sleep 1

                elif [ "${input1}" == "${list[3]}" ]; then
                    # quit
                    echo "${list[3]}"
                    exit 0
                fi
            fi
        done

    done

else
    #--- edit mode
    :
fi


if [ -e "$dumdir" ]; then
    rm -rf $dumdir
fi

exit 0




