export LC_ALL=en_US.UTF-8
#!/bin/sh

#读取所有的podName和PodVersion存入podInfo.txt，每次都需build的pod存入rebuild.txt
timeNow=$(date +%s)
echo "" > podInfo.txt
echo "" > alwaysBuildPods.txt
xcodebuild -project Pods/Pods.xcodeproj -list > targetsInfo.txt
python podInfo.py
timeNow2=$(date +%s)
duration=$(($timeNow2 - $timeNow))
echo "write PodInfo.txt duration:"$duration

ruby remove.rb