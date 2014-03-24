//
//  SOXResamplerTaskOperation.h
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/13/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

@import Foundation;

@class SOXResamplerTask;

@interface SOXResamplerTaskOperation : NSOperation

+ (instancetype)operationWithTask:(SOXResamplerTask *)task;

- (instancetype)initWithTask:(SOXResamplerTask *)task;

@end
