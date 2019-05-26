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
    local upchain=$1

    local ptype=`echo $upchain | awk -F'_' '{print $1}'`


    for child in ${tcase[@]}
    do
        xx="$upchain;$child"

        clen=`echo $xx | awk -F';' '{print NF}'`

        if [ ${clen} -gt ${clenmax} ]; then
            return
        fi


        unset val
        unset val2

        unset typechain
        OIFS=$IFS
        IFS=$';'
        for j in $xx
        do
            yy=`echo $j | awk -F'_' '{print $1}'`
            typechain+="${yy};"
        done
        IFS=$OIFS

        typechain=`echo $typechain | sed -e 's/;$//g'`

        # check deny filter
        if [ "${ideny}" == "ON" ]; then
            OIFS=$IFS
            IFS=$'\n'
            for k in ${filterdeny[@]}
            do
                yy=`echo $k | awk -F';' '{print $1}'`
                if [ ! "${yy}" == "-" ]; then
                    continue 1
                fi

                yy=`echo $k | cut -c 3-`

                if [ $(echo "${typechain}"| grep "${yy}") ]; then
                    # partial/perfect match -> skip
                    IFS=$OIFS
                    continue 2
                fi
            done
            IFS=$OIFS
        fi

        # check allow filter
        if [ "${iallow}" == "ON" ]; then
            OIFS=$IFS
            IFS=$'\n'
            for k in ${filterallow[@]}
            do
                yy=`echo $k | awk -F';' '{print $1}'`
                if [ ! "${yy}" == "-" ]; then
                    continue 1
                fi

                yy=`echo $k | cut -c 3-`
                if [ $(echo "${val}"| grep "${yy}") ]; then
                    :
                else
                    #not partial/perfect match -> skip
                    IFS=$OIFS
                    continue 2
                fi
            done
            IFS=$OIFS
        fi

        if [ ${clen} -eq ${clenmax} ]; then
            numchain=$((numchain+1))

            dir=`echo $xx | sed -e 's#;#/#g' -e 's/.json//g'`
            echo "  [$numchain] ${dir}"
            
            #-- create directory for containing simulation results of this event
            mkdir -p ${dumdir}/chain/${dir}
            
        else
            combination ${xx}
        fi

    done

    return

}



echo "---------------------------"
echo "|   SET chain directory    |"
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
unset back

trap '[[ "$back" ]] && rsync -a $back/.total_chain.list ${ddate}/chain/.total_chain.list && rsync -a $back/.ready_chain.list ${ddate}/chain/.ready_chain.list && rsync -a $back/all_chain.list ${ddate}/chain/all_chain.list && touch ${ddate}/chain/.state.done && [[ "$dumdir" ]] && rm -rf $dumdir && [[ "$back" ]] && rm -rf $back;echo " build chains: OK"' 0
trap '[[ "$dumdir" ]] && rm -rf $dumdir && [[ "$back" ]] && rm -rf $back;echo " EXIT"' 1 2 3 15


dumdir=$(mktemp -d ${ddate}/tmp/`basename $0`_XXXXXXX)
back=$(mktemp -d ${ddate}/tmp/`basename $0`_XXXXX)



tfield=`basename $(cd $(dirname $ddate)/;pwd)`
tdate=`basename ${ddate}`

project=`cat ${ddate}/condition/topography/DEM/geoinfo.json 2>/dev/null | jq -r '.file.name.value'`
if [ -z "${project}" ]; then
    echo
    echo " ERROR: cannot get project name from ${ddate}/condition/topography/DEM/geoinfo.json"
    echo " please check file existence. Or please set DEM correctly"
    echo " quit"
    echo
    exit
fi

echo "#----  SET chains"

# set parameter of chain processing
xx="${D_CONFIG}/chain_proc.json"
cnt=`cat $xx | jq -rc '."chain_proc"| length' 2>/dev/null`

OIFS=$IFS
IFS=$'\n'

list=()
nn=1
for i in `seq 1 $cnt`
do
    val=`cat $xx | jq -cr '."chain_proc"."'$i'"' 2>/dev/null`
    if [ ! -z "${val}" -a ! "${val}" == "null" ]; then
        list[$nn]="${val}"
        nn=$((nn+1))
    fi
done

#-- add choices of processing command
list[$nn]="(default) = 1"

#-- get number of selection
echo " Please select chain depth"
sleep 1

input2=`selectKey "${list[@]}"`

IFS=$OIFS


if [ $input2 -eq $nn ]; then
    # no use
    clenmax=1
else
    clenmax=`cat $xx | jq -cr '."chain_proc"."'${input2}'".depth.val' 2>/dev/null`
fi

echo " [chain depth] = ${clenmax}"



# read deny file
xx=${D_CONFIG}/chain_filter_deny.json
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
            val=`cat $xx | jq -cr '.filter."'$i'"."'${tfield}'"."'${tdate}'"' 2>/dev/null`
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
            filterdeny=`(cat $xx | jq -cr '.filter."'${ids[$input2]}'"|paths' 2>/dev/null | sed -e 's/\[//g' -e 's/\]//g' -e 's/\"//g'| awk -F',' '{if($NF == "val")print}'| sed -e 's#'${tfield}'##g' -e 's#'${tdate}'##g' -e 's/val//g'  -e 's/,/ /g' -e 's/^ *//g' -e 's/ *$//g' -e 's/ /;/g')`

            for i in ${filterdeny[*]}
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
xx=${D_CONFIG}/chain_filter_allow.json
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
            val=`cat $xx | jq -cr '.filter."'$i'"."'${tfield}'"."'${tdate}'"' 2>/dev/null`
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
            filterallow=`(cat $xx | jq -cr '.filter."'${ids[$input2]}'"|paths' 2>/dev/null | sed -e 's/\[//g' -e 's/\]//g' -e 's/\"//g'| awk -F',' '{if($NF == "val")print}'| sed -e 's#'${tfield}'##g' -e 's#'${tdate}'##g' -e 's/val//g' -e 's/,/ /g' -e 's/^ *//g' -e 's/ *$//g' -e 's/ /;/g')`

            for i in ${filterallow[*]}
            do
                echo "   allow combo : "$i
            done
            IFS=$OIFS

        fi
    else
        echo " [allow filter] cannot find selectable allow filter"
        echo
    fi
fi

# get phenomena
xx=`ls -d ${ddate}/case/*`
if [ ! -z "${xx}" ]; then
    cnt=1
    for i in ${xx[@]}
    do
        ptype[$cnt]=`basename $i`
        cnt=$((cnt+1))
    done
else
    echo
    echo " [ERROR] there is no selectable case"
    exit
fi


echo
echo $tfield
echo $tdate
echo ${ptype[@]}
echo

# set case files into array
unset cfiles
unset tcase
cnum=0
num=0
for i in ${ptype[@]}
do
    cnum=$((cnum+1))
    list=`ls ${ddate}/case/${i}/ | grep .json`
    xx=1
    for j in ${list}
    do
        eval cfiles${cnum}[$xx]=${j}
        xx=$((xx+1))

        num=$((num+1))
        tcase[$num]=$j
    done
done

echo
echo " found case files"
for i in `seq 1 ${cnum}`
do
    xx="cfiles${i}[@]"
    echo "    ${ptype[${i}]} : ${!xx}"
done
echo

echo "ideny = $ideny"
echo "iallow = $iallow"

echo
echo " set combination of chains"


cnt=0
numchain=0
for i in ${tcase[@]}
do
    # check 1st event (root)
    flag=0
    ptype=`echo $i | awk -F'_' '{print $1}'`

    # check deny filter for 1st event
    if [ "${ideny}" == "ON" ]; then
        for k in ${filterdeny[@]}
        do
            rootcase=`echo $k | awk -F';' '{print $1}'`

            
            if [ -z "${rootcase}" -o "${rootcase}" == "-" ]; then
                continue 1
            fi

            if [ "${ptype}" == "${rootcase}" ]; then
                continue 2
            fi
        done
    fi

    # check allow filter for 1st event
    if [ "${iallow}" == "ON" ]; then
        for k in ${filterallow[@]}
        do
            rootcase=`echo $k | awk -F';' '{print $1}'`
            flag=0

            if [ -z "${rootcase}" -o "${rootcase}" == "-" ]; then
                continue 1
            fi

            if [ ! "${ptype}" == "${rootcase}" ]; then
                continue 2
            fi
        done
    fi


    if [ $flag -eq 0 ]; then
        combination $i
    fi
done


#-- add chains
find ${dumdir}/chain/* -depth | LANG=C sort -n > ${dumdir}/chain.list

for i in `cat ${dumdir}/chain.list`
do
    xx=`echo $i | sed -e 's#'${dumdir}/chain/'##g'`
    
    ss=`ls ${ddate}/chain/$xx 2>/dev/null | grep -e .state.done -e .calc.ready | wc -l`
    if [ ${ss} -eq 0 ]; then
        mkdir -p ${ddate}/chain/$xx
        touch ${ddate}/chain/$xx/.calc.ready
    fi
done



#-- get list of all chains
find ${ddate}/chain/* -depth | grep -e .calc.ready -e .state.done | sed -e 's#/.calc.ready##g' -e 's#/.state.done##g' | LANG=C sort -n > ${back}/.total_chain.list

#-- get list of all chains in case of ready state
find ${ddate}/chain/* -depth | grep .calc.ready | sed -e 's#/.calc.ready##g'| LANG=C sort -n > ${back}/dummy.list


#-- add depth number of directory path for sorting
cnt=0
while read line
do
    cnt=$((cnt + 1))
    depth=`echo -n ${line} | sed -e 's@[^/]@@g' | wc -c`
    sed -i "${cnt}s/^/${depth} /" ${back}/dummy.list
    
done < ${back}/dummy.list

cat ${back}/dummy.list | LANG=C sort -n > ${back}/.ready_chain.list


#-- create chain list for WEB-UI
cat ${back}/.ready_chain.list | awk -F' ' '{$1="";print}' | sed -e 's/^ //g' | sed -e  's#'${D_FIELD}/'##g' > ${back}/all_chain.list


echo "registration information to logical Databae"
#--------------------------------------
bash ${D_API}/db/psql_setchain.sh --project ${project} --chainlist ${back}/.ready_chain.list
#--------------------------------------


exit 0
