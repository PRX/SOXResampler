//
//  SOXResamplerTaskOperation.m
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/13/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

#import "SOXResamplerTaskOperation.h"
#import "SOXResamplerTask_private.h"
#import "SOXResampler_private.h"
#import "SOXResamplerConfiguration.h"
#import "sox.h"

@interface SOXResamplerTaskOperation () {
  BOOL _executing;
  BOOL _finished;
}

@property (nonatomic, strong) SOXResamplerTask *task;

- (void)didGetCanceled;

- (void)didStartExecuting;
- (void)didStopExecuting;
- (void)didFinish;

- (void)didFailWithError:(NSError *)error;

- (void)resampleToURL:(NSURL *)location;

@end

@implementation SOXResamplerTaskOperation

+ (instancetype)operationWithTask:(SOXResamplerTask *)task {
  return [[self alloc] initWithTask:task];
}

- (instancetype)initWithTask:(SOXResamplerTask *)task {
  self = [super init];
  if (self) {
    self.task = task;
  }
  return self;
}

#pragma mark - Concurrent NSOperation

- (void)start {
  [self didStartExecuting];
  
  if (self.isCancelled) {
    [self didGetCanceled];
    return;
  }
  
  NSString *GID = [[NSProcessInfo processInfo] globallyUniqueString];
  NSString *inputFileName = self.task.URL.path.pathComponents.lastObject;
  NSString *outputFileName = [NSString stringWithFormat:@"%@_%@", GID, inputFileName];
  
  NSURL *outputFileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:outputFileName]];
  
  [self resampleToURL:outputFileURL];
}

- (BOOL)isConcurrent {
  return YES;
}

- (BOOL)isExecuting {
  return _executing;
}

- (BOOL)isFinished {
  return _finished;
}

#pragma mark - State

- (void)didGetCanceled {
  [self didFinish];
  
  NSError *error;
  NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Resampling was unsuccessful.", NSLocalizedFailureReasonErrorKey: @"Operation was canceled.", NSLocalizedRecoverySuggestionErrorKey: @"The user cancled the encoding operation." };
  error = [NSError errorWithDomain:SOXResamplerErrorDomain code:SOXResamplerErrorCancelled userInfo:userInfo];
  
  [self.task didCompleteWithError:error];
}

- (void)didStartExecuting {
  if (_executing != YES) {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
  }
}

- (void)didStopExecuting {
  if (_executing != NO) {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = NO;
    [self didChangeValueForKey:@"isExecuting"];
  }
}

- (void)didFinish {
  if (_finished != YES) {
    [self willChangeValueForKey:@"isFinished"];
    _finished = YES;
    [self didStopExecuting];
    [self didChangeValueForKey:@"isFinished"];
  }
}

- (void)didFailWithError:(NSError *)error {
  [self.task didCompleteWithError:error];
  [self didFinish];
}

#pragma mark - Resampling

- (void)resampleToURL:(NSURL *)location {
  sox_format_t * in, * out; /* input and output files */
  sox_effects_chain_t * chain;
  sox_effect_t * e;
  sox_signalinfo_t interm_signal;
  char * args[10];

  NSUInteger targetSampleRate = self.task.resampler.immutableConfiguration.targetSampleRate;
  
  const char *input_path = self.task.originalURL.fileSystemRepresentation;
  assert(in = sox_open_read(input_path, NULL, NULL, NULL));
  
  sox_signalinfo_t _signal = in->signal;
  _signal.rate = targetSampleRate;
  
  const char *output_path = location.fileSystemRepresentation;
  assert(out = sox_open_write(output_path, &_signal, NULL, NULL, NULL, NULL));
  
  chain = sox_create_effects_chain(&in->encoding, &out->encoding);
  
  interm_signal = in->signal;
  
  e = sox_create_effect(sox_find_effect("input"));
  args[0] = (char *)in, assert(sox_effect_options(e, 1, args) == SOX_SUCCESS);
  assert(sox_add_effect(chain, e, &interm_signal, &in->signal) == SOX_SUCCESS);
  free(e);
  
  e = sox_create_effect(sox_find_effect("rate"));
  assert(sox_effect_options(e, 0, NULL) == SOX_SUCCESS);
  assert(sox_add_effect(chain, e, &interm_signal, &out->signal) == SOX_SUCCESS);
  free(e);
  
  e = sox_create_effect(sox_find_effect("output"));
  args[0] = (char *)out, assert(sox_effect_options(e, 1, args) == SOX_SUCCESS);
  assert(sox_add_effect(chain, e, &interm_signal, &out->signal) == SOX_SUCCESS);
  free(e);
  
  sox_flow_effects(chain, NULL, NULL);
  
  sox_delete_effects_chain(chain);
  sox_close(out);
  sox_close(in);
  
  [self.task.resampler.delegate resampler:self.task.resampler task:self.task didFinishResamplingToURL:location];
}

@end
