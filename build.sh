export LC_ALL=en_US.UTF-8
#!/bin/sh

rm -rf "/Users/dasheng/Work/PodBuild"

buildAndCopy() {
  isSimulator=$1
  isCache=$2
  folderVersion=$3
  podName=$4
  podVersion=$5

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
    echo "dasheng buildFail:$podName"
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


timeNow=$(date +%s)
cat podInfo.txt | while read line
do
    IFS=':' 
    arr=($line)
    podName=${arr[0]}
    podVersion=${arr[1]}
    if [ -n "$podName" ] && [ -n "$podVersion" ]
    then
      if [ -f "alwaysBuildPods.txt" ]
      then
        result=$(cat alwaysBuildPods.txt | grep "::${podName}::")
        #是否缓存，每次都需要重新编译的不缓存
        if [ -n "$result" ]
        then
          copyLib "$podName" "$podVersion" false
        else
          copyLib "$podName" "$podVersion" true
        fi
      else
        copyLib "$podName" "$podVersion" true
      fi
    fi
done
timeNow2=$(date +%s)
duration=$(($timeNow2 - $timeNow))
echo "dasheng build Pod duration:"$duration
