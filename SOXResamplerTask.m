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

@synthesize taskIdentifier = _taskIdentifier;

- (instancetype)initWithURL:(NSURL *)url resampler:(SOXResampler *)resampler delegate:(id<SOXResamplerTaskDelegate>)delegate {
  self = [super init];
  if (self) {
    _URL = url;
    _resampler = resampler;
    _delegate = delegate;
  }
  return self;
}

- (NSUInteger)taskIdentifier {
  if (!_taskIdentifier) {
    _taskIdentifier = arc4random_uniform(999999);
  }
  return _taskIdentifier;
}

- (NSURL *)originalURL {
  return self.URL;
}

//- (const char *)path {
//  return self.URL.path.UTF8String;
//}

- (void)resume {
  [self.resampler resampleTask:self];
}

- (void)cancel {
  _canceled = YES;
}

#pragma mark - Delegate Notification

- (void)didCompleteWithError:(NSError *)error {
  if ([self.delegate respondsToSelector:@selector(resampler:task:didCompleteWithError:)]) {
    [self.delegate resampler:self.resampler task:self didCompleteWithError:error];
  }
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
  SOXResamplerTask *copy = self.class.new;
  
  copy->_delegate = self.delegate;
  copy->_resampler = self.resampler;
  
  // don't copy taskIdentifier
  
  copy->_URL = self.URL.copy;
  copy.taskDescription = self.taskDescription.copy;
  
  return copy;
}

@end
