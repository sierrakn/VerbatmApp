/* This file was generated by the ServiceGenerator.
 * The ServiceGenerator is Copyright (c) 2015 Google Inc.
 */

//
//  GTLVerbatmAppResultsWithCursor.h
//

// ----------------------------------------------------------------------------
// NOTE: This file is generated from Google APIs Discovery Service.
// Service:
//   verbatmApp/v1
// Description:
//   This is an API
// Classes:
//   GTLVerbatmAppResultsWithCursor (0 custom class methods, 2 custom properties)

#if GTL_BUILT_AS_FRAMEWORK
  #import "GTL/GTLObject.h"
#else
  #import "GTLObject.h"
#endif

@class GTLVerbatmAppList;

// ----------------------------------------------------------------------------
//
//   GTLVerbatmAppResultsWithCursor
//

@interface GTLVerbatmAppResultsWithCursor : GTLObject
@property (nonatomic, copy) NSString *cursorString;
@property (nonatomic, retain) GTLVerbatmAppList *results;
@end
