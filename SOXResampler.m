//
//  SOXResampler.m
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/13/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

#import "SOXResampler_private.h"
#import "SOXResamplerConfiguration.h"
#import "SOXResamplerTask_private.h"
#import "SOXResamplerTaskOperation.h"
#import "soxr.h"

NSString * const SOXResamplerErrorDomain = @"SOXResamplerErrorDomain";

@implementation SOXResampler

@synthesize operationQueue = _operationQueue;

+ (void)load {
  [super load];
  
//  assert(sox_init() == SOX_SUCCESS);
#warning Idk where this should happen
//  sox_quit();
}

#pragma mark - Initializers
#pragma mark Public

+ (instancetype)sharedResampler {
  static dispatch_once_t pred;
  static id instance = nil;
  
  dispatch_once(&pred, ^{
    if (!instance) {
      instance = self.new;
    }
  });
  
  return instance;
}

+ (instancetype)resamplerWithConfiguration:(SOXResamplerConfiguration *)configuration {
  return [self resamplerWithConfiguration:configuration delegate:nil operationQueue:nil];
}

+ (instancetype)resamplerWithConfiguration:(SOXResamplerConfiguration *)configuration delegate:(id<SOXResamplerDelegate>)delegate operationQueue:(NSOperationQueue *)queue {
  return [[self alloc] initWithConfiguration:configuration delegate:delegate operationQueue:queue];
}

#pragma mark Private

- (instancetype)initWithConfiguration:(SOXResamplerConfiguration *)configuration {
  return [self initWithConfiguration:configuration delegate:nil operationQueue:nil];
}

- (instancetype)initWithConfiguration:(SOXResamplerConfiguration *)configuration delegate:(id<SOXResamplerDelegate>)delegate operationQueue:(NSOperationQueue *)queue {
  self = [super init];
  if (self) {
    _configuration = configuration;
    _immutableConfiguration = configuration.copy;
    _operationQueue = queue;
    _delegate = delegate;
  }
  return self;
}

#pragma mark - Operation Queue

- (NSOperationQueue *)operationQueue {
  if (!_operationQueue) {
    _operationQueue = [[NSOperationQueue alloc] init];
    _operationQueue.name = @"SOXResamplerDefaultOperationQueue";
  }
  
  return _operationQueue;
}

- (void)resampleTask:(SOXResamplerTask *)task {
  if (!self.isInvalid) {
    SOXResamplerTaskOperation *operation;
    operation = [SOXResamplerTaskOperation operationWithTask:task];
    
    [self.operationQueue addOperation:operation];
  }
}

#pragma mark - Task Creation

- (SOXResamplerTask *)taskWithURL:(NSURL *)url {
  if (!self.isInvalid) {
    id taskDelegate;
    
    if ([self.delegate conformsToProtocol:@protocol(SOXResamplerTaskDelegate)]) {
      taskDelegate = self.delegate;
    }
    
    SOXResamplerTask *task = [[SOXResamplerTask alloc] initWithURL:url resampler:self delegate:taskDelegate];
    return task;
  }
  
  return nil;
}

#pragma mark - Delegate Notification

- (void)didBecomeInvalidWithError:(NSError *)error {
  self.isInvalid = YES;
  
  if ([self.delegate respondsToSelector:@selector(resampler:didBecomeInvalidWithError:)]) {
    [self.delegate resampler:self didBecomeInvalidWithError:error];
  }
}

- (void)didFinishResamplingTask:(SOXResamplerTask *)task toURL:(NSURL *)location {
  [self.delegate resampler:self task:task didFinishResamplingToURL:location];
  [NSFileManager.defaultManager removeItemAtURL:location error:nil];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
  SOXResampler *copy = self.class.new;
  
  copy->_configuration = self.immutableConfiguration.copy;
  copy->_immutableConfiguration = self.immutableConfiguration.copy;
  
  copy.isInvalid = self.isInvalid;
  
  copy.resamplerDescription = self.resamplerDescription.copy;
  
  copy->_delegate = self.delegate;
  copy->_operationQueue = self.operationQueue.copy;
  
  return copy;
}

@end
