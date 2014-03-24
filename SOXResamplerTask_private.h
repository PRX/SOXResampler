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

@property (nonatomic, readonly) const char *path;

- (id)initWithURL:(NSURL *)url resampler:(SOXResampler *)resampler;

- (void)didCompleteWithError:(NSError *)error;

@end
