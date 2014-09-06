//
//  SOXResamplerError.h
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 9/5/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

@class NSString;

/*
 @discussion Constants used by NSError to differentiate between "domains" of error codes, serving as a discriminator for error codes that originate from different subsystems or sources.
 @constant SOXResamplerErrorDomain Indicates a soxr resampler error.
 */
FOUNDATION_EXPORT NSString * const SOXResamplerErrorDomain;

/*!
 @enum SOXResampler-related Error Codes
 @abstract Constants used by NSError to indicate errors in the soxr domain
 @discussion Documentation on each constant forthcoming.
 */

typedef NS_ENUM(NSInteger, SOXResamplerError) {
  SOXResamplerErrorUnknown = -1,
  SOXResamplerErrorCancelled = -999,
  SOXResamplerErrorUnsupportedAudio = -1000,
  
  // Resampler errors
  SOXResamplerErrorCannotInitialize = -2000,
  SOXResamplerErrorCannotResampleAudio = -2001,
  SOXResamplerErrorCannotAllocateInputBuffer = -2002,
  SOXResamplerErrorCannotAllocateOutputBuffer = -2003,
  
  // File I/O errors
  SOXResamplerErrorCannotOpenFile = -3000,
  SOXResamplerErrorCannotReadFile = -3001,
  SOXResamplerErrorCannotWriteFile = -3002
};
