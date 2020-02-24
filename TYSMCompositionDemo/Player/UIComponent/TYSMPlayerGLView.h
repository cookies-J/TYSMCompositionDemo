//
//  TYSMPlayerGLView.h
//  MLife
//
//  Created by jele lam on 31/1/2020.
//  Copyright © 2020 CookiesJ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

NS_ASSUME_NONNULL_BEGIN

@interface TYSMPlayerGLView : UIView
- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer;
@end

NS_ASSUME_NONNULL_END
