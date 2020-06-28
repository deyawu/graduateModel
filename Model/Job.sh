sourceFileName="resource.txt"
jobcommand="alluxio fs copyFromLocal /home/gurong1228/bigfile/bigfile_10GB /"
./ruleModel.sh   # running single job to optimize the parameters

echo "restart the job after the parameter optimization "

alluxio fs rm /bigfile*
time $jobcommand &
./getSample.sh &
wait
line=($(cat ${sourceFileName} | head -n 1))
echo "the average resource occupied partly are (some samples from the beginning):"
echo "CPU ${line[0]}  Memory ${line[1]}  Network ${line[2]}"

