//
//  verbatmCustomPinchView.m
//  Verbatm
//
//  Created by Lucio Dery Jnr Mwinmaarong on 11/15/14.
//  Copyright (c) 2014 Verbatm. All rights reserved.
//

#import "PinchView.h"
#import "VerbatmImageView.h"


@interface PinchView()
@property(strong,nonatomic)IBOutlet UIView* background;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewer;
@property (weak, nonatomic) IBOutlet UITextView *textField;
@property (nonatomic,strong) AVPlayerViewController * mixPlayer;
@property (nonatomic,strong) AVPlayerLayer * playerLayer;

@property (strong, nonatomic) NSMutableArray* media;
@property (strong, nonatomic) NSMutableArray* photos;
@property (strong, nonatomic) NSMutableArray* videos;
@property (strong, nonatomic) NSMutableArray* pinched;
@property (strong, nonatomic) NSString* text;

@property (readwrite,nonatomic) BOOL there_is_text;
@property (readwrite, nonatomic) BOOL there_is_video;
@property (readwrite, nonatomic) BOOL there_is_picture;

#define SHADOW_OFFSET_FACTOR 25
#define DIVISION_FACTOR_FOR_TWO 2
#define P_OBJ_THERE_IS_PICTURE @"picture"
#define P_OBJ_THERE_IS_VIDEO  @"video"
#define P_OBJ_THERE_IS_TEXT @"text"
#define P_OBJ_MEDIA @"media"
#define MIN_PINCHVIEW_SIZE 100


@end

@implementation PinchView

//Instantiates an instance of the custom view without any media types inputted
-(instancetype)initWithRadius:(float)radius  withCenter:(CGPoint)center andMedia:(id)medium
{
    if((self = [super init]))
    {
        
        //load from Nib file..this initializes the background view and all its subviews
        [[NSBundle mainBundle] loadNibNamed:@"PinchView" owner:self options:nil];
        
        //set up the properties
        CGRect frame = CGRectMake(center.x - radius, center.y - radius, radius*2, radius*2);
        [self specifyFrame:frame];
        self.background.layer.masksToBounds = YES;
        
        //initialize arrays
        self.media = [[NSMutableArray alloc]init];
        self.inDataFormat = NO;
        
        //add Medium to the list of media
        if([medium isKindOfClass: [UITextView class]]){
             self.there_is_text = YES;
        }else if([medium isKindOfClass: [VerbatmImageView class]]){
            self.there_is_video = ((VerbatmImageView*)medium).isVideo;
            self.there_is_picture = !self.there_is_video;
        }
        
        [self initSubviews];
        if(medium){
            [self.media addObject: medium];
            [self renderMedia];
        }
        [self addBorderToPinchView];
        
    }
    return self;
}

+(PinchView *)pinchObjectFromPinchObject: (PinchView *) pv
{
    id media_1 = pv.media.firstObject;
    [pv.media removeObject:media_1];
    PinchView * new_pv = [[PinchView alloc]initWithRadius:pv.frame.size.width/2 withCenter:pv.center andMedia:media_1];
    [new_pv.media addObjectsFromArray:pv.media];
    return new_pv;
}

-(void)initSubviews
{
    //add background as a subview
    [self addSubview: self.background];
    
    //set frames
    self.videoView.frame =  CGRectZero;
    self.textField.frame = CGRectZero; //prevents the little part of the  texfield from showing
    self.imageViewer.frame = CGRectZero;
    
    self.background.backgroundColor = [UIColor clearColor];
    self.backgroundColor = [UIColor clearColor];
    self.textField.backgroundColor = [UIColor clearColor];

}

//adds a thin circular border to the view
-(void)addBorderToPinchView
{
    self.layer.borderColor = [UIColor whiteColor].CGColor;
    self.layer.borderWidth = 1.0f;
}

//Lucio
//adds a picture to the custom view
-(void)changePicture:(UIImage*)image
{
    //only works if we already have a picture
    if(![self thereIsOnlyOneMedium] || [self hasMultipleMedia] || !self.there_is_picture) return;
    VerbatmImageView* view = [self.media firstObject];
    view.image = image;
    self.imageViewer.image = image;
}
-(void) changeText:(UITextView *) textview
{
    //should only work if ther is text in the pinchview
    if(![self thereIsOnlyOneMedium] || [self hasMultipleMedia] || !self.there_is_text) return;
    UITextView* view = [self.media firstObject];
    view.text = textview.text;
    self.textField.text = textview.text;
    self.textField.textColor = [UIColor whiteColor];
    self.textField.font = [UIFont fontWithName:@"Helvetica" size:15];
}


//Lucio.
/*This specifies the frame of the background and all the subviews
 *It modifies the object to have a circular shape by setting the 
 *corner radius
 */
-(void)specifyFrame:(CGRect)frame
{
    CGPoint center = CGPointMake(frame.origin.x + frame.size.width/2, frame.origin.y + frame.size.height/2);
    self.center = center;
    self.frame = frame;
    self.background.frame = self.bounds;
    self.background.layer.cornerRadius = frame.size.width/2;
    self.layer.cornerRadius = frame.size.width/2;
    self.autoresizesSubviews = YES; // This makes sure that moving the background canvas moves all the associated subviews too.
}

-(void)specifyCenter:(CGPoint) center
{
    self.center = center;
    self.frame = CGRectMake(center.x - self.frame.size.width/2, center.y - self.frame.size.width/2, self.frame.size.width,self.frame.size.height);
    self.background.frame = self.bounds;
    self.background.layer.cornerRadius = self.frame.size.width/2;
    self.layer.cornerRadius = self.frame.size.width/2;
    self.autoresizesSubviews = YES; // This makes sure that moving the background canvas moves all the associated subviews too.
}

//allows the user to change the width and height of the frame keeping the same center
-(void) changeWidthTo: (double) width
{
    if(width < MIN_PINCHVIEW_SIZE) return;
    self.autoresizesSubviews = YES;
    
    CGPoint center = self.center;
    CGRect new_frame = CGRectMake(center.x- width/2, center.y - width/2, width, width);
    CGRect new_bounds_frame =CGRectMake(0, 0, width, width);
    
   
    self.frame = new_frame;
    self.background.frame = new_bounds_frame;
    self.videoView.frame = new_bounds_frame;
    
    if (self.playerLayer) {
        [CATransaction begin];
        [CATransaction setAnimationDuration:0];
        [CATransaction setDisableActions:YES];
        self.playerLayer.frame=self.bounds;
        [CATransaction commit];
        
        self.playerLayer.cornerRadius = self.frame.size.width/2;
        self.background.layer.cornerRadius = self.frame.size.width/2;
        self.layer.cornerRadius = self.frame.size.width/2;
        self.clipsToBounds = YES;
    }
}


-(void)removeBorder
{
    self.layer.borderWidth = 0;
}

-(void)createLensingEffect:(float)radius
{
    //remove previous shadows
    self.layer.shadowPath = nil;
    
    //create the shadow or lensing effect
    self.layer.shadowOffset = CGSizeMake(radius/SHADOW_OFFSET_FACTOR, radius/SHADOW_OFFSET_FACTOR);
    self.layer.shadowColor = [UIColor whiteColor].CGColor;
    self.layer.masksToBounds = NO;
    self.layer.shadowOpacity = 1;
    self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:radius].CGPath;
}


//This renders the pinch object unto the screen in terms of the dynamics of the
//way it should look
-(void)renderMedia
{
    if(self.there_is_video && self.there_is_text && self.there_is_picture){
        [self renderThreeViews];
    }else if( [self thereIsOnlyOneMedium]){
        [self renderSingleView];
    }else{
        [self renderTwoMedia];
    }
    [self displayMedia];
}



//This renders a single view on the pinch object
-(void)renderSingleView
{
    if(self.there_is_text){
        self.textField.frame = self.background.frame;
    }else if(self.there_is_video){
        self.videoView.frame = self.background.frame;
        [self.background bringSubviewToFront:self.videoView];
    }else{
        self.imageViewer.frame = self.background.frame;
        [self.background bringSubviewToFront:self.imageViewer];
    }
}

//this renders two media in a vertical split view kind of way on the pinch object.
-(void)renderTwoMedia
{
    CGRect frame1 = CGRectMake(self.background.frame.origin.x, self.background.frame.origin.y, self.background.frame.size.width/DIVISION_FACTOR_FOR_TWO , self.background.frame.size.height);
    CGRect frame2 = CGRectMake(self.background.frame.origin.x + self.background.frame.size.width/DIVISION_FACTOR_FOR_TWO, self.background.frame.origin.y, self.background.frame.size.width/DIVISION_FACTOR_FOR_TWO, self.background.frame.size.height);
    if(self.there_is_text){
        self.textField.frame = frame1;
        if(self.there_is_picture){
            self.imageViewer.frame = frame2;
        }else{
            self.videoView.frame = frame2;
        }
    }else{
        self.videoView.frame = frame1;
        self.imageViewer.frame = frame2;
        [self.background bringSubviewToFront:self.videoView];
        [self.background bringSubviewToFront:self.imageViewer];
    }
}
       

//This renders three views on the pinch view object.
-(void)renderThreeViews
{
    //computation to determine the relative positions of each of the views
    self.textField.frame = CGRectMake(self.background.frame.origin.x, self.background.frame.origin.y, self.background.frame.size.width, self.background.frame.size.height/DIVISION_FACTOR_FOR_TWO);
    self.imageViewer.frame = CGRectMake(self.background.frame.origin.x, self.background.frame.origin.y + self.textField.frame.size.height, self.background.frame.size.width/DIVISION_FACTOR_FOR_TWO, self.background.frame.size.height - self.textField.frame.size.height);
    self.videoView.frame = CGRectMake(self.background.frame.origin.x + self.imageViewer.frame.size.width, self.imageViewer.frame.origin.y , self.background.frame.size.width - self.imageViewer.frame.size.width, self.imageViewer.frame.size.width);
}

//This function displays the media on the view.
-(void)displayMedia {
    
    self.textField.text = @"";
    VerbatmImageView* videoView = nil;
    if(!self.inDataFormat){
        for(id object in self.media){
            if([object isKindOfClass: [UITextView class]]){
                self.textField.text = [self.textField.text stringByAppendingString: ((UITextView*)object).text];
                self.textField.text = [self.textField.text stringByAppendingString:@"\r\r"];
                //[self.background bringSubviewToFront: self.textField];
            }else if(!((VerbatmImageView*)object).isVideo){
                UIImage* image = [(VerbatmImageView*)object image];
                [self.imageViewer setImage:image];
                self.imageViewer.contentMode = UIViewContentModeCenter;
                self.imageViewer.layer.masksToBounds = YES;
                //[self.background bringSubviewToFront: self.imageViewer];
            }else{
                if(!videoView) videoView = object;
            }
        }
        if(videoView){
            if(self.playerLayer){
                [self.playerLayer removeFromSuperlayer];
                self.playerLayer.frame = self.videoView.bounds;
                [self.videoView.layer addSublayer:self.playerLayer];
            }
        }
    }else{ // Added to make class accomodate taking NSData for vidoes instead!
        self.textField.text = self.text;
        if(self.there_is_picture){
            id imagedata = [self.photos firstObject];
            
            if([imagedata isKindOfClass:[UIImage class]])
            {
                [self.imageViewer setImage: (UIImage*)imagedata];
                self.imageViewer.contentMode = UIViewContentModeCenter;
                self.imageViewer.layer.masksToBounds = YES;
            }else
            {
                [self.imageViewer setImage: [[UIImage alloc] initWithData:imagedata]];
                self.imageViewer.contentMode = UIViewContentModeCenter;
                self.imageViewer.layer.masksToBounds = YES;
            }
        }
        if(self.there_is_video)
        {
            if([self.videos.firstObject isKindOfClass:[AVAsset class]])[self playVideo:[self.videos firstObject]];
            else{
                NSURL* url;
                NSString* filePath = [NSTemporaryDirectory() stringByAppendingString:[NSString stringWithFormat:@"%@%u.mov", @"pinch",  arc4random_uniform(100)]];
                [[NSFileManager defaultManager] createFileAtPath: filePath contents: (NSData*)[self.videos firstObject] attributes:nil];
                url = [NSURL fileURLWithPath: filePath];
                AVURLAsset *avurlAsset = [AVURLAsset URLAssetWithURL:url options:nil];
                [self playVideo:avurlAsset];
            }
        }
    }
    self.textField.font = [UIFont fontWithName:@"Helvetica" size:15];
    self.textField.textColor = [UIColor whiteColor];
    if(self.playerLayer){
        float rate = self.playerLayer.player.rate;
        NSLog(@"here is the rate : %f", rate);
    }
}
       
       
//This merges two verbatm pinch objects into one. 
+(PinchView*)pinchTogether:(NSMutableArray*)to_be_merged
{
    if(to_be_merged.count == 0) return nil;
    PinchView* firstObject = (PinchView*)[to_be_merged firstObject];
    PinchView* result = [[PinchView alloc] initWithRadius:firstObject.frame.size.width/2.0 withCenter:firstObject.center andMedia:nil];
    result.pinched = [[NSMutableArray alloc] init];
    for(int i = 0; i < to_be_merged.count; i++){
        PinchView* pinchObject = (PinchView*)[to_be_merged objectAtIndex:i];
        if(pinchObject.pinched){
            for(PinchView* subView in pinchObject.pinched){
                [PinchView append:subView toPinchObject:result];
            }
        }else{
            [PinchView append:pinchObject toPinchObject:result];
        }
    }
    [result renderMedia];
    return result;
}

+(void)append:(PinchView*)pinchObject toPinchObject:(PinchView*)result
{
    [result.media addObjectsFromArray: pinchObject.media];
    [result.pinched addObject:pinchObject];
    result.there_is_picture =  result.there_is_picture || pinchObject.there_is_picture;
    result.there_is_text =  result.there_is_text || pinchObject.there_is_text;
    result.there_is_video = result.there_is_video || pinchObject.there_is_video;
}

//keeping this just in case
-(BOOL)thereIsOnlyOneMedium
{
    if(self.there_is_text && self.there_is_video && self.there_is_picture) return false;
    if(self.there_is_picture && self.there_is_text)return false;
    if(self.there_is_text && self.there_is_video) return false;
    if(self.there_is_video && self.there_is_picture) return false;
    return  self.there_is_picture || self.there_is_text || self.there_is_video;
}


//this function pulls a pinch object apart into the componenent media.
//It returns an array of pinch objects
+(NSMutableArray*)openCollection:(PinchView*)to_be_seperated
{
    NSMutableArray* arr = [[NSMutableArray alloc] initWithArray: to_be_seperated.pinched];
//    if([to_be_seperated.videoView.layer.sublayers firstObject]){
//        AVPlayerLayer* layer = (AVPlayerLayer*)[to_be_seperated.videoView.layer.sublayers firstObject];
//        [layer.player replaceCurrentItemWithPlayerItem:nil];
//        [layer removeFromSuperlayer]; //remove the video layer
//    }
//
//    NSArray* media = [[NSArray alloc]initWithArray:to_be_seperated.media];
//    CGPoint center = to_be_seperated.center;
//    float radius = to_be_seperated.frame.size.width/2;
//    to_be_seperated = nil;
    for(PinchView* object in arr){
        object.center = to_be_seperated.center;
    }
    //[arr insertObject:to_be_seperated atIndex: 0];
    return arr;
}

//Pinches apart two media that were previously pinched together.
//Undoes a pinch apart
//The function returns null if the object to be pinched apart does not actually consist
//of more than one media object.
+(NSMutableArray*)pinchApart:(PinchView*)to_be_pinched_apart
{
    if(to_be_pinched_apart.media.count < 2)return nil;
    NSMutableArray* arr = [[NSMutableArray alloc] init];
    PinchView* result = [[PinchView alloc]initWithRadius: to_be_pinched_apart.background.frame.size.width withCenter:to_be_pinched_apart.center andMedia: [to_be_pinched_apart.media lastObject]];
    [to_be_pinched_apart.media removeObject: [to_be_pinched_apart.media lastObject]];
    [arr addObject:to_be_pinched_apart];
    [arr addObject: result];
    return arr;
}

#pragma mark - necessary info to return -
//returns all the strings of the media in the media array which are textfields.
-(NSString*)getTextFromPinchObject
{
    return self.textField.text;
}

//Tells whether it is a collection consisting of more than one type of media
-(BOOL)isCollection
{
    return ![self thereIsOnlyOneMedium];
}

//tells you if the pinch object has multiple media objects in its array.
//This applies, whether it is a collection or not.
-(BOOL)hasMultipleMedia
{
    
    return self.media.count > 1;
}

-(NSMutableArray*)mediaObjects
{
    if(_media)return self.media;
    else return [NSMutableArray arrayWithArray:[self.photos arrayByAddingObjectsFromArray:self.videos]];
}

#pragma mark - manipulating playing of videos -

-(void)playVideo:(AVAsset*)asset{
	// Create an AVPlayerItem using the asset
	AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
	// Create the AVPlayer using the playeritem
	AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
	//MUTE THE PLAYER
	player.muted = YES;
	player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(playerItemDidReachEnd:)
												 name:AVPlayerItemDidPlayToEndTimeNotification
											   object:[player currentItem]];

	// Create an AVPlayerLayer using the player
	AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
	playerLayer.frame = self.bounds;
	playerLayer.videoGravity =  AVLayerVideoGravityResizeAspectFill;
	// Add it to your view's sublayers
	[self.videoView.layer addSublayer:playerLayer];
	self.playerLayer = playerLayer;
	// You can play/pause using the AVPlayer object
	[player play];
}

//tells me when the video ends so that I can rewind
-(void)playerItemDidReachEnd:(NSNotification *)notification
{
	AVPlayerItem *p = [notification object];
	[p seekToTime:kCMTimeZero];
}

//this is only to occur when the player layer has been removed (perhaps due to previewing)
//and we need to add a new layer and restart the video
-(void) restartVideo
{
	if (self.playerLayer) {
		return;
	}
	[self displayMedia];
}

//pauses the video for the pinchview if there is one
-(void)pauseVideo
{

    if(!self.there_is_video || !self.playerLayer) return;
	AVPlayer* player = self.playerLayer.player;
    [player pause];
}

//plays the video of the pinch view if there is one
-(void)continueVideo
{

	if(!self.there_is_video || !self.playerLayer) return;
	AVPlayer* player = self.playerLayer.player;
	[player play];
}

-(void)unmuteVideo
{
	if(self.playerLayer) {
		[self.playerLayer.player setMuted:NO];
	}
}

-(void)muteVideo
{
	if(self.playerLayer) {
		[self.playerLayer.player setMuted:YES];
	}
}

#pragma mark - selection interface -

-(void)markAsDeleting
{
    self.layer.borderColor = [UIColor redColor].CGColor;
    self.layer.borderWidth = 2.0f;
}

-(void)unmarkAsDeleting
{
    [self addBorderToPinchView];
}
-(void)markAsSelected
{
    self.layer.borderColor = [UIColor blueColor].CGColor;
    self.layer.borderWidth = 2.0f;
}

-(void)unmarkAsSelected
{
    
    [self addBorderToPinchView];
}



# pragma mark - Modified Pinch to take NSData -
-(instancetype)initWithRadius:(float)radius  withCenter:(CGPoint)center Images:(NSArray*)images videoData:(NSArray*)videoData andText:(NSString*)text
{
    if((self = [super init]))
    {
        //load from Nib file..this initializes the background view and all its subviews
        [[NSBundle mainBundle] loadNibNamed:@"PinchView" owner:self options:nil];
        
        //set up the properties
        CGRect frame = CGRectMake(center.x - radius, center.y - radius, radius*2, radius*2);
        [self specifyFrame:frame];
        self.background.layer.masksToBounds = YES;
        
        //initialize arrays
        self.photos = [[NSMutableArray alloc]initWithArray:images];
        // TODO(sierra): Crashing on this line
        self.videos = [[NSMutableArray alloc]initWithArray:videoData];
        self.text = text;
        self.inDataFormat = YES;
        
        //add Medium to the list of media
        if(text){
            self.there_is_text = YES;
        }
        self.there_is_video = !(videoData == nil || !videoData.count);
        self.there_is_picture = !(images == nil || !images.count);
        
        [self initSubviews];
        [self renderMedia];
        [self addBorderToPinchView];
    }
    return self;
}

-(void)offScreen
{
    
    if(self.playerLayer)    {
        [self.playerLayer.player replaceCurrentItemWithPlayerItem:nil];
    }
}

-(void)onScreen
{
//    AVPlayerItem* playerItem = [AVPlayerItem playerItemWithAsset:self.mix];
//    AVPlayerLayer* playerLayer = [self.videoView.layer.sublayers firstObject];
//    [playerLayer.player replaceCurrentItemWithPlayerItem:playerItem];
    [self displayMedia];
}


-(NSMutableArray*)getVideos
{
    return self.videos;
}

-(NSMutableArray*)getPhotos
{
    return self.photos;
}

@end


