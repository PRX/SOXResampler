//
//  SOXResamplerConfiguration.m
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/13/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

#import "SOXResamplerConfiguration.h"

@implementation SOXResamplerConfiguration

+ (instancetype)publicRadioConfiguration {
  SOXResamplerConfiguration *config = self.new;
  
  config.targetSampleRate = 44100;
  
  return config;
}

- (id)copyWithZone:(NSZone *)zone {
  SOXResamplerConfiguration *copy = self.class.new;
  
  if (copy) {
    copy.targetSampleRate = self.targetSampleRate;
  }
  
  return copy;
}

@end
