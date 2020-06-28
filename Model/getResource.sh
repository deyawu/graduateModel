#resource occupied % 
cpu_total=0
mem_total=0
net_receive=0
net_put=0

sourceFileName='resource.txt'

# get MEM、CPU info
getSysInfo(){
    cpu_snapshot=cpu_snapshot.txt
    cpufile=cpu.txt
    memfile=mem.txt
    cpu_total=0
    mem_total=0
    rm -f $cpu_snapshot
    psResult=`nohup ps -aux`
    echo "$psResult" >> $cpu_snapshot
    while read line
    do
            if [ ${#line} > 0 ]; then
                    cpu_num=`echo $line |grep -v "CPU"| awk -F ' ' '{print $3}'`
                    mem_num=`echo $line |grep -v "MEM"| awk -F ' ' '{print $4}'`
                    if [[ ${#cpu_num} > 0 && ${#mem_num} > 0 ]];then
                            cpu_total=$(echo $cpu_total $cpu_num | awk '{printf "%.3f\n",$1 + $2}')
                            mem_total=$(echo $mem_total $mem_num | awk '{printf "%.3f\n",$1 + $2}')


                    fi
            fi
    done < $cpu_snapshot

    cpu_total=$(echo $cpu_total | awk '{printf "%.3f\n",$1 / 6}')
   # echo "master_cpu $cpu_total" &>> $cpufile
   # echo "master_mem $mem_total" &>> $memfile
}

# get NetWork info
getNetInfo(){
    eth="em1" #detect info of em1
    receivePre=$(cat /proc/net/dev | grep $eth | tr : " " | awk '{print $2}')
    putPre=$(cat /proc/net/dev | grep $eth | tr : " " | awk '{print $10}')
    sleep 1
    receivePost=$(cat /proc/net/dev | grep $eth | tr : " " | awk '{print $2}')
    putPost=$(cat /proc/net/dev | grep $eth | tr : " " | awk '{print $10}')
    receive=`expr $receivePost - $receivePre`
    put=`expr $putPost - $putPre`
    if [ $receive -lt 0 ]; then
        receive=`expr 0 - $receive`
    fi
    if [ $put -lt 0 ]; then
        put=`expr 0 - $put`
    fi
    # translate to format MB
    net_receive=$(echo $receive | awk '{print $1/1048576}')
    net_put=$(echo $put | awk '{print $1/1048576}')
}

getSysInfo
getNetInfo
netResult=$net_put
if [  $net_put \< $net_receive ]; then
   netResult=$net_receive
fi
echo "$cpu_total  $mem_total  $netResult" > ${sourceFileName}

echo "$cpu_total  $mem_total  $netResult"

