//
//  SGFFVideoOutput.m
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFVideoOutput.h"
#import "SGFFVideoOutputRender.h"
#import "SGGLView.h"
#import "SGGLProgramYUV420.h"
#import "SGGLNormalModel.h"
#import "SGGLTextureYUV420.h"
#import "SGPlatform.h"

@interface SGFFVideoOutput ()

@property (nonatomic, strong) SGGLView * glView;
@property (nonatomic, strong) SGGLProgramYUV420 * program;
@property (nonatomic, strong) SGGLNormalModel * model;
@property (nonatomic, strong) SGGLTextureYUV420 * texture;
@property (nonatomic, strong) SGPLFDisplayLink * displayLink;
@property (nonatomic, strong) SGFFVideoOutputRender * currentRender;

@end

@implementation SGFFVideoOutput

- (id <SGFFOutputRender>)renderWithFrame:(id <SGFFFrame>)frame
{
    SGFFVideoOutputRender * render = [[SGFFObjectPool sharePool] objectWithClass:[SGFFVideoOutputRender class]];
    [render updateVideoFrame:frame.videoFrame];
    return render;
}

- (instancetype)init
{
    if (self = [super init])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.glView = [[SGGLView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
            [self.delegate videoOutputDidChangeDisplayView:self];
        });
        self.displayLink = [SGPLFDisplayLink displayLinkWithTarget:self selector:@selector(displayLinkAction)];
        self.displayLink.preferredFramesPerSecond = 25;
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        self.displayLink.paused = NO;
    }
    return self;
}

- (SGPLFView *)displayView
{
    return self.glView;
}

- (void)displayLinkAction
{
    self.currentRender = [self.renderSource outputFecthRender:self];
    if (self.currentRender)
    {
        SGFFVideoOutputRender * render = self.currentRender;
        [self.glView display:^{
            if (!self.texture) {
                self.texture = [[SGGLTextureYUV420 alloc] init];
            }
            if (!self.program) {
                self.program = [SGGLProgramYUV420 program];
            }
            if (!self.model) {
                self.model = [SGGLNormalModel model];
            }
            [self.program use];
            [self.program bindVariable];
            [self.texture updateTexture:render];
            [self.model bindPositionLocation:self.program.position_location
                        textureCoordLocation:self.program.texture_coord_location
                           textureRotateType:SGGLModelTextureRotateType0];
            [self.program updateMatrix:GLKMatrix4Identity];
            glDrawElements(GL_TRIANGLES, self.model.index_count, GL_UNSIGNED_SHORT, 0);
            [render unlock];
        }];
    }
}

@end
