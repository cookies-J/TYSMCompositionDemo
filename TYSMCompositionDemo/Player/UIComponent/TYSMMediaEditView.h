//
//  MIT License
//
//  Copyright (c) 2014 Bob McCune http://bobmccune.com/
//  Copyright (c) 2014 TapHarmonic, LLC http://tapharmonic.com/
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

@protocol TYSMMediaEditViewDelegate <NSObject>
/** 回调偏移量，用于 seek 时间
 @param offset 偏移量
*/
- (void)handleScrollOffset:(CGFloat)offset;

/** 播放按钮
 @param isPlay yes 暂停，no 播放
 */
- (void)handlePlayerButton:(BOOL)isPlay;

/**
 点击裁剪按钮
 */
- (void)handleSplitRange;

/**
 点击追加视频
 */
- (void)handleAppendVideo;


/**
 变速
 @param isSlowDown 是否减速
 */
- (void)handleTransmitVideo:(BOOL)isSlowDown;

@end

@interface TYSMMediaEditView : UIView
@property (nonatomic, weak) id <TYSMMediaEditViewDelegate> delegate;
// 生成幻灯片
- (void)buildScrubber:(NSArray <UIImage *> *)images;
// 更新时间
- (void)updateTimeLabel:(NSString *)timeString;
// 播放的时候 scrollView 跟着滚动
- (void)setScroll:(CGFloat)offset;
// 更新转码进度
- (void)updateProgress:(CGFloat)progress;
@end
