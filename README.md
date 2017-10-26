# DSLibCache

缓存cocoapods生成的静态库，不用每次都编译

## 安装xcodeproj

```
gem install xcodeproj
```

## 使用

在工程的`Build Phases`里新增`Run Script`，为了运行ruby，需要修改Shell后面的`/bin/sh`为`/bin/bash -l`。

然后在工程目录下放置`copy.sh`和`remove`。

修改`remove`里的`DSDemo.xcodeproj`和`DSDemo_Example`为你实际的工程名和target名。

修改`copy.sh`里的`/Users/dasheng/Work`目录为你实际想要放置的目录