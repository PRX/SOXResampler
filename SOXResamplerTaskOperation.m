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
#import "SOXResamplerError.h"
#import "soxr.h"
#import "sndfile.h"

@interface SOXResamplerTaskOperation () {
  BOOL _executing;
  BOOL _finished;
}

@property (nonatomic, strong) SOXResamplerTask *task;

@property (nonatomic) SNDFILE *inputFile;
@property (nonatomic) SF_INFO inputFileInfo;

@property (nonatomic) SNDFILE *outputFile;
@property (nonatomic) SF_INFO outputFileInfo;

@property (nonatomic) soxr_t soxr;

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
    
    [self didInit];
  }
  return self;
}

- (void)didInit {
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
  NSString *outputFileName = [NSString stringWithFormat:@"%@_%@.au", GID, inputFileName];
  
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

- (BOOL)isTaskCanceled {
  if (self.task.isCanceled) {
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Encoding was unsuccessful.",
                                NSLocalizedFailureReasonErrorKey: @"Operation was canceled by the user.",
                                NSLocalizedRecoverySuggestionErrorKey: @"Allow the operation to complete." };
    
    NSError *error = [NSError errorWithDomain:SOXResamplerErrorDomain
                                         code:SOXResamplerErrorCancelled
                                     userInfo:userInfo];
    
    [self didFailWithError:error];
    
    return YES;
  }
  
  return NO;
}

- (void)didFailWithError:(NSError *)error {
  [self.task didCompleteWithError:error];
  [self didFinish];
}

#pragma mark - Resampling

- (void)resampleToURL:(NSURL *)location {
  if (!self.isTaskCanceled && self.isExecuting) {
    [self openInputFile];
    [self openOutputFile:location];
    
    [self setupResampler];
    
    [self resample:location];
    
//    [self flushRemainingAudio];
    [self cleanup];
    
    BOOL report = self.isExecuting;
    
    [self didFinish];
    
    if (report) {
      [self.task.resampler didFinishResamplingTask:self.task toURL:location];
    }
  }
}

- (void)openInputFile {
  if (!self.isTaskCanceled && self.isExecuting) {
    self.inputFile = sf_open(self.task.URL.path.fileSystemRepresentation, SFM_READ, &_inputFileInfo);
    
    if (self.inputFile == NULL) {
      NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Resampling was unsuccessful.",
                                  NSLocalizedFailureReasonErrorKey: @"Could not open input file.",
                                  NSLocalizedRecoverySuggestionErrorKey: @"Make sure the file is a support PCM format." };
      
      NSError *_error = [NSError errorWithDomain:SOXResamplerErrorDomain
                                            code:SOXResamplerErrorCannotOpenFile
                                        userInfo:userInfo];
      
      [self didFailWithError:_error];

    }
  }
}

- (void)openOutputFile:(NSURL *)location {
  if (!self.isTaskCanceled && self.isExecuting) {
    
    memset(&_outputFileInfo, 0, sizeof(SF_INFO));
    
    _outputFileInfo.frames = self.inputFileInfo.frames;
    _outputFileInfo.channels = self.inputFileInfo.channels;
    _outputFileInfo.sections = self.inputFileInfo.sections;
    _outputFileInfo.seekable = self.inputFileInfo.seekable;
    _outputFileInfo.format = self.inputFileInfo.format;
    
    double targetSampleRate = self.task.resampler.immutableConfiguration.targetSampleRate;
    _outputFileInfo.samplerate = (int)targetSampleRate;
    
    self.outputFile = NULL;
    self.outputFile = sf_open(location.path.fileSystemRepresentation, SFM_WRITE, &_outputFileInfo);
    
    if (self.outputFile == NULL) {
      NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Resampling was unsuccessful.",
                                  NSLocalizedFailureReasonErrorKey: @"Could not open output file.",
                                  NSLocalizedRecoverySuggestionErrorKey: @"This may be a app sandboxing issue." };
      
      NSError *error = [NSError errorWithDomain:SOXResamplerErrorDomain
                                           code:SOXResamplerErrorCannotOpenFile
                                       userInfo:userInfo];
      
      [self didFailWithError:error];
    }
  }
}

- (void)setupResampler {
  if (!self.isTaskCanceled && self.isExecuting) {
    unsigned int quality = SOXR_HQ;
    soxr_error_t err;
    soxr_io_spec_t spec;
    soxr_quality_spec_t qspec = soxr_quality_spec(quality, 0);
    
    spec = soxr_io_spec(SOXR_INT32_I, SOXR_INT32_I);
    
    double targetSampleRate = self.task.resampler.immutableConfiguration.targetSampleRate;
    
    self.soxr = soxr_create(self.inputFileInfo.samplerate, targetSampleRate, self.inputFileInfo.channels, &err, &spec, &qspec, NULL);
    
    if(err || self.soxr == NULL) {
      NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Resampling was unsuccessful.",
                                  NSLocalizedFailureReasonErrorKey: @"Could not initialize resampler.",
                                  NSLocalizedRecoverySuggestionErrorKey: @"Input audio may be unsupported." };
      
      NSError *error = [NSError errorWithDomain:SOXResamplerErrorDomain
                                           code:SOXResamplerErrorCannotInitialize
                                       userInfo:userInfo];
      
      [self didFailWithError:error];
    }
  }
}

- (void)resample:(NSURL *)location {
  if (!self.isTaskCanceled && self.isExecuting) {
    
    int resampleBufferSize;
    void *resampleBuffer;
    
    sf_count_t samplesRead;
    int64_t totalSamplesRead = 0;
    
    int inputBuffer [1024 * self.inputFileInfo.channels];
    
    if (inputBuffer == NULL) {
      NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Encoding was unsuccessful.",
                                  NSLocalizedFailureReasonErrorKey: @"Could not allocate buffer.",
                                  NSLocalizedRecoverySuggestionErrorKey: @"You may be out of memory." };
      
      NSError *error = [NSError errorWithDomain:SOXResamplerErrorDomain
                                           code:SOXResamplerErrorCannotAllocateInputBuffer
                                       userInfo:userInfo];
      
      [self didFailWithError:error];
      return;
    }
    
    while ((samplesRead = sf_readf_int(self.inputFile, inputBuffer, 1024))) {
      
      totalSamplesRead += samplesRead;
      
      int bufSize = 2.0f * sizeof(int) * samplesRead * self.outputFileInfo.samplerate * self.outputFileInfo.channels / self.inputFileInfo.samplerate;
      
      resampleBuffer = malloc(bufSize);
      resampleBufferSize = bufSize;
      
      size_t done = 0;
      soxr_process(self.soxr, inputBuffer, samplesRead, NULL, resampleBuffer, resampleBufferSize, &done);
      
      if (done > 0) {

        sf_writef_int(self.outputFile, resampleBuffer, done);
      }

      
      [self.task.resampler.delegate resampler:self.task.resampler task:self.task didResampleFrames:samplesRead totalFramesResampled:totalSamplesRead totalFrameExpectedToResample:self.inputFileInfo.frames];
      
    }
    
    NSLog(@"%@", location);
    
    
    if(resampleBuffer) {
      free(resampleBuffer);
    }
    resampleBuffer = NULL;
    resampleBufferSize = 0;
    
  }
}

- (void)cleanup {
  if (self.outputFile) {
    sf_close(self.outputFile);
  }
  self.outputFile = NULL;
  
  if (self.inputFile) {
    sf_close(self.inputFile);
  }
  self.inputFile = NULL;
  
  if(self.soxr) {
    soxr_delete(self.soxr);
  }
  self.soxr = NULL;
}

- (void)yresampleToURL:(NSURL *)location {

  double targetSampleRate = self.task.resampler.immutableConfiguration.targetSampleRate;
  
  // Open input file and get info
  
  SNDFILE *input_file;
  SF_INFO input_file_info;
  
  input_file = sf_open(self.task.URL.path.fileSystemRepresentation, SFM_READ, &input_file_info);
  
  // Setup output file properties
  
  SF_INFO output_file_info;
  memset(&output_file_info, 0, sizeof(SF_INFO));
  
  output_file_info.frames = input_file_info.frames;
  output_file_info.channels = input_file_info.channels;
  output_file_info.sections = input_file_info.sections;
  output_file_info.seekable = input_file_info.seekable;
  output_file_info.format = input_file_info.format;
  
  // Manually set the output sample rate
  
  output_file_info.samplerate = (int)targetSampleRate;
  
  // Open output file for writing
  
  SNDFILE *output_file;
  output_file = sf_open(location.path.fileSystemRepresentation, SFM_WRITE, &output_file_info);
  
  // Setup the soxr resampler
  
  unsigned int quality = SOXR_HQ;
  soxr_error_t err;
  soxr_io_spec_t spec;
  soxr_quality_spec_t qspec = soxr_quality_spec(quality, 0);
  
  spec = soxr_io_spec(SOXR_INT32_I, SOXR_INT32_I);
  
  soxr_t soxr;
  soxr = soxr_create(input_file_info.samplerate, targetSampleRate, input_file_info.channels, &err, &spec, &qspec, NULL);
  
  if(err) {
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Resampling was unsuccessful.",
                                NSLocalizedFailureReasonErrorKey: @"Could not initialize resampler.",
                                NSLocalizedRecoverySuggestionErrorKey: @"Input audio may be unsupported." };
    
    NSError *error = [NSError errorWithDomain:SOXResamplerErrorDomain
                                         code:SOXResamplerErrorCannotInitialize
                                     userInfo:userInfo];
    
    [self didFailWithError:error];
  }

  // Read through the input file
  
  int resampleBufferSize;
  void *resampleBuffer;

  if (soxr) {
    
    sf_count_t _frames = 1024;
    int data [_frames * input_file_info.channels];
    
    sf_count_t samples_read;
    
    while ((samples_read = sf_readf_int(input_file, data, _frames))) {
      
      int bufSize = 2.0f * sizeof(int) * samples_read * output_file_info.samplerate * output_file_info.channels / input_file_info.samplerate;
      
      resampleBuffer = malloc(bufSize);
      resampleBufferSize = bufSize;
      
      size_t done = 0;
      soxr_process(soxr, data, samples_read, NULL, resampleBuffer, resampleBufferSize, &done);
      
      if (done > 0) {
        sf_writef_int(output_file, resampleBuffer, done);
      }
      
    }
    
  }
  
  // Cleanup
  
  if (output_file) {
    sf_close(output_file);
  }
  output_file = NULL;
  
  if (input_file) {
    sf_close(input_file);
  }
  input_file = NULL;
  
  if(soxr) {
    soxr_delete(soxr);
  }
  soxr = NULL;
  
  if(resampleBuffer) {
    free(resampleBuffer);
  }
  resampleBuffer = NULL;
  resampleBufferSize = 0;
  
  NSLog(@"%@", location);
  
  [self.task.resampler.delegate resampler:self.task.resampler task:self.task didFinishResamplingToURL:location];
  
}

@end
