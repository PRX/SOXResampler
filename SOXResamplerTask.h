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

@interface SOXResamplerTask : NSObject

@property (nonatomic, strong) id <SOXResamplerTaskDelegate> delegate;
@property (nonatomic, strong, readonly) NSURL *originalURL;

- (void)resume;
- (void)cancel;

@end

@protocol SOXResamplerTaskDelegate <NSObject>

@optional

- (void)resampler:(SOXResampler *)encoder task:(SOXResamplerTask *)task didCompleteWithError:(NSError *)error;

@end