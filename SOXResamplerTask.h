//
//  SOXResamplerTask.h
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/13/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

@import Foundation;

@class SOXResampler;
@protocol SOXResamplerTaskDelegate;

/*
 * SOXResamplerTask - a cancelable object that refers to the lifetime
 * of resampling a given audio file.
 */
@interface SOXResamplerTask : NSObject <NSCopying>

@property (nonatomic, assign) id <SOXResamplerTaskDelegate> delegate;

/* an identifier for this task, assigned by and unique to the owning session */
@property (readonly) NSUInteger taskIdentifier;

/* original file URL of the PCM audio to be encoded */
@property (readonly, copy) NSURL *originalURL;

/*
 * The taskDescription property is available for the developer to
 * provide a descriptive label for the task.
 */
@property (copy) NSString *taskDescription;

/* -cancel returns immediately, but marks a task as being canceled.
 * The task will signal -resampler:task:didCompleteWithError: with an
 * error value of { SOXResamplerErrorDomain, SOXResamplerErrorCancelled }.  In
 * some cases, the task may signal other work before it acknowledges the
 * cancelation.  -cancel may be sent to a task that has been suspended.
 */
- (void)cancel;

/*
 * The error, if any, delivered via -resampler:task:didCompleteWithError:
 * This property will be nil in the event that no error occured.
 */
@property (readonly, copy) NSError *error;

/* Called to being the encoding process */
- (void)resume;

@end

@protocol SOXResamplerTaskDelegate <NSObject>

@optional

- (void)resampler:(SOXResampler *)encoder task:(SOXResamplerTask *)task didCompleteWithError:(NSError *)error;

@end