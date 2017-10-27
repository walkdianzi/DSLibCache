export LC_ALL=en_US.UTF-8
#!/bin/sh

ruby remove.rb
rm -rf "/Users/dasheng/Work/PodBuild"

if [ ! -f "noBuildSuccess.txt" ]
then
  echo "" > noBuildSuccess.txt
fi
noBuildPods=$(cat noBuildSuccess.txt)
buildAndCopy() {
  isSimulator=$1
  isCache=$2
  folderVersion=$3
  podName=$4
  podVersion=$5

  #如果是不需要编译生成静态库的则返回
  result=$(echo $noBuildPods | grep "${podName}$")
  if [ -n "$result" ]
  then
    echo "dasheng noBuild $podName"
    return
  fi

  #如果已经编译生成过的则copy并返回
  device=""
  if [ "${isSimulator}" = true ] 
  then
    device="iphonesimulator"
  else
    device="iphoneos"
  fi
  sourceFolder="/Users/dasheng/Work/PodBuild/${CONFIGURATION}-$device"
  if [ -d "${sourceFolder}/${podName}" ]
  then
    if [ "${isCache}" = true ]
    then
      mkdir -p "$folderVersion"
      cp -fR "${sourceFolder}/$podName" "$folderVersion"
    fi
    cp -fR "${sourceFolder}/$podName" "${CONFIGURATION_BUILD_DIR}"
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
  if [ -d "${sourceFolder}/${podName}" ]
  then
    if [ "${isCache}" = true ]
    then
      mkdir -p "$folderVersion"
      cp -fR "${sourceFolder}/$podName" "$folderVersion"
    fi
    cp -fR "${sourceFolder}/$podName" "${CONFIGURATION_BUILD_DIR}"
  else
    echo $podName >> noBuildSuccess.txt
  fi
}

copyLib() {
  buildDir=${CONFIGURATION_BUILD_DIR}
  folderName=$(echo ${buildDir##*/Build/Products/})
  result=$(echo ${folderName} | grep "iphonesimulator")
  if [ -n "${result}" ]
  then
    isSimulator=true
  else
    isSimulator=false
  fi

  desFolder="/Users/dasheng/Work/podLib/"${folderName}
  if [ ! -d "$desFolder" ]
  then
    mkdir -p $desFolder
  fi
  
  folderVersion=${desFolder}"/$1/$2"
  #如果本地不存在此版本的pod，则运行build生成
  if [ ! -d "$folderVersion" ]
  then
    #是否缓存，每次都需要重新编译的不缓存（比如:path =>和:git =>）
    buildAndCopy ${isSimulator} $3 $folderVersion $1 $2
  else
    if [ -d "$folderVersion/$1" ]
    then
      cp -fR "$folderVersion/$1" "${CONFIGURATION_BUILD_DIR}"
    fi
  fi
}

echo "" > podInfo.txt
echo "" > rebuild.txt
getRebuildPod=false

export rebuildPodStr="::"
writeRebuild() {
    line=$1
    firstChar=$(echo "${line:0:1}")
    if [ -n "$firstChar" ] && [ "$firstChar" != ":" ]
    then
      podName=$(echo "${line}" | grep -Eo '[a-zA-Z0-9_]+')
      rebuildPodStr=${rebuildPodStr}${podName}"::"
      echo $rebuildPodStr > rebuild.txt
    fi
}

timeNow=$(date +%s)
cat Podfile.lock | while read line
do
    podName=$(echo $line | grep -Eo '\- [a-zA-Z0-9_+]+' | grep -Eo '[a-zA-Z0-9_+]+')
    podVersion=$(echo $line | grep -Eo '\([a-zA-Z0-9.= -]+\)' | grep -Eo '[a-zA-Z0-9.-]+')
    result=$(cat podInfo.txt | grep "${podName}")
    if [ -n "$podName" ] && [ -n "$podVersion" ] && [ -z "${result}" ]
    then
      echo "$podName:$podVersion" >> podInfo.txt
    fi

    if [ "$line"x = "CHECKOUT OPTIONS:"x ]
    then
      getRebuildPod=false
    fi

    if [ "${getRebuildPod}" = true ]
    then
      writeRebuild "$line"
    fi

    if [ "$line"x = "EXTERNAL SOURCES:"x ]
    then
      getRebuildPod=true
    fi
done
timeNow2=$(date +%s)
duration=$(($timeNow2 - $timeNow))
echo "write PodInfo.txt duration:"$duration

timeNow=$(date +%M%S)
echo "begin build Pod"$timeNow
cat podInfo.txt | while read line
do
    IFS=':' 
    arr=($line)
    podName=${arr[0]}
    podVersion=${arr[1]}
    if [ -n "$podName" ] && [ -n "$podVersion" ]
    then
      result=$(cat rebuild.txt | grep "::${podName}::")
      #是否缓存，每次都需要重新编译的不缓存
      if [ -n "$result" ]
      then
        copyLib "$podName" "$podVersion" false
      else
        copyLib "$podName" "$podVersion" true
      fi
    fi
done
timeNow=$(date +%M%S)
echo "end build Pod"$timeNow

