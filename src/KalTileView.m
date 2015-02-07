/*
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import "KalTileView.h"
#import "KalDate.h"
#import "KalPrivate.h"

extern CGSize kTileSize;

static KalTileView* __sharedAppearance = nil;

@implementation KalTileView

@synthesize date;

+ (KalTileView*) appearance {
	if (__sharedAppearance == nil) { __sharedAppearance = [[KalTileView alloc] init];}
	return __sharedAppearance;
}

- (KalTileView*) init {
	if ((self = [super init])) {
		CGFloat fontSize = 24.f;
		self.font = [UIFont boldSystemFontOfSize:fontSize];
		
		self.tileImageTodaySelected = [[UIImage imageNamed:@"Kal.bundle/kal_tile_today_selected.png"] stretchableImageWithLeftCapWidth:6 topCapHeight:0];
		self.markerImageToday = [UIImage imageNamed:@"Kal.bundle/kal_marker_today.png"];
		self.tileImageToday = [[UIImage imageNamed:@"Kal.bundle/kal_tile_today.png"] stretchableImageWithLeftCapWidth:6 topCapHeight:0];
		self.tileImageSelected= [[UIImage imageNamed:@"Kal.bundle/kal_tile_selected.png"] stretchableImageWithLeftCapWidth:1 topCapHeight:0];
		self.tileBackgroundImage = [UIImage imageNamed:@"Kal.bundle/kal_tile.png"];
		self.markerImageSelected = [UIImage imageNamed:@"Kal.bundle/kal_marker_selected.png"];
		self.textColorAdjacentMonth = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Kal.bundle/kal_tile_dim_text_fill.png"]];
		self.markerImageAdjacentMonth = [UIImage imageNamed:@"Kal.bundle/kal_marker_dim.png"];
		self.textColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Kal.bundle/kal_tile_text_fill.png"]];
		self.textColorSelected = [UIColor whiteColor];
		self.textShadowColorSelected = [UIColor blackColor];
		self.textShadowColor = [UIColor whiteColor];
		self.textShadowColorAdjacentMonth = nil;
		self.markerImage = [UIImage imageNamed:@"Kal.bundle/kal_marker.png"];
		self.textAlignment = NSTextAlignmentCenter;
		self.textVAlignment = 1;
		self.textXOffset = 0;
		
	}
	return self;
}


- (id)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		self.opaque = NO;
		self.backgroundColor = [UIColor clearColor];
		self.clipsToBounds = NO;
		origin = frame.origin;
		[self setIsAccessibilityElement:YES];
		[self setAccessibilityTraits:UIAccessibilityTraitButton];
		[self resetState];
	}
	return self;
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	UIFont *font = [[KalTileView appearance] font];
	UIColor *shadowColor = nil;
	UIColor *textColor = nil;
	UIImage *markerImage = nil;
	CGContextSelectFont(ctx, [font.fontName cStringUsingEncoding:NSUTF8StringEncoding], font.pointSize, kCGEncodingMacRoman);
	
	CGContextTranslateCTM(ctx, 0, kTileSize.height);
	CGContextScaleCTM(ctx, 1, -1);
	
	if ([self isToday] && self.selected) {
		[[[KalTileView appearance] tileImageTodaySelected] drawInRect:CGRectMake(0, -1, kTileSize.width+1, kTileSize.height+1)];
		textColor = [[KalTileView appearance] textColorSelected];
		shadowColor = [[KalTileView appearance] textShadowColorSelected];
		markerImage = [[KalTileView appearance] markerImageToday];
	} else if ([self isToday] && !self.selected) {
		[[[KalTileView appearance] tileImageToday] drawInRect:CGRectMake(0, -1, kTileSize.width+1, kTileSize.height+1)];
		textColor = [[KalTileView appearance] textColorSelected];
		shadowColor = [[KalTileView appearance] textShadowColorSelected];
		markerImage = [[KalTileView appearance] markerImageToday];
	} else if (self.selected) {
		[[[KalTileView appearance] tileImageSelected]
		 drawInRect:CGRectMake(0, -1, kTileSize.width+1, kTileSize.height+1)];
		textColor = [[KalTileView appearance] textColorSelected];
		shadowColor = [[KalTileView appearance] textShadowColorSelected];
		markerImage = [[KalTileView appearance] markerImageSelected];
	} else if (self.belongsToAdjacentMonth) {
		[[[KalTileView appearance] tileBackgroundImage] drawInRect:CGRectMake(0, 0, kTileSize.width, kTileSize.height)];
		textColor = [[KalTileView appearance] textColorAdjacentMonth];
		shadowColor = [[KalTileView appearance] textShadowColorAdjacentMonth];
		markerImage = [[KalTileView appearance] markerImageAdjacentMonth];
	} else {
		[[[KalTileView appearance] tileBackgroundImage] drawInRect:CGRectMake(0, 0, kTileSize.width, kTileSize.height)];
		textColor = [[KalTileView appearance] textColor];
		shadowColor = [[KalTileView appearance] textShadowColor];
		markerImage = [[KalTileView appearance] markerImage];
	}
	
	if (flags.marked)
		[markerImage drawInRect:CGRectMake(21.f, 5.f, 4.f, 5.f)];
	
	NSUInteger n = [self.date day];
	NSString *dayText = [NSString stringWithFormat:@"%lu", (unsigned long)n];
	const char *day = [dayText cStringUsingEncoding:NSUTF8StringEncoding];
	CGSize textSize = [dayText sizeWithFont:font];
	CGFloat textX = 0, textY = 0;
	if([[KalTileView appearance] textAlignment] == NSTextAlignmentLeft) {
		textX = 0;
	} else {
		textX = roundf(0.5f * (kTileSize.width - textSize.width));
	}
	textX += [KalTileView appearance].textXOffset;
	
	if ([[KalTileView appearance] textVAlignment] == 0){
		textY = roundf(kTileSize.height - textSize.height);
	} else if ([[KalTileView appearance] textVAlignment] == 1){
		textY = 6.f + roundf(0.5f * (kTileSize.height - textSize.height));
	} 
	
	if (shadowColor) {
		[shadowColor setFill];
		CGContextShowTextAtPoint(ctx, textX, textY, day, n >= 10 ? 2 : 1);
		textY += 1.f;
	}
	[textColor setFill];
	CGContextShowTextAtPoint(ctx, textX, textY, day, n >= 10 ? 2 : 1);
	
	if (self.highlighted) {
		[[UIColor colorWithWhite:0.25f alpha:0.3f] setFill];
		CGContextFillRect(ctx, CGRectMake(0.f, 0.f, kTileSize.width, kTileSize.height));
	}
}

- (void)resetState
{
	// realign to the grid
	CGRect frame = self.frame;
	frame.origin = origin;
	frame.size = kTileSize;
	self.frame = frame;
	
	date = nil;
	flags.type = KalTileTypeRegular;
	flags.highlighted = NO;
	flags.selected = NO;
	flags.marked = NO;
}

- (void)setDate:(KalDate *)aDate
{
	if (date == aDate)
		return;
	
	date = aDate;
	
	[self setNeedsDisplay];
}

- (BOOL)isSelected { return flags.selected; }

- (void)setSelected:(BOOL)selected
{
	if (flags.selected == selected)
		return;
	
	// workaround since I cannot draw outside of the frame in drawRect:
	if (![self isToday]) {
		CGRect rect = self.frame;
		if (selected) {
			rect.origin.x--;
			rect.size.width++;
			rect.size.height++;
		} else {
			rect.origin.x++;
			rect.size.width--;
			rect.size.height--;
		}
		self.frame = rect;
	}
	
	flags.selected = selected;
	[self setNeedsDisplay];
}

- (BOOL)isHighlighted { return flags.highlighted; }

- (void)setHighlighted:(BOOL)highlighted
{
	if (flags.highlighted == highlighted)
		return;
	
	flags.highlighted = highlighted;
	[self setNeedsDisplay];
}

- (BOOL)isMarked { return flags.marked; }

- (void)setMarked:(BOOL)marked
{
	if (flags.marked == marked)
		return;
	
	flags.marked = marked;
	[self setNeedsDisplay];
}

- (KalTileType)type { return flags.type; }

- (void)setType:(KalTileType)tileType
{
	if (flags.type == tileType)
		return;
	
	// workaround since I cannot draw outside of the frame in drawRect:
	CGRect rect = self.frame;
	if (tileType == KalTileTypeToday) {
		rect.origin.x--;
		rect.size.width++;
		rect.size.height++;
	} else if (flags.type == KalTileTypeToday) {
		rect.origin.x++;
		rect.size.width--;
		rect.size.height--;
	}
	self.frame = rect;
	
	flags.type = tileType;
	[self setNeedsDisplay];
}

- (BOOL)isToday { return flags.type == KalTileTypeToday; }

- (BOOL)belongsToAdjacentMonth { return flags.type == KalTileTypeAdjacent; }


@end
