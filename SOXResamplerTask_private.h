//
//  SOXResamplerTask_private.h
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/13/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

#import "SOXResamplerTask.h"

@class SOXResampler;

@interface SOXResamplerTask ()

@property (nonatomic, strong, readonly) SOXResampler *resampler;
@property (nonatomic, strong, readonly) NSURL *URL;

@property (readonly, getter = isCanceled) BOOL canceled;

//@property (nonatomic, readonly) const char *path;

/* Private Initializers */
/* neither url nor encoder can be nil */
- (instancetype)initWithURL:(NSURL *)url resampler:(SOXResampler *)resampler delegate:(id<SOXResamplerTaskDelegate>)delegate;

/* Delegate Notification */
- (void)didCompleteWithError:(NSError *)error;

@end
