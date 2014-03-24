//
//  SOXResamplerTask.m
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/13/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

#import "SOXResamplerTask_private.h"
#import "SOXResampler_private.h"

@implementation SOXResamplerTask

@synthesize resampler = _resampler;
@synthesize URL = _URL;

- (id)initWithURL:(NSURL *)url resampler:(SOXResampler *)resampler {
  self = [super init];
  if (self) {
#warning should make sure both args exist
    _URL = url;
    _resampler = resampler;
  }
  return self;
}

- (NSURL *)originalURL {
  return self.URL;
}

- (const char *)path {
  return self.URL.path.UTF8String;
}

- (void)resume {
  [self.resampler resampleTask:self];
}

- (void)cancel {
#warning todo
}

- (void)didCompleteWithError:(NSError *)error {
  if ([self.delegate respondsToSelector:@selector(resampler:task:didCompleteWithError:)]) {
    [self.delegate resampler:self.resampler task:self didCompleteWithError:error];
  }
}

@end
