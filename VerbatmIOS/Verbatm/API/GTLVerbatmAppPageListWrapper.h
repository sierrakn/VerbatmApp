/* This file was generated by the ServiceGenerator.
 * The ServiceGenerator is Copyright (c) 2015 Google Inc.
 */

//
//  GTLVerbatmAppPageListWrapper.h
//

// ----------------------------------------------------------------------------
// NOTE: This file is generated from Google APIs Discovery Service.
// Service:
//   verbatmApp/v1
// Description:
//   This is an API
// Classes:
//   GTLVerbatmAppPageListWrapper (0 custom class methods, 1 custom properties)

#if GTL_BUILT_AS_FRAMEWORK
  #import "GTL/GTLObject.h"
#else
  #import "GTLObject.h"
#endif

@class GTLVerbatmAppPage;

// ----------------------------------------------------------------------------
//
//   GTLVerbatmAppPageListWrapper
//

@interface GTLVerbatmAppPageListWrapper : GTLObject
@property (nonatomic, retain) NSArray *pages;  // of GTLVerbatmAppPage
@end