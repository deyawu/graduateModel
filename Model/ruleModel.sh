CPU_chosen=false
Memory_chosen=false
Network_chosen=false 
netPort='em1' # network bytes flowing
netSpeed=125 # BindWidth MB/S

sourceFileName='resource.txt' # to store source sample information
jobcommand=$1 # get the alluxio running command
runningTime=90 #1min30s
diet=0.05
properties_name='/home/gurong1228/alluxio-2.1.0/conf/alluxio-site.properties' #alluxio-site.properties file path
jobcommand="alluxio fs copyFromLocal /home/gurong1228/bigfile/bigfile_10GB /"

# changed when testing a value for eache parameter
cpu_param=0
mem_param=0
network_param=0

runJob() {
    echo "testing $1 with value $2"
    sed -i "s/$1.*/$1=$2/" $properties_name
    scp $properties_name gurong1228@slave205:${properties_name}
    scp $properties_name gurong1228@slave206:${properties_name} # distribute the properties file to all slaves
    alluxio fs rm /bigfile*
    timeout $runningTime $jobcommand &
    ./getSample.sh &
    wait # instructions above finished 
    echo "bigfile erased"
    arr=($(cat ${sourceFileName} | head -n 1))
    cpu_param=${arr[0]}
    mem_param=${arr[1]} 
    network_param=${arr[2]}
}

judgeResource() {
    Net_percent=$(echo $3 $netSpeed | awk '{printf "%.2f\n", $1 / $2}')
    if [ $(expr $Net_percent \< $1) == 1 ] 
    then
        if [ $(expr $Net_percent \< $2) == 1 ]
        then
            Network_chosen=true
        else
            Memory_chosen=true
        fi
    else
        if [ $(expr $1 \< $2) == 1 ]
        then
            CPU_chosen=true
        else
            Memory_chosen=true
        fi
    fi
}

alluxio fs rm /bigfile*
timeout $runningTime $jobcommand &
./getSample.sh & 
wait
line=($(cat ${sourceFileName} | head -n 1))
cpu_default=${line[0]}
mem_default=${line[1]}
network_default=${line[2]}
cpuCompare=$(echo $cpu_default $diet | awk '{printf "%.2f",$1+$2*$1}')
memCompare=$(echo $mem_default $diet | awk '{printf "%.2f",$1+$2*$1}')
networkCompare=$(echo $network_default $diet | awk '{printf "%.2f",$1+$2*$1}')
echo "under default parameter : $cpu_default $mem_default $network_default"

#judgeResource $cpu_default $mem_default $network_default
CPU_chosen=true
echo "judge finished"
alluxio fs rm /bigfile*

if [ $Network_chosen == true ]; then
    echo "optimize from Network"
    for item in 'ASYNC_THROUGH' 'MUST_CACHE' 'THROUGH' 'CACHE_THROUGH'; do
        param='alluxio.user.file.writetype.default'
        runJob $param $item
        if [ $(expr $network_param \> $networkCompare) == 1 ]; then
            echo " Successfully change the $param's value to $item"
            exit
        fi
    done

    for item in 'CACHE_PROMOTE' 'CACHE' 'NO_CACHE'; do  
        param='alluxio.user.file.readtype.default'
        runJob $param $item
        if [ $(expr $network_param \> $networkCompare) == 1 ]; then
            echo " Successfully change the $param's value to $item"
           exit
        fi
    done

    for item in '5ms' '10ms' '20ms' '50ms' '80ms' '100ms'; do  
        param='alluxio.user.rpc.retry.base.sleep'
        runJob $param $item
        if [ $(expr $network_param \> $networkCompare) == 1 ]; then
            echo " Successfully change the $param's value to $item"
           exit
        fi
    done

    for item in '30sec' '1min' '2min' '4min' '8min' '10min'; do 
        param='alluxio.user.rpc.retry.max.duration' 
        runJob $param $item
        if [ $(expr $network_param \> $networkCompare) == 1 ]; then
            echo " Successfully change the $param's value to $item"     
           exit
        fi
    done

    for item in '5sec' '10sec' '20sec' '30sec' '50sec' '80sec'; do 
        param='alluxio.user.network.data.timeout' 
        runJob $param $item
        if [ $(expr $network_param \> $networkCompare) == 1 ]; then
            echo " Successfully change the $param's value to $item"
           exit
        fi
    done

elif [ $CPU_chosen == true ]; then
    echo "optimize from CPU"
    for item in '0' '1' '2' '4' '8'; do  
        param='alluxio.user.network.netty.worker.threads'
        runJob $param $item
	    if [ $( expr $cpu_param \> $cpuCompare) == 1 ]; then
            echo " Successfully change the $param's value to $item"
           exit
        fi
    done
    
    for item in '512' '1024' '2048' '4096'; do  
        param='alluxio.worker.network.block.reader.threads.max'
        runJob $param $item
	    if [ $( expr $cpu_param \> $cpuCompare) == 1 ]; then
            echo " Successfully change the $param's value to $item"
           exit
        fi
    done
    
    for item in 'ASYNC_THROUGH' 'MUST_CACHE' 'THROUGH' 'CACHE_THROUGH'; do
        param='alluxio.user.file.writetype.default'
        runJob $param $item
	    if [ $( expr $cpu_param \> $cpuCompare) == 1 ]; then
            echo " Successfully change the $param's value to $item"
           exit
        fi
    done

    for item in 'CACHE_PROMOTE' 'CACHE' 'NO_CACHE'; do  
        param='alluxio.user.file.readtype.default'
        runJob $param $item
	    if [ $( expr $cpu_param \> $cpuCompare) == 1 ]; then
            echo " Successfully change the $param's value to $item"
           exit
        fi
    done

else
# Memory_chosen is true
    echo "optimize from Memory"
    for item in 'LocalFirstPolicy' 'MostAvailableFirst' 'RoundRobinPolicy' 'SpecificHostPolicy'; do
        param='alluxio.user.block.write.location.policy.class'  
        runJob $param $item  # parameter optimization for item of param
	    if [ $( expr $cpu_param \> $memCompare) == 1 ]; then
            echo " Successfully change the $param's value to $item"
           exit
        fi
    done
    
    for item in 'ALWAYS' 'NEVER' 'ONCE'; do  
        param='Alluxio.user.file.metadata.load.type'
        runJob $param $item
	    if [ $( expr $cpu_param \> $memCompare) == 1 ]; then
            echo " Successfully change the $param's value to $item"
           exit
        fi
    done
    
    for item in 'LRFUEvictor' 'GreedyEvictor' 'LRUEvictor' 'PartialLRUEvictor'; do  
        param='alluxio.worker.evictor.class'
        runJob $param $item
	    if [ $( expr $cpu_param \> $memCompare) == 1 ]; then
            echo " Successfully change the $param's value to $item"
           exit
        fi
    done
    
    for item in '128' '512KB' '1MB' '2MB' '4MB' '8MB'; do  
        param='alluxio.worker.file.buffer.size'
        runJob $param $item
	    if [ $( expr $cpu_param \> $memCompare) == 1 ]; then
            echo " Successfully change the $param's value to $item"
           exit
        fi
    done

fi
