//
//  ImageVideoUpload.h
//  Verbatm
//
//  Takes a piece of media (image or video data) and an upload uri
// generated by the server and uploads the data to the uri
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "ASIFormDataRequest.h"

#import <PromiseKit/PromiseKit.h>


typedef void(^MediaUploadCompletionBlock)(NSError* error, NSString* responseURL);

@interface MediaUploader : NSObject

@property (nonatomic, strong) NSProgress* mediaUploadProgress;

// Creates an ASIFormDataRequest with the image in png form
// and stages it for upload to the given uri
-(instancetype) initWithImage:(NSData*)imageData andUri: (NSString*)uri;

// and stages it for upload to the given uri
-(instancetype) initWithVideoData: (NSData*)videoData  andUri: (NSString*)uri;

// Returns the number of bytes to be uploaded
-(long long) getPostLength;

-(AnyPromise*) startUpload;

@end
