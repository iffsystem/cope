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


function selectfile() {
    local input2
    input2=0

    slist=$1
    sdir=$2
    sfile=$3

    echo " Please selected file (after selected, inside of file will be shown on this terminal)"
    sleep 3
    get=$(echo ${slist} | ${D_API}/condition/sentaku/sentaku)

    if [ -e "${sdir}/${get}" ]; then

        echo
        echo "  selected file : $get"
        echo
        cat ${sdir}/${get}
        echo
        echo "  [[ select the above file ? -> \"1\": select, \"2\": retry ]]"
        sleep 2
        read input2


        if [ "${input2}" = "1" -o -z "${input2}" ]; then
            echo "select OK"
            sfile=${get}

        elif  [ "${input2}" = "2" ]; then
            echo "RETRY" && sleep 1
            selectfile $slist $sdir
        else
            echo "  invalid input" && sleep 1
            selectfile $slist $sdir
        fi

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

function combination()
{
    local parent=$1
    local child=$2

    cnt=1
    for i in ${parent[@]}
    do
        for j in ${child[@]}
        do
            xx="$i;$j"
            
            unset val
            unset val2

            # check deny filter
            if [ "${ideny}" == "ON" ]; then
                OIFS=$IFS
                IFS=$'\n'
                flag=0
                for k in ${filterdeny[@]}
                do
                    chk1=`echo "${xx}"| grep -x "${k}" 1>/dev/null && echo 1 || echo 0`
                    chk2=`echo "${k}"| grep "${xx}" 1>/dev/null && echo 1 || echo 0`
                    if [ ${chk1} -eq 1 -o ${chk2} -eq 1 ]; then
                        # match -> skip
                        flag=0
                        break 1
                    else
                        #no match -> add
                        flag=1
                    fi
                done
                IFS=$OIFS
                if [ ${flag} -eq 1 ]; then
                    val=$xx
                fi
            else
                val=$xx
            fi

            # check allow filter
            if [ "${iallow}" == "ON" ]; then
                OIFS=$IFS
                IFS=$'\n'
                flag=0
                for k in ${filterallow[@]}
                do
                    chk1=`echo "${val}"| grep -x "${k}" 1>/dev/null && echo 1 || echo 0`
                    chk2=`echo "${k}"| grep "${val}" 1>/dev/null && echo 1 || echo 0`
                    if [ ${chk1} -eq 1 -o ${chk2} -eq 1 ]; then
                        # match -> add
                        flag=1
                        break 1
                    else
                        #no match -> skip
                        flag=0
                    fi
                done
                IFS=$OIFS
                if [ ${flag} -eq 1 ]; then
                    val2=$val
                fi
            else
                val2=$val
            fi

            echo $val2
        done
    done

    return

}



echo "---------------------------"
echo "|   SET case file         |"
echo "---------------------------"

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


echo "#----  SET case"


# select phenomena
plist=`ls ${ddate}/condition/phenomena/${ptype}/ | grep .json`
if [ -z "${plist}" ]; then
    echo " no selectable condition file of phenomena"
    echo " quit"
    exit 0
else

    # select phanomena
    sfile=""
    selectfile "${plist}" "${ddate}/condition/phenomena/${ptype}" ${sfile}

fi

tfield=`basename $(cd $(dirname $ddate)/;pwd)`
tdate=`basename ${ddate}`

echo
echo $tfield
echo $tdate
echo $ptype
echo $sfile
echo


# get input conditions
pfile="${ddate}/condition/phenomena/${ptype}/${sfile}"
keychain0='.field.condition.input'
key0=${keychain0##*.}
nkey0=`echo $keychain0|awk -F[.] '{print NF}'`

# get keys which can set value from phenomena.json
roop=0
cnt=1
while (roop==0)
do
    xx=`cat $pfile | jq -cr ''${keychain0}'."'${cnt}'"|keys[]' 2>/dev/null`
    if [ -z "${xx}" ]; then
        roop=1
        break 1
    fi
    ctype[$cnt]=$xx
    cnt=$((cnt+1))
done


# set condition files into array
unset cfiles
cnum=0
for i in ${ctype[@]}
do
    cnum=$((cnum+1))
    list=`ls ${ddate}/condition/${i}/ | grep .json | grep ${i}`
    xx=1
    for j in ${list}
    do
        eval cfiles${cnum}[$xx]=${j}
        xx=$((xx+1))
    done
done

#echo ${cfiles[@]}
echo
echo " found condition files"
for i in `seq 1 ${cnum}`
do
    xx="cfiles${i}[@]"
    echo "    "${!xx}
done
echo


# read deny file
xx=${D_CONFIG}/case_filter_deny.json
ideny=OFF
if [ -e "${xx}" ]; then
    val=`cat $xx | jq -cr '.filter|keys[]'`
    if [ ! -z "${val}" ]; then

        # select filter number
        # change delimiter to treat text including any space
        OIFS=$IFS
        IFS=$'\n'

        cnt=`cat $xx | jq -rc '.filter| length' 2>/dev/null`

        list=()
        ids=()
        nn=1
        for i in `seq 1 $cnt`
        do
            val=`cat $xx | jq -cr '.filter."'$i'"."'${tfield}'"."'${tdate}'"."'${ptype}'"."'${sfile}'"' 2>/dev/null`
            if [ ! -z "${val}" -a ! "${val}" == "null" ]; then
                list[$nn]="${val}"
                ids[$nn]=$i
                nn=$((nn+1))
            fi
        done

        #-- add choices of processing command
        list[$nn]="no use deny filter"

        #-- get number of selection
        echo " Please select number of deny filter"
        sleep 1

        input2=`selectKey "${list[@]}"`

        IFS=$OIFS


        if [ $input2 -eq $nn ]; then
            # no use
            :
        else
            #-- get value from measure file
            filterdeny=`cat $xx | jq -rc '.filter."'${ids[$input2]}'"' 2>/dev/null`
            ideny=ON

            echo " [deny filter] : $filterdeny"

            OIFS=$IFS
            IFS=$'\n'
            filterdeny=`(cat $xx | jq -cr '.filter."'${ids[$input2]}'"|paths' 2>/dev/null | sed -e 's/\[//g' -e 's/\]//g' -e 's/\"//g'| awk -F',' '{if($NF == "val")print}'| sed -e 's#'${tfield}'##g' -e 's#'${tdate}'##g' -e 's/val//g' -e 's#'${ptype}'##g' -e 's#'${sfile}'##g' -e 's/,/ /g' -e 's/^ *//g' -e 's/ *$//g' -e 's/ /;/g')`

            for i in ${filtedreny[*]}
            do
                echo "   deny combo : "$i
            done
            IFS=$OIFS
        fi
    else
        echo " [deny filter] cannot find selectable deny filter"
        echo
    fi
fi

# read allow file
xx=${D_CONFIG}/case_filter_allow.json
iallow=OFF
if [ -e "${xx}" ]; then
    val=`cat $xx | jq -cr '.filter|keys[]'`
    if [ ! -z "${val}" ]; then

        # select filter number
        # change delimiter to treat text including any space
        OIFS=$IFS
        IFS=$'\n'
        
        cnt=`cat $xx | jq -rc '.filter| length' 2>/dev/null`

        list=()
        ids=()
        nn=1
        for i in `seq 1 $cnt`
        do
            val=`cat $xx | jq -cr '.filter."'$i'"."'${tfield}'"."'${tdate}'"."'${ptype}'"."'${sfile}'"' 2>/dev/null`
            if [ ! -z "${val}" -a ! "${val}" == "null" ]; then
                list[$nn]="${val}"
                ids[$nn]=$i
                nn=$((nn+1))
            fi
        done

        #-- add choices of processing command
        list[$nn]="no use allow filter"

        #-- get number of selection
        echo " Please select number of allow filter"
        sleep 1

        input2=`selectKey "${list[@]}"`

        IFS=$OIFS


        if [ $input2 -eq $nn ]; then
            # no use
            :
        else
            #-- set filter number
            filterallow=`cat $xx | jq -rc '.filter."'${ids[$input2]}'"' 2>/dev/null`
            iallow=ON

            echo " [allow filter] : $filterallow"

            OIFS=$IFS
            IFS=$'\n'
            filterallow=`(cat $xx | jq -cr '.filter."'${ids[$input2]}'"|paths' 2>/dev/null | sed -e 's/\[//g' -e 's/\]//g' -e 's/\"//g'| awk -F',' '{if($NF == "val")print}'| grep ${ptype} | sed -e 's#'${tfield}'##g' -e 's#'${tdate}'##g' -e 's/val//g' -e 's#'${ptype}'##g' -e 's#'${sfile}'##g' -e 's/,/ /g' -e 's/^ *//g' -e 's/ *$//g' -e 's/ /;/g')`

            for i in ${filterallow[*]}
            do
                echo "   allow combination : "$i
            done
            IFS=$OIFS

        fi
    else
        echo " [allow filter] cannot find selectable allow filter"
        echo
    fi
fi


echo
echo " set combination"
cnt=1
num=1
unset comb
unset comb2


while (roop==0)
do
    if [ $cnum -eq 1 ]; then

        cnt=1
        xx="cfiles${cnt}[@]"
        ret=(${!xx})

        # check deny filter
        if [ "${ideny}" == "ON" ]; then
            OIFS=$IFS
            IFS=$'\n'
            for i in ${ret[@]}
            do
                flag=0
                for j in ${filterdeny[@]}
                do
                    if [ $(echo "${i}"| grep -x "${j}") ]; then
                        # perfect match -> skip
                        flag=0
                        break 1
                    else
                        #no match -> add
                        flag=1
                    fi
                done
                if [ ${flag} -eq 1 ]; then
                    comb[$num]=$j
                    num=$((num+1))
                fi
            done
            IFS=$OIFS
        else
            comb="(${ret[@]})"
        fi

        # check allow filter
        if [ "${iallow}" == "ON" ]; then
            OIFS=$IFS
            IFS=$'\n'
            for i in ${comb[@]}
            do
                flag=0
                for j in ${filterallow[@]}
                do
                    if [ $(echo "${i}"| grep -x "${j}") ]; then
                        # perfect match -> add
                        flag=1
                        break 1
                    else
                        #no match -> skip
                        flag=0
                    fi
                done
                if [ ${flag} -eq 1 ]; then
                    comb2[$num]=$j
                    num=$((num+1))
                fi
            done
            IFS=$OIFS
        else
            comb2="(${comb[@]})"
        fi

        roop=1
        break
    fi

    if [ $cnt -eq 1 ]; then
        xx1="cfiles${cnt}[*]"
    else
        xx1="comb2[*]"
    fi
    xx2="cfiles$((cnt+1))[*]"

    
    comb2=(`combination "${!xx1}" "${!xx2}"`)

    xx=$((cnt+1))
    if [ $xx -eq $cnum  ]; then
        roop=1
        break 1
    fi

    cnt=$((cnt+1))
done

if [ ${#comb2[@]} -eq 0 ]; then
    echo
    echo " [ERROR] there is no possible combination"
    echo " please re-check deny & allow filters"
    echo " quit"
    echo
    exit
fi


echo
echo " [add case files] (not add if same case is exist)"

# get ID number of exist case file
xx=`ls -F ${ddate}/case/${ptype}/ 2>/dev/null | grep .json | LANG=C sort -t _ -n -k 2 | awk 'END{print}' | awk -F'[_.]' '{print $2}'`
if [ -z "${xx}" ]; then
    cnt=0
    mkdir -p ${ddate}/case/${ptype} 
else
    cnt=$((xx+1))
fi

elist=$(ls -F ${ddate}/case/${ptype}/ 2>/dev/null | grep .json)

OIFS=$IFS
IFS=$'\n'
for i in ${comb2[@]}
do
    val="${sfile};${i}"
    
    echo '{"condition":{}}' > $dumdir/dummy.json

    nn=1
    OIFS=$IFS
    IFS=$';'
    for k in $val
    do
        cat $dumdir/dummy.json | jq '.condition |= .+ {"'${nn}'":{"val":"'${k}'"}}' > $dumdir/dummy2.json
        cp -f $dumdir/dummy2.json $dumdir/dummy.json
        nn=$(( nn + 1 ))
    done 
    IFS=$OIFS
    
    
    # check same case
    flag=0
    if [ ! -z "${elist[@]}" ]; then
        for j in ${elist[@]}
        do
            xx=`diff -q ${ddate}/case/${ptype}/$j $dumdir/dummy.json`
            
            
            if [ -z "${xx}" ]; then
                flag=1
                break 1
            else
                flag=0
            fi
        done
    fi

    if [ $flag -eq 0 ]; then
        echo "ID=$cnt  $val"
        rsync -a $dumdir/dummy.json ${ddate}/case/${ptype}/${ptype}_case_${cnt}.json
        cnt=$((cnt+1))
    fi
done
IFS=$OIFS


if [ -e "$dumdir" ]; then
    rm -rf $dumdir
fi

exit 0




