# English Reader iOS App

这是一个 SwiftUI iOS 英文小说阅读器工程骨架，支持：

- 导入 `.txt` 和 `.epub`
- EPUB 章节解析
- 点击英文单词查询中文释义
- 内置离线词典 JSON
- 字号、行距、背景主题、亮度调节
- 章节列表跳转
- 滑动翻页
- 可选音量键翻页

## 使用方式

当前环境是 Windows，不能直接编译 iOS App。请在 macOS 上用 Xcode 打开：

```text
EnglishReader.xcodeproj
```

首次打开时 Xcode 会拉取 `ZIPFoundation` Swift Package，用于解压 EPUB 文件。

## GitHub Actions 编译

项目已包含 GitHub Actions 配置：

```text
.github/workflows/ios-build.yml
```

推送到 GitHub 的 `main` 分支后，会使用 `macos-15` runner 编译 iOS Simulator 版本，并上传：

```text
EnglishReader-simulator-app.zip
xcodebuild.log
```

这个 workflow 不需要 Apple 开发者证书，因为它只构建模拟器版本。真机安装、TestFlight 或 App Store 包需要额外配置 Apple 证书和 provisioning profile。

## 离线词典

内置词典文件在：

```text
EnglishReader/Resources/dictionary_seed.json
```

现在放的是小型种子词库，用来验证点击查词流程。要做到“基本每个常见英文单词都有中文意思”，需要替换为完整英汉词库。格式保持为：

```json
[
  {
    "word": "example",
    "phonetic": "/ig'zampel/",
    "translation": "n. 例子；样本",
    "definition": "A representative form or pattern."
  }
]
```

替换文件名不变即可，无需联网查询。

## 音量键翻页说明

iOS 没有公开的“音量键按下事件”API。这里采用监听系统音量变化的方式实现翻页，阅读设置里可以开启或关闭。这个功能适合自用版本；如果计划上架 App Store，建议谨慎评估审核风险，或改成蓝牙键盘/耳机遥控翻页。

## 已知后续工作

- 替换完整离线英汉词典
- 增加书签、阅读进度同步、搜索全文
- 增加横屏双页、更多主题
- 针对大体积 EPUB 做分章节懒加载
