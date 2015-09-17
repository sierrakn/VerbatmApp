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

@property (nonatomic, assign) float progress;


// Creates an ASIFormDataRequest with the image in png form
// and stages it for upload to the given uri
-(instancetype) initWithImage:(UIImage*)img andUri: (NSString*)uri;

// Creates an ASIFormDataRequest with the video in quicktime .mov form
// and stages it for upload to the given uri
-(instancetype) initWithVideoData: (NSData*)videoData  andUri: (NSString*)uri;

// Start the upload with the given completion block, called when the upload request
// is either complete or failed (passed into success parameter)
// If it succeeded the url from the server will be passed as a parameter
// TODO: this is a blobkey string for video and an imagesservice servingurl for image
-(void) startWithCompletionHandler:(MediaUploadCompletionBlock) completionBlock;

-(PMKPromise*) startUpload;

@end
