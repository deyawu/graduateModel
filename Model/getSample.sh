SampleDots=10 
sourceFileName='resource.txt'

cpuRate=0
memRate=0
networkRate=0

for((i=0;i<$SampleDots;i++)); do
    ./getResource.sh # To get Resource Rate 
    arr=($(cat ${sourceFileName} | head -n 1))
    cpuRate=$(echo $cpuRate ${arr[0]} | awk '{printf "%.2f\n",$1 + $2}')
    memRate=$(echo $memRate ${arr[1]} | awk '{printf "%.2f\n",$1 + $2}')
    networkRate=$(echo $networkRate ${arr[2]} | awk '{printf "%.2f\n",$1 + $2}')
done
cpuRate=$(echo $cpuRate $SampleDots | awk '{printf "%.2f\n", $1 / $2}')
memRate=$(echo $memRate $SampleDots | awk '{printf "%.2f\n", $1 / $2}')
networkRate=$(echo $networkRate $SampleDots | awk '{printf "%.2f\n", $1 / $2}')
echo "Average rate: $cpuRate  $memRate $networkRate"
echo "$cpuRate $memRate $networkRate" > $sourceFileName
