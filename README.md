# TYSMCompositionDemo
# 简单的视频剪辑 demo AVComposition 

## 本 demo 主要做了以下事情：
1. Avcomposition :
  * 合成两个视频展示到屏幕上
  * 轨道头部裁剪视频（固定 20 秒）
  * 轨道尾部追加视频
  * 变速
  * 调音
  （会陆续增加）

2. 底部编辑 View
  * scrollview 展示幻灯片/缩略图
  * 拖动 scrollview 等同 seek 时间
  * 播放时 scrollview 跟随移动
  * 展示时间

3. 合成输出
  * 输出到系统相册
  * 可后台运行

4. 硬解播放器：
  * 通过硬解得到一帧 CVPixelBuffer 
  * 交给 OpenGLES 渲染呈现到屏幕
  * 提供基本的播放功能


### 编辑的交互细节略多，有 bug 见谅。

![](https://github.com/cookies-J/TYSMCompositionDemo/blob/master/demo.gif)



