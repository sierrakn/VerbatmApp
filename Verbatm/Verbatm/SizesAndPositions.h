//
//  Sizes.h
//  Verbatm
//
//  Created by Sierra Kaplan-Nelson on 7/20/15.
//  Copyright © 2015 Verbatm. All rights reserved.
//

#ifndef SizesAndPositions_h
#define SizesAndPositions_h


#pragma mark - Sign In -

#define SIGN_IN_ERROR_VIEW_HEIGHT 100.f
#define SIGNIN_ERROR_LABEL_PADDING 30.f


#pragma mark - Feed -

#define ARTICLE_IN_FEED_BUTTON_HEIGHT 50
#define FEED_TOP_OFFSET 30
#define FEED_TITLE_LIST_OFFSET 30

#pragma mark Compose Story Button

#define COMPOSE_STORY_BUTTON_SIZE 90.f
#define COMPOSE_STORY_BUTTON_OFFSET 20.f
#define COMPOSE_STORY_OUTER_CIRCLE_SIZE 110.f


#pragma mark - Media Dev VC -

#define SWITCH_ICON_SIZE 50.f
#define FLASH_ICON_SIZE 50.f
#define CAMERA_BUTTON_SIZE 100.f
#define PROGRESS_CIRCLE_SIZE 100.f
#define PROGRESS_CIRCLE_THICKNESS 10.0f
#define PROGRESS_CIRCLE_OPACITY 0.6f

#define FLASH_START_POSITION  10.f, 0.f
#define SWITCH_CAMERA_START_POSITION 260.f, 5.f
#define CAMERA_BUTTON_Y_OFFSET 20.f

#define TRANSLATION_CONTENT_DEV_CONTAINER_VIEW_THRESHOLD 50.f


#pragma mark - Content Dev VC -

#pragma mark - Gallery

#define GALLERY_COLUMNS_PORTRAIT 3
#define GALLERY_COLUMNS_LANDSCAPE 5

#pragma mark - Editing Content View

#define TEXT_VIEW_BOTTOM_PADDING 15.f

#pragma mark Toolbar

#define TEXT_TOOLBAR_HEIGHT 30.f
#define TEXT_TOOLBAR_BUTTON_OFFSET 9.f
#define TEXT_TOOLBAR_BUTTON_WIDTH 70.f

#pragma mark - Preview

#define PUBLISH_BUTTON_XOFFSET 20.f
#define PUBLISH_BUTTON_YOFFSET 20.f
#define PUBLISH_BUTTON_SIZE 75.f

#pragma mark - Pull Bar

#define PULLBAR_BUTTON_XOFFSET 20.f
#define PULLBAR_BUTTON_YOFFSET 15.f
#define PULLBAR_PULLDOWN_ICON_WIDTH 60.f
#define PULLBAR_HEIGHT_MENU_MODE 60.f
#define PULLBAR_HEIGHT_PULLDOWN_MODE 30.f


#pragma mark Verbatm Image Scroll View
#define VIEW_WALL_OFFSET 20

#define TEXTFIELD_BORDER_WIDTH 0.8f
#define AUTO_SCROLL_OFFSET 10
#define CONTENT_SIZE_OFFSET 20
#define OFFSET_BELOW_ARTICLE_TITLE 30
//distance between elements on the page
#define ELEMENT_OFFSET_DISTANCE 20
#define CURSOR_BASE_GAP 10
//the gap between the bottom of the screen and the cursor
#define CENTERING_OFFSET_FOR_TEXT_VIEW 30
//if the image is up- you can scroll up and have it turn to circles. This gives that scrollup distance
#define SCROLLDISTANCE_FOR_PINCHVIEW_RETURN 200

#pragma mark PinchViews

#define PINCHVIEW_DIVISION_FACTOR_FOR_TWO 2
#define MIN_PINCHVIEW_SIZE 100
//distance two fingers must travel for the horizontal pinch to be accepted
#define HORIZONTAL_PINCH_THRESHOLD 100
#define PINCH_VIEW_DELETING_THRESHOLD 80
#define PINCH_DISTANCE_THRESHOLD_FOR_NEW_MEDIA_TILE_CREATION 100

#pragma mark Media Select Tile

#define MEDIA_TILE_SELECTOR_HEIGHT 100.f
#define ADD_MEDIA_BUTTON_OFFSET 10



#pragma mark - AVES -

#pragma mark Text

#define TEXT_OVER_AVE_TOP_OFFSET 80.f
#define TEXT_OVER_AVE_STARTING_HEIGHT 100.f
#define TEXT_OVER_AVE_PULLBAR_HEIGHT 40.f
#define TEXT_OVER_AVE_ANIMATION_THRESHOLD 30.f
#define TEXT_OVER_AVE_BORDER 30.f

#pragma mark Images

#define CIRCLE_OVER_IMAGES_RADIUS_FACTOR_OF_HEIGHT 6.f

#define POINTS_ON_CIRCLE_RADIUS 10.f
#define TOUCH_THRESHOLD 40.f


#endif
