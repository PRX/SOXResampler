//
//  SOXResampler.h
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/13/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

@import Foundation;

extern NSString * const SOXResamplerErrorDomain;

typedef NS_ENUM(NSInteger, SOXResamplerError) {
  SOXResamplerErrorUnknown = -1,
  SOXResamplerErrorCancelled = -999
};

@protocol SOXResamplerDelegate;
@class SOXResamplerConfiguration, SOXResamplerTask;

@interface SOXResampler : NSObject

+ (instancetype)resamplerWithConfiguration:(SOXResamplerConfiguration *)configuration;
+ (instancetype)resamplerWithConfiguration:(SOXResamplerConfiguration *)configuration delegate:(id<SOXResamplerDelegate>)delegate operationQueue:(NSOperationQueue *)queue;
+ (instancetype)sharedResampler;

@property (weak) id <SOXResamplerDelegate> delegate;
@property (copy, readonly) SOXResamplerConfiguration *configuration;

- (SOXResamplerTask *)taskWithURL:(NSURL *)url;

@end

@protocol SOXResamplerDelegate <NSObject>

@required

//- (void)encoder:(TWLEncoder *)encoder task:(TWLEncoderTask *)task didWriteFrames:(int64_t)framesWritten totalFramesWritten:(int64_t)totalFramesWritten totalFrameExpectedToWrite:(int64_t)totalFramesExpectedToWrite bytesWritten:(int64_t)bytessWritten totalBytesWritten:(int64_t)totalBytesWritten;
- (void)resampler:(SOXResampler *)resampler task:(SOXResamplerTask *)task didFinishResamplingToURL:(NSURL *)location;

@end