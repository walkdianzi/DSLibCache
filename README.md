# DSLibCache

缓存cocoapods生成的静态库，不用每次都编译

## 安装xcodeproj

```
gem install xcodeproj
```

## 使用

### 脚本处理
在工程的`Build Phases`里新增`Run Script`，内容为`"${SRCROOT}/build.sh"`，位置在`[CP]Check Pods Manifest.lock`后面。

然后在工程目录下放置`build.sh`、`info.sh`和`remove.rb`。

修改`remove`里的`DSDemo.xcodeproj`和`DSDemo_Example`为你实际的工程名和target名。

修改`build.sh`里的`/Users/dasheng/Work`目录为你实际想要放置的目录。

选择当前scheme，`Edit Scheme`->`Build`->`Find Implicit Dependencies`的勾选去掉。

### 执行
在每次`Pod update`或`Pod install`执行完之后执行`sh info.sh`。


## 输出

下面是log输出：

表示从Podfile.lock读出所有pod的名字跟版本，写入PodInfo.txt的时间
```
write PodInfo.txt duration:时间
```

表示当前所有的pod都build的时间
```
dasheng build Pod duration:时间
```

表示执行失败的pod
```
dasheng buildFail:PodName
```

表示当前build的pod名和版本
```
dasheng beginbuild PodName PodVersion
```