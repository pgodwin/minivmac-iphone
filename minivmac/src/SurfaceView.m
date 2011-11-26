/** 
 *  @file SurfaceView.m
 *  Implementation of SurfaceView
 */

#import "SurfaceView.h"
#import <QuartzCore/QuartzCore.h>


#import <OpenGLES/EAGLDrawable.h>
#import "cocos2d.h"
#import "CNFGGLOB.h"


PixelFormat kPixelFormat565L = "565L";
PixelFormat kPixelFormatARGB = "ARGB";

BOOL useColor;

NSLock* _lock = nil;

// kCAFilterNearest, kCAFilterLinear
#define kDefaultScalingFilter kCAFilterLinear 



@implementation SurfaceView


// You must implement this


- (id)initWithFrame:(CGRect)frame {
    return [self initWithFrame:frame pixelFormat:kPixelFormat565L surfaceSize:frame.size magnificationFilter:kDefaultScalingFilter minificationFilter:kDefaultScalingFilter];
}

- (id)initWithFrame:(CGRect)frame surfaceSize:(CGSize)size {
    return [self initWithFrame:frame pixelFormat:kPixelFormat565L surfaceSize:size magnificationFilter:kDefaultScalingFilter minificationFilter:kDefaultScalingFilter];
}

- (id)initWithFrame:(CGRect)frame pixelFormat:(PixelFormat)pxf {
    return [self initWithFrame:frame pixelFormat:pxf surfaceSize:frame.size magnificationFilter:kDefaultScalingFilter minificationFilter:kDefaultScalingFilter];
}

- (id)initWithFrame:(CGRect)frame pixelFormat:(PixelFormat)pxf surfaceSize:(CGSize)size {
    return [self initWithFrame:frame pixelFormat:pxf surfaceSize:size magnificationFilter:kDefaultScalingFilter minificationFilter:kDefaultScalingFilter];
}

- (id)initWithFrame:(CGRect)frame pixelFormat:(PixelFormat)pxf scalingFilter:(NSString*)scalingFilter {
    return [self initWithFrame:frame pixelFormat:pxf surfaceSize:frame.size magnificationFilter:scalingFilter minificationFilter:scalingFilter];
}

- (id)initWithFrame:(CGRect)frame pixelFormat:(PixelFormat)pxf surfaceSize:(CGSize)size scalingFilter:(NSString*)scalingFilter {
    return [self initWithFrame:frame pixelFormat:pxf surfaceSize:size magnificationFilter:scalingFilter minificationFilter:scalingFilter];
}

- (id)initWithFrame:(CGRect)frame pixelFormat:(PixelFormat)pxf magnificationFilter:(NSString*)magnificationFilter minificationFilter:(NSString*)minificationFilter {
    return [self initWithFrame:frame pixelFormat:pxf surfaceSize:frame.size magnificationFilter:magnificationFilter minificationFilter:minificationFilter];
}

// real initializer

- (id)initWithFrame:(CGRect)frame pixelFormat:(PixelFormat)pxf surfaceSize:(CGSize)size magnificationFilter:(NSString*)magnificationFilter minificationFilter:(NSString*)minificationFilter {
    // set values
    pixelFormat = pxf;
    surfaceSize = size;
        
    if (self = [super initWithFrame:frame]) {
    
        NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:
                           // [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                           //  [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                           //  [NSNumber numberWithBool:YES], kCVPixelBufferOpenGLCompatibilityKey,
                           nil];
        
        
        CVPixelBufferCreate(kCFAllocatorDefault, vMacScreenWidth, vMacScreenHeight, 
                            kCVPixelFormatType_32ARGB, (CFDictionaryRef)d, &surfaceBuffer);
        
        
        CVPixelBufferLockBaseAddress(surfaceBuffer,0); 

        
        pixels = (uint8_t *)CVPixelBufferGetBaseAddress(surfaceBuffer);
        
        CVPixelBufferUnlockBaseAddress(surfaceBuffer, 0);
        
                
        surfaceLayer = [[CALayer layer] retain];  
        
        [surfaceLayer setEdgeAntialiasingMask:15];
        [surfaceLayer setOpaque:YES];
        [surfaceLayer setFrame:[self fixFrame:frame]];
        
        [surfaceLayer setMagnificationFilter:magnificationFilter];
        [surfaceLayer setMinificationFilter:minificationFilter];
    

        [[self layer] addSublayer:surfaceLayer];
              
    }
    return self;
}

- (void)dealloc {
    [surfaceLayer release];
    [super dealloc];
}




- (void)drawRect:(CGRect)rect {
    

    // Do not remove this empty function, or you'll break it
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB(); 
    CGColorSpaceRef colorSpace;
    CGDataProviderRef provider;
    CGImageRef cgImage;
    CGContextRef bitmap;
    

    static unsigned char colorTable[] = {255, 255, 255, 0, 0, 0, 0};
   
    provider = CGDataProviderCreateWithData(NULL, pixels, vMacScreenNumBytes, NULL);
    
    if (!useColor) {
        
        colorSpace = CGColorSpaceCreateIndexed(rgbColorSpace, 1, colorTable);
        
        cgImage = CGImageCreate(vMacScreenWidth, vMacScreenHeight, 8, 8, vMacScreenByteWidth, colorSpace, 0, provider, NULL, false, kCGRenderingIntentDefault);
        
        CGColorSpaceRelease(colorSpace);
    }
    else
    {
        
        //bitmap = CGBitmapContextCreate(pixels, vMacScreenWidth, vMacScreenHeight, 8, vMacScreenWidth * 4, rgbColorSpace,  kCGImageAlphaPremultipliedLast);
        bitmap = CGBitmapContextCreate(pixels, vMacScreenWidth, vMacScreenHeight, 8, vMacScreenWidth * 4, rgbColorSpace,  kCGImageAlphaPremultipliedLast);
        
        cgImage = CGBitmapContextCreateImage(bitmap);
        
        //cgImage = CGImageCreate(vMacScreenWidth, vMacScreenHeight, 3, 3, vMacScreenWidth * 4, rgbColorSpace, 0, provider, NULL, false, kCGRenderingIntentDefault);
        
        CFRelease(bitmap);
    }


    [surfaceLayer setContents:(id)cgImage];
    [surfaceLayer setFrame:rect];
    
    CGColorSpaceRelease(rgbColorSpace);    
    CGDataProviderRelease(provider);
    CGImageRelease(cgImage);
}





#if 0
#pragma mark -
#pragma mark Accessors
#endif

- (void*)pixels {
    return pixels;
}

- (void)useColorMode:(BOOL)color {
    useColor = color;
}

- (PixelFormat)pixelFormat {
    return pixelFormat;
}

- (int)pixelSize {
    if (pixelFormat == kPixelFormat565L) return 2;
    //if (pixelFormat == kPixelFormat1555) return 2;
    //if (pixelFormat == kPixelFormat4444) return 2;
    //if (pixelFormat == kPixelFormat555L) return 2;
    //if (pixelFormat == kPixelFormat565S) return 2;
    //if (pixelFormat == kPixelFormat555S) return 2;
    //if (pixelFormat == kPixelFormat155S) return 2;
    if (pixelFormat == kPixelFormatARGB) return 4;
    //if (pixelFormat == kPixelFormatABGR) return 4;
    //if (pixelFormat == kPixelFormatRGBA) return 4;
    // unknown, 4 should be safe
    return 4;
    /*
    if (pixelFormat == kPixelFormatA23B) return 4;
    if (pixelFormat == kPixelFormatA46B) return 4;
    if (pixelFormat == kPixelFormatYUV2) return 4;
    if (pixelFormat == kPixelFormatB23S) return 4;
    if (pixelFormat == kPixelFormatSVUY) return 4;
    if (pixelFormat == kPixelFormatV024) return 4;
    if (pixelFormat == kPixelFormat024Y) return 4;
    if (pixelFormat == kPixelFormat804V) return 4;
    */
}

- (CGRect)frame {
    return fakeFrame;
}

- (void)setFrame:(CGRect)frame {
    fakeFrame = frame;
    frame = [self fixFrame:frame];
    [super setFrame:frame];
    if (surfaceLayer) [surfaceLayer setFrame:frame];
}

- (NSString*)magnificationFilter {
    return [surfaceLayer magnificationFilter];
}

- (void)setMagnificationFilter:(NSString*)magnificationFilter {
    [surfaceLayer setMagnificationFilter:magnificationFilter];
}

- (NSString*)minificationFilter {
    return [surfaceLayer minificationFilter];
}

- (void)setMinificationFilter:(NSString*)minificationFilter {
    [surfaceLayer setMinificationFilter:minificationFilter];
}

- (CGRect)fixFrame: (CGRect)frame {
    // fix CoreSurface bugginess
    int p = self.pixelSize;
    frame.origin.x /= p;
    frame.origin.y /= p;
    /*if (frame.size.height == surfaceSize.height && frame.size.width == surfaceSize.width)
        frame.size.height += 1;*/
    return frame;
}



@end
