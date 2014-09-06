//
//  SOXResampler.h
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/13/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

@import Foundation;

@protocol SOXResamplerDelegate;
@class SOXResamplerConfiguration, SOXResamplerTask;

@interface SOXResampler : NSObject <NSCopying>

/*
 * The shared resampler has a basic configuration and uses
 * an operation queue that the class manages internally.
 */
+ (instancetype)sharedResampler;

/*
 * Customization of SOXResampler occurs during the creation of a new resampler.
 * If you only need to use the convenience routines with custom
 * configuration options it is not necessary to specify a delegate.
 * If no operation queue is provided, all tasks will be executed in
 * a default queue that the class manages internally.
 */
+ (instancetype)resamplerWithConfiguration:(SOXResamplerConfiguration *)configuration;
+ (instancetype)resamplerWithConfiguration:(SOXResamplerConfiguration *)configuration delegate:(id<SOXResamplerDelegate>)delegate operationQueue:(NSOperationQueue *)queue;

@property (readonly, retain) NSOperationQueue *operationQueue;
@property (assign) id <SOXResamplerDelegate> delegate;
@property (copy, readonly) SOXResamplerConfiguration *configuration;

/*
 * The resamplerDescription property is available for the developer to
 * provide a descriptive label for the resampler.
 */
@property (copy) NSString *resamplerDescription;

/*
 * SOXResamplerTask objects are always created in a suspended state and
 * must be sent the -resume message before they will execute.
 */

/* Creates a data task to resample the PCM audio data of the given file URL. */
- (SOXResamplerTask *)taskWithURL:(NSURL *)url;

@end

/*
 * SOXResamplerDelegate specifies the methods that a session delegate
 * may respond to.  There are both session specific messages (for
 * example, resample setup errors) as well as task based messages.
 */

/*
 * Messages related to the resampler as a whole, and to the operation
 * of a task that writes data to a file and notifies the delegate
 * upon completion.
 */

@protocol SOXResamplerDelegate <NSObject>
@optional

/* The last message an resampler receives.  A resampler will only become
 * invalid because of a systemic error or when it has been
 * explicitly invalidated, in which case it will receive an
 * { SOXResamplerErrorDomain, SOXResamplerErrorCancelled } error.
 */
- (void)resampler:(SOXResampler *)resampler didBecomeInvalidWithError:(NSError *)error;

@required

/* Sent when an resampling task that has completed resampling.  The delegate should
 * copy or move the file at the given location to a new location as it will be
 * removed when the delegate message returns. resampler:task:didCompleteWithError: will
 * still be called.
 */
- (void)resampler:(SOXResampler *)resampler task:(SOXResamplerTask *)task didFinishResamplingToURL:(NSURL *)location;

/* Sent periodically to notify the delegate of resampling progress. */
- (void)resampler:(SOXResampler *)resampler task:(SOXResamplerTask *)task didResampleFrames:(int64_t)framesResampled totalFramesResampled:(int64_t)totalFramesResampled totalFrameExpectedToResample:(int64_t)totalFrameExpectedToResample;

@end