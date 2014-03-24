//
//  SOXResamplerConfiguration.h
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/13/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

@import Foundation;

@interface SOXResamplerConfiguration : NSObject <NSCopying>

+ (instancetype)publicRadioConfiguration;

@property (nonatomic) NSUInteger targetSampleRate;

@end
