/* 
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import <UIKit/UIKit.h>

enum {
  KalTileTypeRegular   = 0,
  KalTileTypeAdjacent  = 1 << 0,
  KalTileTypeToday     = 1 << 1,
};
typedef char KalTileType;

@class KalDate;

@interface KalTileView : UIView
{
  KalDate *date;
  CGPoint origin;
  struct {
    unsigned int selected : 1;
    unsigned int highlighted : 1;
    unsigned int marked : 1;
    unsigned int type : 2;
  } flags;
	
}

@property (nonatomic, strong) KalDate *date;
@property (nonatomic, getter=isHighlighted) BOOL highlighted;
@property (nonatomic, getter=isSelected) BOOL selected;
@property (nonatomic, getter=isMarked) BOOL marked;
@property (nonatomic) KalTileType type;

// Appearance
@property (strong) UIFont* font;
@property (strong) UIImage* tileImageTodaySelected;
@property (strong) UIImage* markerImageToday;
@property (strong) UIImage* tileBackgroundImage;
@property (strong) UIImage* tileImageToday;
@property (strong) UIImage* tileImageSelected;
@property (strong) UIImage* markerImageSelected;
@property (strong) UIColor* textColorAdjacentMonth;
@property (strong) UIImage* markerImageAdjacentMonth;
@property (strong) UIColor* textColor;
@property (strong) UIColor* textColorSelected;
@property (strong) UIColor* textShadowColor;
@property (strong) UIColor* textShadowColorAdjacentMonth;
@property (strong) UIColor* textShadowColorSelected;
@property (strong) UIImage* markerImage;
@property NSTextAlignment* textAlignment;
@property int textVAlignment;
@property float textXOffset;

- (void)resetState;
- (BOOL)isToday;
- (BOOL)belongsToAdjacentMonth;

+ (KalTileView*) appearance ;

@end
