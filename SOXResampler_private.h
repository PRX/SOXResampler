//
//  SOXResampler_private.h
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/13/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

#import "SOXResampler.h"

@class SOXResamplerConfiguration;

@interface SOXResampler ()

/* This copy of the configuration set during creation
 * is immutable in spirit only. Nothing that has access
 * to it should change its properties, even if it could
 */
@property (readonly, copy) SOXResamplerConfiguration *immutableConfiguration;

/* The encoder will not accept new tasks once it becomes invalid */
@property BOOL isInvalid;

/* Initializers */
- (instancetype)initWithConfiguration:(SOXResamplerConfiguration *)configuration;
- (instancetype)initWithConfiguration:(SOXResamplerConfiguration *)configuration delegate:(id<SOXResamplerDelegate>)delegate operationQueue:(NSOperationQueue *)queue;

/* Creates an operation for the task and adds it to this
 * resampler's operation queue to be worked on immediately
 */
- (void)resampleTask:(SOXResamplerTask *)task;

/* Delegate Notification */
- (void)didBecomeInvalidWithError:(NSError *)error;
- (void)didFinishResamplingTask:(SOXResamplerTask *)task toURL:(NSURL *)location;

@end
