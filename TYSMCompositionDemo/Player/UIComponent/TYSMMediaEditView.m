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

#import "TYSMMediaEditView.h"

@interface TYSMMediaEditView () <UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIButton *playerButton;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

@end

@implementation TYSMMediaEditView

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        UINib *nib = [UINib nibWithNibName:@"TYSMMediaEditView" bundle:[NSBundle mainBundle]];
        UIView *view = [[nib instantiateWithOwner:self options:nil] objectAtIndex:0];
        [self addSubview:view];
        self.scrollView.delegate = self;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)buildScrubber:(NSArray<UIImage *> *)images {
    
    if (self.scrollView.subviews.count) {
        for (UIView *subView in self.scrollView.subviews) {
            [subView removeFromSuperview];
        }
        self.scrollView.contentSize = CGSizeZero;
        self.scrollView.contentInset = UIEdgeInsetsZero;
    }
    
    CGFloat currentX = 0.0f;
    
    CGSize imageSize = [images[0] size];
    
    CGRect imageRect = CGRectMake(currentX, 0, imageSize.width, imageSize.height);
    
    CGFloat imageWidth = CGRectGetWidth(imageRect) * images.count;
    self.scrollView.contentSize = CGSizeMake(imageWidth, imageRect.size.height);
    self.scrollView.contentInset = UIEdgeInsetsMake(0, 0 , 0, CGRectGetWidth(self.scrollView.bounds));

    for (NSUInteger i = 0; i < images.count; i++) {
        UIImageView *imgView = [[UIImageView alloc] initWithImage:images[i]];
//        第一张图片在 scrollview 中间出现
        if (i == 0) {
            currentX += CGRectGetWidth(self.scrollView.bounds)/2;
        }
        
        imgView.frame = CGRectMake(currentX, 0, imageSize.width, imageSize.width);

        [self.scrollView addSubview:imgView];
        currentX += imageSize.width;
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    self.playerButton.selected = YES;
    [self tapPlaybutton:self.playerButton];
    if (self.delegate && [self.delegate respondsToSelector:@selector(handleScrollOffset:)]) {
        [self.delegate handleScrollOffset:scrollView.contentOffset.x];
    }
}

- (IBAction)tapPlaybutton:(UIButton *)sender {
    sender.selected = !sender.selected;
    
    [sender setTitle:sender.selected?@"暂停":@"播放"
            forState:sender.selected?UIControlStateSelected:UIControlStateNormal];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(handlePlayerButton:)]) {
        [self.delegate handlePlayerButton:sender.selected];
    }
    
}

- (void)updateTimeLabel:(NSString *)timeString {
    [self.timeLabel setText:timeString];
}

- (void)setScroll:(CGFloat)offset {
    CGRect scrollBounds = self.scrollView.bounds;
    scrollBounds.origin = CGPointMake(offset, 0);
    self.scrollView.bounds = scrollBounds;
}

- (IBAction)tapSplitRange:(UIButton *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(handleSplitRange)]) {
        [self.delegate handleSplitRange];
    }
}

- (IBAction)tapAppendVideoButton:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(handleAppendVideo)]) {
        [self.delegate handleAppendVideo];
    }
}

- (void)updateProgress:(CGFloat)progress {
    [self.progressView setProgress:progress];
}
@end
