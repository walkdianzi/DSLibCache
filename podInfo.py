#!/usr/bin/python
#-*- coding: utf-8 -*-
#encoding=utf-8

import os
import os.path
import string,re,sys
import shutil

alwaysBuildPodStr="::"
def writeAlwaysBuild(line):
    if line[0] != ":":
        podName = re.findall(r"\b[\w+-]+|$", line)[0]
        alwaysBuildPodStr=alwaysBuildPodStr+podName+"::"

#获取所有要build的target
targetsFile=open("targetsInfo.txt")
beginWrite=False
targetsMap={}
for line in targetsFile:
    line=line.strip()
    if line == "Targets:":
        beginWrite=True
        continue
    if line == "Build Configurations:":
        break
    if beginWrite==True and len(line)>0:
        targetsMap[line]=True

#从Podfile.lock中读取所有的pod，只有上面targetsMap中的target需要build，每次都需build的pod存入alwaysBuildPods.txt
file = open("Podfile.lock")
f=open('podInfo.txt','a')
getRebuildPod=False
podInfoString=""
for line in file:
    podName = re.findall(r"(?<=- )\b[\w+-]+|$", line)[0]
    podVersion = re.findall(r"(?<=\()\b[a-zA-Z0-9.-]+(?=\))|$", line)[0]
    if podName and podVersion and podInfoString.find(podName+":"+podVersion+"\n") == -1 and targetsMap.has_key(podName):
        podInfoString=podInfoString+podName+":"+podVersion+"\n"
        f.write(podName+":"+podVersion+"\n")
    if line.find("CHECKOUT OPTIONS:") > -1:
        getRebuildPod=False
    if getRebuildPod==True:
        writeAlwaysBuild(line)
    if line.find("EXTERNAL SOURCES:") > -1:
        getRebuildPod=True


os.remove("targetsInfo.txt")
if alwaysBuildPodStr=="::":
    os.remove("alwaysBuildPods.txt")
else:
    alwaysBuildFile=open('alwaysBuildPods.txt','a')
    alwaysBuildFile.write(alwaysBuildPodStr)