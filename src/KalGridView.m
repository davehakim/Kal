/*
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import <CoreGraphics/CoreGraphics.h>

#import "KalGridView.h"
#import "KalView.h"
#import "KalMonthView.h"
#import "KalTileView.h"
#import "KalLogic.h"
#import "KalDate.h"
#import "KalPrivate.h"

#define SLIDE_NONE 0
#define SLIDE_UP 1
#define SLIDE_DOWN 2
#define SLIDE_LEFT 3
#define SLIDE_RIGHT 4

CGSize kTileSize = { 46.f, 44.f };

// static NSString *kSlideAnimationId = @"KalSwitchMonths";

static KalGridView* __sharedAppearance = nil;

@interface KalGridView ()
@property (nonatomic, strong) KalTileView *selectedTile;
@property (nonatomic, strong) KalTileView *highlightedTile;
- (void)swapMonthViews;
@end

@implementation KalGridView

@synthesize selectedTile, highlightedTile, transitioning;

+ (KalGridView*) appearance {
	if (__sharedAppearance == nil) { __sharedAppearance = [[KalGridView alloc] init];}
	return __sharedAppearance;
}

- (KalGridView*) init {
	if ((self = [super init])) {
		self.gridBackgroundImage = [UIImage imageNamed:@"Kal.bundle/kal_grid_background.png"];
		self.fadeMonthsOnSlide = YES;
	}
	return self;
}

- (id)initWithFrame:(CGRect)frame logic:(KalLogic *)theLogic delegate:(id<KalViewDelegate>)theDelegate
{
	// MobileCal uses 46px wide tiles, with a 2px inner stroke
	// along the top and right edges. Since there are 7 columns,
	// the width needs to be 46*7 (322px). But the iPhone's screen
	// is only 320px wide, so we need to make the
	// frame extend just beyond the right edge of the screen
	// to accomodate all 7 columns. The 7th day's 2px inner stroke
	// will be clipped off the screen, but that's fine because
	// MobileCal does the same thing.

	// Check all that, moving to dynamic tile widths
	kTileSize.height = 44.f;
	kTileSize.width = (frame.size.width + 2)/ 7;
	
	if (self = [super initWithFrame:frame]) {
		self.clipsToBounds = YES;
		logic = theLogic;
		delegate = theDelegate;
		
		CGRect monthRect = CGRectMake(0.f, 0.f, frame.size.width, frame.size.height);
		frontMonthView = [[KalMonthView alloc] initWithFrame:monthRect];
		frontMonthView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
		backMonthView = [[KalMonthView alloc] initWithFrame:monthRect];
		backMonthView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
		backMonthView.hidden = YES;
		[self addSubview:backMonthView];
		[self addSubview:frontMonthView];
		
		[self jumpToSelectedMonth];
	}
	return self;
}

- (void)drawRect:(CGRect)rect
{
	[[[KalGridView appearance] gridBackgroundImage] drawInRect:rect];
	[[UIColor colorWithRed:0.63f green:0.65f blue:0.68f alpha:1.f] setFill];
	CGRect line;
	line.origin = CGPointMake(0.f, self.height - 1.f);
	line.size = CGSizeMake(self.width, 1.f);
	CGContextFillRect(UIGraphicsGetCurrentContext(), line);
}

- (void)sizeToFit
{
	self.height = frontMonthView.height;
}

#pragma mark -
#pragma mark Touches

- (void)setHighlightedTile:(KalTileView *)tile
{
	if (highlightedTile != tile) {
		highlightedTile.highlighted = NO;
		highlightedTile = tile;
		tile.highlighted = YES;
	}
}

- (void)setSelectedTile:(KalTileView *)tile
{
	if (selectedTile != tile) {
		selectedTile.selected = NO;
		selectedTile = tile;
		tile.selected = YES;
		if (tile != nil) {
			_selectedDate = selectedTile.date;
		}
		[delegate didSelectDate:tile.date];
	}
}

- (void)receivedTouches:(NSSet *)touches withEvent:event
{
	UITouch *touch = [touches anyObject];
	CGPoint location = [touch locationInView:self];
	UIView *hitView = [self hitTest:location withEvent:event];
	
	if (!hitView)
		return;
	
	if ([hitView isKindOfClass:[KalTileView class]]) {
		KalTileView *tile = (KalTileView*)hitView;
		if (tile.belongsToAdjacentMonth) {
			self.highlightedTile = tile;
		} else {
			self.highlightedTile = nil;
			self.selectedTile = tile;
		}
	}
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self receivedTouches:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self receivedTouches:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	CGPoint location = [touch locationInView:self];
	UIView *hitView = [self hitTest:location withEvent:event];
	
	if ([hitView isKindOfClass:[KalTileView class]]) {
		KalTileView *tile = (KalTileView*)hitView;
		if (tile.belongsToAdjacentMonth) {
			if ([tile.date compare:[KalDate dateFromNSDate:logic.baseDate]] == NSOrderedDescending) {
				[delegate showFollowingMonth];
			} else {
				[delegate showPreviousMonth];
			}
			self.selectedTile = [frontMonthView tileForDate:tile.date];
		} else {
			self.selectedTile = tile;
		}
		[delegate userDidSelectDate:self.selectedTile.date];
	}
	self.highlightedTile = nil;
}

#pragma mark -
#pragma mark Slide Animation

- (void)swapMonthsAndSlide:(int)direction keepOneRow:(BOOL)keepOneRow
{
	backMonthView.hidden = NO;
	
	// set initial positions before the slide
	
	if (direction == SLIDE_UP) {
		backMonthView.top = keepOneRow
		? frontMonthView.bottom - kTileSize.height
		: frontMonthView.bottom;
	} else if (direction == SLIDE_DOWN) {
		NSUInteger numWeeksToKeep = keepOneRow ? 1 : 0;
		NSInteger numWeeksToSlide = [backMonthView numWeeks] - numWeeksToKeep;
		backMonthView.top = -numWeeksToSlide * kTileSize.height;
	} else if (direction == SLIDE_LEFT) {
		backMonthView.left = frontMonthView.right;
	} else if (direction == SLIDE_RIGHT) {
		backMonthView.right = frontMonthView.left;
	} else {
		backMonthView.top = 0.f;
	}
	
	KalTileView* oldSelectedTile = selectedTile;
	selectedTile = nil;
	
	// trigger the slide animation
	[UIView setAnimationsEnabled:direction!=SLIDE_NONE];
	[UIView animateWithDuration:.3 animations:^{
		if (direction == SLIDE_UP || direction == SLIDE_DOWN){
			frontMonthView.top = -backMonthView.top;
			backMonthView.top = 0.f;
		} else {
			frontMonthView.left = - backMonthView.left;
			backMonthView.left = 0;
		}
		
		if ([KalGridView appearance].fadeMonthsOnSlide) {
			frontMonthView.alpha = 0.f;
			backMonthView.alpha = 1.f;
		}
		
		self.height = backMonthView.height;
		
		[self swapMonthViews];
	} completion: ^(BOOL finished){
		transitioning = NO;
		backMonthView.hidden = YES;
		oldSelectedTile.selected = NO;
	}
	];
	
	[UIView setAnimationsEnabled:YES];
}

- (void)slide:(int)direction
{
	transitioning = YES;
	
	[backMonthView showDates:logic.daysInSelectedMonth
		leadingAdjacentDates:logic.daysInFinalWeekOfPreviousMonth
	   trailingAdjacentDates:logic.daysInFirstWeekOfFollowingMonth];
	
	// At this point, the calendar logic has already been advanced or retreated to the
	// following/previous month, so in order to determine whether there are
	// any cells to keep, we need to check for a partial week in the month
	// that is sliding offscreen.
	
	BOOL keepOneRow = (direction == SLIDE_UP && [logic.daysInFinalWeekOfPreviousMonth count] > 0)
	|| (direction == SLIDE_DOWN && [logic.daysInFirstWeekOfFollowingMonth count] > 0);
	
	[self swapMonthsAndSlide:direction keepOneRow:keepOneRow];
	
	// NSLog(@"Selected date = %@",self.selectedDate);
	
	[self selectDate:self.selectedDate];
}

- (void)slideUp { if ([KalGridView appearance].slideHorizontal) [self slide:SLIDE_LEFT]; else [self slide:SLIDE_UP]; }
- (void)slideDown { if ([KalGridView appearance].slideHorizontal) [self slide:SLIDE_RIGHT]; else [self slide:SLIDE_DOWN]; }

#pragma mark -

- (void)selectDate:(KalDate *)date
{
	self.selectedDate = date;
	self.selectedTile = [frontMonthView tileForDate:date];
}

- (void)swapMonthViews
{
	KalMonthView *tmp = backMonthView;
	backMonthView = frontMonthView;
	frontMonthView = tmp;
	[self exchangeSubviewAtIndex:[self.subviews indexOfObject:frontMonthView] withSubviewAtIndex:[self.subviews indexOfObject:backMonthView]];
}

- (void)jumpToSelectedMonth
{
	[self slide:SLIDE_NONE];
}

- (void)markTilesForDates:(NSArray *)dates { [frontMonthView markTilesForDates:dates]; }

- (KalDate *)selectedDate { return _selectedDate; }

#pragma mark -


@end
