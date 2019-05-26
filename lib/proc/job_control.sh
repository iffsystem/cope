#!/bin/bash


#--- get my process ID
_PID=$$

#-- directory path at top
RPATH=$(cd $(dirname $0)/../../;pwd)

#-- read filesystem
. ${RPATH}/config/filesystem.conf


#--- read options
OPT=`getopt -o " " -l chainpath: -l ncpu: -- "$@"`
if [ "$?" -ne 0 -o "`echo ${OPT}`" == "--" ]; then
      echo "Usage: $0 "
      echo "      [--chainpath=character] (chain's path)"
      echo "      [--ncpu=number] (select number of num_cpu.json)"
      exit
fi

eval set -- "$OPT"

until [ "$1" == "--" ]; do

      case $1 in
            --chainpath)
                  chainpath=$2
                  ;;
            --ncpu)
                  ncpu=$2
                  ;;
      esac
      shift
done

if [ ! -z "${ncpu}" -a -e "${D_CONFIG}/num_cpu.json" ]; then
    N_CPU=`cat ${D_CONFIG}/num_cpu.json | jq -r '."num_cpu"."'${ncpu}'".cpunum.val'`
fi

if [ -z "${N_CPU}" ]; then
    N_CPU=1
fi

ddate=`dirname $chainpath`
project=`cat ${ddate}/condition/topography/DEM/geoinfo.json 2>/dev/null | jq -r '.file.name.value'`
if [ -z "${project}" ]; then
    echo
    echo " ERROR: cannot get project name from ${ddate}/condition/topography/DEM/geoinfo.json"
    echo " please check file existence. Or please set DEM correctly"
    echo " quit"
    echo
    exit
fi


if [ ! -e "${chainpath}" ]; then
    echo
    echo "ERROR: chain path is not exist: ${chainpath}"
    echo "quit"
    echo
    exit 99
fi

echo
echo "CHAIN = "$chainpath
echo "N_CPU = "${N_CPU}
echo

starttime=`date "+%Y-%m-%d %H:%M.%S"`
timestamp=`date +"%Y%m%d%H%M%S%3N"` 

logdir="`dirname $chainpath`/tmp"
mkdir -p $logdir
calcprogresslog=${logdir}/calcprogress_"${timestamp}".txt
    
    
COLOR_1="\e[1;31m"
COLOR_2="\e[1;34m"
COLOR_OFF="\e[m"


unset dummy
trap 'echo "  PID = ${_PID} (closing this process. wait 5sec)";Func_kill_batch && sleep 5;[[ "${calcprogresslog}" ]] && rm -rf ${calcprogresslog};[[ "$dummy" ]] && rm -rf $dummy;echo " EXIT";exit' ERR 1 2 3 15


dummy=$(mktemp -d ${chainpath}/`basename $0`_XXXXX)

num_queue=`cat ${chainpath}/.ready_chain.list | wc -l`
end_queue=0

queue_list=`cat ${chainpath}/.ready_chain.list | awk -F' ' '{$1="";print $2}'| sed -e 's/^ //g'`


Func_kill_batch()
{
    for i in `seq 0 $((${N_CPU}-1))`
    do
        bash ${D_API}/proc/killtree.sh ${queue_pid[${i}]} KILL
        rm -f ${cpu_queue[${i}]}/.calc.on
        rm -f ${cpu_queue[${i}]}/.calc.err
    done
}

Func_run_batch()
{
    bash ${engine_dir}/API/batch_run.sh --project ${project} --target ${queue} --retry ${queue_retry[${cpu_qid[${i}]}]}
}


#--- [state]
#
# .calc.ready   : turn waiting state
# .calc.on      : on going to processing
# .calc.err     : error state
# .state.done   : end state (sucess)
# .state.err   : end state (failure even 3 times retry)
#

#--- initialize
for i in `seq 0 $((${N_CPU}-1))`
do
    cpu_state[${i}]=0
done
for i in `seq 0 $((${num_queue}-1))`
do
    queue_state[${i}]=0
    queue_retry[${i}]=0
done


err_num=0


while true
do
    #--- end condition
    if [ ${end_queue} -eq ${num_queue} ]; then
        break
    fi
    
    #--- search queue & exec batch
    cnt=0
    for queue in ${queue_list}
    do
        
        #-- check parent state
        p_path=$(cd ${queue}/../;pwd)
        my_path=$(cd ${queue};pwd)
        
        
        state_parent=0
        xx=`ls -a ${p_path}/.calc.on 2> /dev/null | wc -l`
        if [ ${xx} -ne 0 ]; then
            state_parent=1
        fi
        
        err_parent=0
        xx=`ls -a ${p_path}/.calc.err 2> /dev/null | wc -l`
        yy=`ls -a ${p_path}/.state.err 2> /dev/null | wc -l`
        if [ ${xx} -ne 0 -a ${yy} -ne 0 ]; then
            err_parent=1
        fi
        
        end_parent=0
        xx=`ls -a ${p_path}/.state.done 2> /dev/null | wc -l`
        if [ ${xx} -ne 0 ]; then
            end_parent=1
        fi
        
            
        #-- check my state
        state_me=0
        state_me2=0
        xx=`ls -a ${my_path}/.calc.on 2> /dev/null | wc -l`
        if [ ${xx} -ne 0 ]; then
            state_me=1
        fi
        xx=`ls -a ${my_path}/.state.done 2> /dev/null | wc -l`
        if [ ${xx} -ne 0 ]; then
            state_me=1
            state_me2=1
        fi
        
        err_me=0
        xx=`ls -a ${my_path}/.calc.err 2> /dev/null | wc -l`
        if [ ${xx} -ne 0 ]; then
            err_me=1
        fi
        
        
        #--- check cpu state 
        for i in `seq 0 $((${N_CPU}-1))`
        do
            if [ ${err_parent} -eq 0 -a ${end_parent} -eq 1 -a ${state_me} -eq 0 ]; then
                #echo "CPU=$i, ${queue_retry[${i}]} ${cpu_state[${i}]} ${queue_state[${cnt}]} : $queue"
                
                if [ ${queue_retry[${i}]} -lt 4 -a ${cpu_state[${i}]} -eq 0 ]; then
                    
                    
                    queue_state[${cnt}]=0
                                        
                    cpu_qid[${i}]=${cnt}
                    cpu_queue[${i}]="${queue}"
                    cpu_state[${i}]=-1
                    
                    state_me=1
                    
                    
                    #--- check simulation type
                    sim_type=`basename ${queue} | awk -F'_' '{print $1}'`


                    engine_dir=${D_ENGINE}/${sim_type}

                    #--- run batch
                    if [ ${queue_retry[${i}]} -eq 0 ]; then
                        Func_run_batch 2>&1 | tee ${queue}/.log.stdout-err >/dev/null 2>&1 &
                        xx=$!
                    
                    else
                        Func_run_batch 2>&1 | tee -a ${queue}/.log.stdout-err >/dev/null 2>&1 &
                        xx=$!
                    
                    fi
                    
                    queue_pid[${i}]=$((xx-1))
                    
                    echo "RUN BATCH (${queue_pid[${i}]})" ${queue}
                fi
            elif [ ${err_parent} -eq 0 -a ${end_parent} -eq 1 -a ${state_me2} -eq 1 ]; then            
                queue_state[${cnt}]=1
            fi
        done
        
        
        if [ ${err_parent} -eq 1 ]; then
            touch ${queue}/.calc.err
            touch ${queue}/.state.err
            
            queue_state[${cnt}]=-1
        
        fi
        
        cnt=$((cnt+1))    
        
    done


    #--- monitoring state of batch
    for i in `seq 0 $((${N_CPU}-1))`
    do
        if [ ${cpu_state[${i}]} -eq -1 ]; then
            
            #--- success state
            xx=`ls -a ${cpu_queue[${i}]}/.state.done 2> /dev/null | wc -l`
            if [ ${xx} -ne 0 ]; then
                
                echo "  [DONE] : ${cpu_queue[${i}]}"
                
                rm -f ${cpu_queue[${i}]}/.calc.ready
                rm -f ${cpu_queue[${i}]}/.calc.on
                rm -f ${cpu_queue[${i}]}/.calc.err
                
                queue_state[${cpu_qid[${i}]}]=1
                
                cpu_qid[${i}]=0
                cpu_queue[${i}]=""
                cpu_state[${i}]=0
                
                
            fi
            
            #--- error state
            xx=`ls -a ${cpu_queue[${i}]}/.calc.err 2> /dev/null | wc -l`
            if [ ${xx} -ne 0 ]; then
                
                #touch ${cpu_queue[${i}]}/.state.done
                cpu_state[${i}]=0
                
                
                #--- kill co-process tree
                num=`ps aux | grep ${queue_pid[${i}]} | grep "bash" | wc -l`
                if [ ${num} -eq 1 ]; then
                    bash ${D_API}/proc/killtree.sh ${queue_pid[${i}]} KILL
                    echo "[KILL] : ${queue_pid[${i}]}"
                fi
                
                echo " RETRY : ${queue_retry[${cpu_qid[${i}]}]}"
                sleep 1
                
                if [ ${queue_retry[${cpu_qid[${i}]}]} -ge 4 ]; then
                    queue_state[${cpu_qid[${i}]}]=-1
                    
                    touch ${cpu_queue[${i}]}/.state.err
                    continue                   
                fi
                
                rm -f ${cpu_queue[${i}]}/.calc.on
                rm -f ${cpu_queue[${i}]}/.calc.err
                
                queue_retry[${cpu_qid[${i}]}]=$((queue_retry[${cpu_qid[${i}]}] +1))
                
            fi
        fi
        
        # can manually reset retry-count by creation of specific file
        if [ -e ${cpu_queue[${i}]}/.retry.count.reset ]; then
            queue_retry[${cpu_qid[${i}]}]=0
        fi
        
    done
    
    #--- cnt number of end status
    end_queue=0
    err_num=0
    for i in `seq 0 $((${#queue_state[@]}-1))`
    do
        if [ ${queue_state[${i}]} -eq 1 -o ${queue_state[${i}]} -eq -1 ]; then
            end_queue=$((end_queue + 1))
        fi
        
        if [ ${queue_state[${i}]} -eq -1 ]; then
            err_num=$((err_num + 1))
        fi
        
    done

    echo "${end_queue}/${num_queue}" > ${dummy}/state
    echo "${queue_state[@]}" >> ${dummy}/state
    
    
    #--- monitor status
    
    echo -n > ${calcprogresslog}
    
    echo "CHAIN = ${chainpath}" 2>&1 | tee -a ${calcprogresslog}
    echo "PROGRESS SATUS = ${end_queue}/${num_queue} (chains)  [ERROR CHAIN = ${err_num}]" 2>&1 | tee -a ${calcprogresslog}
    echo "" 2>&1 | tee -a ${calcprogresslog}
    
    echo "#=== MONITOR PROGRESS =================================================" 2>&1 | tee -a ${calcprogresslog}
    echo " NOW : `date "+%Y-%m-%d %H:%M.%S"` (START DATE = ${starttime})" 2>&1 | tee -a ${calcprogresslog}
     
    for i in `seq 0 $((${N_CPU}-1))`
    do
        echo "-------------------------------------------------------" 2>&1 | tee -a ${calcprogresslog}
        
        xx=`echo ${cpu_queue[${i}]} | sed -e "s#${D_FIELD}##g"`
        
        echo -e "${COLOR_1} [Progress CPU:${i}] (PPID=${_PID},MYPID=${queue_pid[${i}]}) RETRY : ${queue_retry[${cpu_qid[${i}]}]}/3${COLOR_OFF}" 
        echo -e "${COLOR_2} QUEUE : ~${xx}${COLOR_OFF}"
        
        echo " [Progress CPU:${i}] (PPID=${_PID},MYPID=${queue_pid[${i}]}) RETRY : ${queue_retry[${cpu_qid[${i}]}]}/3" >> ${calcprogresslog}
                
        echo " QUEUE : ~${xx}" >> ${calcprogresslog}
        echo "" >> ${calcprogresslog}
        
        if [ -e "${cpu_queue[${i}]}/.log.stdout-err" ]; then
            tail -n 10 ${cpu_queue[${i}]}/.log.stdout-err 2>&1 | tee -a ${calcprogresslog}
        fi
        echo 2>&1 | tee -a ${calcprogresslog}
        
    done
    
    echo "#======================================================================" 2>&1 | tee -a ${calcprogresslog}
    echo  2>&1 | tee -a ${calcprogresslog}
    
    
    sleep 5

done

if [ -e "$dummy" ] ;then
    rm -rf $dummy
fi


rm -f ${calcprogresslog}

exit 0


