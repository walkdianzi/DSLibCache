export LC_ALL=en_US.UTF-8
#!/bin/sh

#是否是模拟器
buildDir=${CONFIGURATION_BUILD_DIR}
folderName=$(echo ${buildDir##*/Build/Products/})
result=$(echo ${folderName} | grep "iphonesimulator")
if [ -n "${result}" ]
then
  export isSimulator=true
else
  export isSimulator=false
fi
export device=""
if [ "${isSimulator}" = true ] 
then
  device="iphonesimulator"
else
  device="iphoneos"
fi

#缓存目录
export desFolder="/Users/dasheng/Work/podLib/"${folderName}
if [ ! -d "$desFolder" ]
then
  mkdir -p $desFolder
fi

#编译目录
export podBuildFolder="/Users/dasheng/Work/PodBuild/${CONFIGURATION}-$device"
if [ ! -d "$podBuildFolder" ]
then
  mkdir -p $podBuildFolder
fi

export alwaysBuildStr=""
if [ -f "alwaysBuildPods.txt" ]
then
  alwaysBuildStr=$(cat alwaysBuildPods.txt)
fi

buildAndCopy() {
  folderVersion=${desFolder}"/$1/$2"
  podName=$1
  podVersion=$2
  isCache=$3

  #如果已经编译生成过的则copy并返回
  if [ -d "${podBuildFolder}/${podName}" ]
  then
    if [ "${isCache}" = true ] && [ ! -d "$folderVersion" ]
    then
      mkdir -p "$folderVersion"
      cp -fR "${podBuildFolder}/$podName" "$folderVersion"
    fi
    cp -fR "${podBuildFolder}/$podName" "${CONFIGURATION_BUILD_DIR}"
    return
  fi

  echo "dasheng beginbuild $podName $podVersion"
  if [ "${isSimulator}" = true ] 
  then
    xcodebuild build -project Pods/Pods.xcodeproj -target $podName -sdk iphonesimulator SYMROOT="/Users/dasheng/Work/PodBuild" -configuration ${CONFIGURATION} ONLY_ACTIVE_ARCH=NO
  else
    xcodebuild build -project Pods/Pods.xcodeproj -target $podName SYMROOT="/Users/dasheng/Work/PodBuild" -configuration ${CONFIGURATION} ONLY_ACTIVE_ARCH=NO
  fi

  #如果build生成了此版本的pod，则在本地创建目录并拷贝进来
  if [ -d "${podBuildFolder}/${podName}" ]
  then
    if [ "${isCache}" = true ]
    then
      mkdir -p "$folderVersion"
      cp -fR "${podBuildFolder}/$podName" "$folderVersion"
    fi
    cp -fR "${podBuildFolder}/$podName" "${CONFIGURATION_BUILD_DIR}"
  else
    echo "dasheng buildFail:$podName"
  fi
}


#如果本地存在则复制到buildPod目录和${CONFIGURATION_BUILD_DIR}目录
echo "" > buildPodInfo.txt
cat podInfo.txt | while read line
do
    OLD_IFS="$IFS"
    IFS=':' 
    arr=($line)
    IFS="$OLD_IFS"
    podName=${arr[0]}
    podVersion=${arr[1]}
    folderVersion=${desFolder}"/$podName/$podVersion"
    result=$(echo $alwaysBuildStr | grep "::${podName}::")
    if [ -n "$podName" ] && [ -n "$podVersion" ]
    then
      if [ -d "$folderVersion" ] && [ -z "$result" ]
      then
        cp -fR "$folderVersion/$podName" "${podBuildFolder}"
        cp -fR "$folderVersion/$podName" "${CONFIGURATION_BUILD_DIR}"
      else
        echo "$podName:$podVersion">>buildPodInfo.txt
      fi
    fi
done


cat buildPodInfo.txt | while read line
do
    OLD_IFS="$IFS"
    IFS=':' 
    arr=($line)
    IFS="$OLD_IFS"
    podName=${arr[0]}
    podVersion=${arr[1]}
    if [ -n "$podName" ] && [ -n "$podVersion" ] && [ -n "$podBuildFolder/$podName" ]
    then
      rm -rf "$podBuildFolder/$podName"
    fi
done


timeNow=$(date +%s)
cat buildPodInfo.txt | while read line
do
    OLD_IFS="$IFS"
    IFS=':' 
    arr=($line)
    IFS="$OLD_IFS"
    podName=${arr[0]}
    podVersion=${arr[1]}
    if [ -n "$podName" ] && [ -n "$podVersion" ]
    then
      result=$(echo $alwaysBuildStr | grep "::${podName}::")
      #是否缓存，每次都需要重新编译的不缓存
      if [ -n "$result" ]
      then
        buildAndCopy "$podName" "$podVersion" false
      else
        buildAndCopy "$podName" "$podVersion" true
      fi
    fi
done
timeNow2=$(date +%s)
duration=$(($timeNow2 - $timeNow))
echo "dasheng build Pod duration:"$duration

rm -rf buildPodInfo.txt
