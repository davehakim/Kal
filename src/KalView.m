/* 
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import "KalView.h"
#import "KalGridView.h"
#import "KalLogic.h"
#import "KalPrivate.h"

static KalView* __sharedAppearance = nil;

@interface KalView ()
- (void)addSubviewsToHeaderView:(UIView *)headerView;
- (void)addSubviewsToContentView:(UIView *)contentView;
- (void)setHeaderTitleText:(NSString *)text;
@end

static const CGFloat kHeaderHeight = 44.f;
static const CGFloat kMonthLabelHeight = 17.f;
extern CGSize kTileSize;

@implementation KalView

@synthesize delegate, tableView,gridView=gridView;

+ (KalView*) appearance {
	if (__sharedAppearance == nil) { __sharedAppearance = [[KalView alloc] init];}
	return __sharedAppearance;
}

- (KalView*) init {
	if ((self = [super init])) {
		self.backgroundImage = [UIImage imageNamed:@"Kal.bundle/kal_grid_background.png"];
		self.leftArrowImage = [UIImage imageNamed:@"Kal.bundle/kal_left_arrow.png"];
		self.rightArrowImage = [UIImage imageNamed:@"Kal.bundle/kal_right_arrow.png"];
		self.backgroundColor = [UIColor grayColor];
		self.titleFont = [UIFont boldSystemFontOfSize:22.f];
		self.titleColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Kal.bundle/kal_header_text_fill.png"]];
		self.titleShadowColor = [UIColor whiteColor];
		self.weekdayFont = [UIFont boldSystemFontOfSize:10.f];
		self.weekdayColor = [UIColor colorWithRed:0.3f green:0.3f blue:0.3f alpha:1.f];
		self.weekdayShadowColor = [UIColor whiteColor];
	}
	return self;
}


- (id)initWithFrame:(CGRect)frame delegate:(id<KalViewDelegate>)theDelegate logic:(KalLogic *)theLogic
{
  if ((self = [super initWithFrame:frame])) {
    delegate = theDelegate;
    logic = theLogic;
    [logic addObserver:self forKeyPath:@"selectedMonthNameAndYear" options:NSKeyValueObservingOptionNew context:NULL];
    self.autoresizesSubviews = YES;
    self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, frame.size.width, kHeaderHeight)];
	  headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin ;
    headerView.backgroundColor = [[KalView appearance] backgroundColor];
    [self addSubviewsToHeaderView:headerView];
    [self addSubview:headerView];
    
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0.f, kHeaderHeight, frame.size.width, frame.size.height - kHeaderHeight)];
    contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin ;
    [self addSubviewsToContentView:contentView];
	  contentView.backgroundColor = [UIColor blackColor];
    [self addSubview:contentView];
	  
	  self.clipsToBounds = YES;
  }
  
  return self;
}

- (void)redrawEntireMonth { [self jumpToSelectedMonth]; }

- (void)slideDown { [gridView slideDown]; }
- (void)slideUp { [gridView slideUp]; }

- (void)showPreviousMonth
{
  if (!gridView.transitioning)
    [delegate showPreviousMonth];
}

- (void)showFollowingMonth
{
  if (!gridView.transitioning)
    [delegate showFollowingMonth];
}

- (float) calendarOnlyHeight {
	return kHeaderHeight + gridView.height; // kHeaderHeight + 5* kTileSize.height;
}


- (void)addSubviewsToHeaderView:(UIView *)headerView
{
	const CGFloat kChangeMonthButtonWidth = 46.0f;
	const CGFloat kChangeMonthButtonHeight = 30.0f;
	const CGFloat kMonthLabelWidth = 200.0f;
	const CGFloat kHeaderVerticalAdjust = 3.f;
	
	// Header background gradient
	UIImageView *backgroundView = [[UIImageView alloc] initWithImage:[[KalView appearance] backgroundImage]];
	CGRect imageFrame = headerView.frame;
	imageFrame.origin = CGPointZero;
	backgroundView.frame = imageFrame;
	[headerView addSubview:backgroundView];
	
	// Create the previous month button on the left side of the view
	CGRect previousMonthButtonFrame = CGRectMake(self.left,
												 kHeaderVerticalAdjust,
												 kChangeMonthButtonWidth,
												 kChangeMonthButtonHeight);
	UIButton *previousMonthButton = [[UIButton alloc] initWithFrame:previousMonthButtonFrame];
	previousMonthButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	[previousMonthButton setAccessibilityLabel:NSLocalizedString(@"Previous month", nil)];
	[previousMonthButton setImage:[KalView appearance].leftArrowImage forState:UIControlStateNormal];
	previousMonthButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
	previousMonthButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	[previousMonthButton addTarget:self action:@selector(showPreviousMonth) forControlEvents:UIControlEventTouchUpInside];
	[headerView addSubview:previousMonthButton];
	
	// Draw the selected month name centered and at the top of the view
	CGRect monthLabelFrame = CGRectMake((self.width/2.0f) - (kMonthLabelWidth/2.0f),
										kHeaderVerticalAdjust,
										kMonthLabelWidth,
										kMonthLabelHeight);
	headerTitleLabel = [[UILabel alloc] initWithFrame:monthLabelFrame];
	headerTitleLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	headerTitleLabel.backgroundColor = [UIColor clearColor];
	headerTitleLabel.font = [[KalView appearance] titleFont];
	headerTitleLabel.textAlignment = NSTextAlignmentCenter;
	headerTitleLabel.textColor = [[KalView appearance] titleColor];
	headerTitleLabel.shadowColor = [[KalView appearance] titleShadowColor];
	headerTitleLabel.shadowOffset = CGSizeMake(0.f, 1.f);
	[self setHeaderTitleText:[logic selectedMonthNameAndYear]];
	[headerView addSubview:headerTitleLabel];
	
	// Create the next month button on the right side of the view
	CGRect nextMonthButtonFrame = CGRectMake(self.width - kChangeMonthButtonWidth,
											 kHeaderVerticalAdjust,
											 kChangeMonthButtonWidth,
											 kChangeMonthButtonHeight);
	UIButton *nextMonthButton = [[UIButton alloc] initWithFrame:nextMonthButtonFrame];
	nextMonthButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	[nextMonthButton setAccessibilityLabel:NSLocalizedString(@"Next month", nil)];
	[nextMonthButton setImage:[KalView appearance].rightArrowImage forState:UIControlStateNormal];
	nextMonthButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
	nextMonthButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	[nextMonthButton addTarget:self action:@selector(showFollowingMonth) forControlEvents:UIControlEventTouchUpInside];
	[headerView addSubview:nextMonthButton];
	
	// Add column labels for each weekday (adjusting based on the current locale's first weekday)
	NSArray *weekdayNames = [[[NSDateFormatter alloc] init] shortWeekdaySymbols];
	NSArray *fullWeekdayNames = [[[NSDateFormatter alloc] init] standaloneWeekdaySymbols];
	NSUInteger firstWeekday = [[NSCalendar currentCalendar] firstWeekday];
	NSUInteger i = firstWeekday - 1;
	
	// Make day label spacing dynamic
	float tileWidth = headerView.width / 7;
	for (CGFloat xOffset = 0.f; xOffset < headerView.width; xOffset += tileWidth, i = (i+1)%7) {
		CGRect weekdayFrame = CGRectMake(xOffset, 30.f, tileWidth, kHeaderHeight - 29.f);
		UILabel *weekdayLabel = [[UILabel alloc] initWithFrame:weekdayFrame];
		weekdayLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
		
		weekdayLabel.backgroundColor = [UIColor clearColor];
		weekdayLabel.font = [[KalView appearance] weekdayFont];
		weekdayLabel.textAlignment = NSTextAlignmentCenter;
		weekdayLabel.textColor = [[KalView appearance] weekdayColor];
		weekdayLabel.shadowColor = [[KalView appearance] weekdayShadowColor];
		weekdayLabel.shadowOffset = CGSizeMake(0.f, 1.f);
		weekdayLabel.text = [weekdayNames objectAtIndex:i];
		[weekdayLabel setAccessibilityLabel:[fullWeekdayNames objectAtIndex:i]];
		[headerView addSubview:weekdayLabel];
	}
}

- (void)addSubviewsToContentView:(UIView *)contentView
{
  // Both the tile grid and the list of events will automatically lay themselves
  // out to fit the # of weeks in the currently displayed month.
  // So the only part of the frame that we need to specify is the width.
  CGRect fullWidthAutomaticLayoutFrame = CGRectMake(0.f, 0.f, self.width, 0.f);

  // The tile grid (the calendar body)
  gridView = [[KalGridView alloc] initWithFrame:fullWidthAutomaticLayoutFrame logic:logic delegate:delegate];
	gridView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
  [gridView addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:NULL];
  [contentView addSubview:gridView];

  // The list of events for the selected day
  /* tableView = [[UITableView alloc] initWithFrame:fullWidthAutomaticLayoutFrame style:UITableViewStylePlain];
  tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [contentView addSubview:tableView]; */
  
  // Drop shadow below tile grid and over the list of events for the selected day
  shadowView = [[UIImageView alloc] initWithFrame:fullWidthAutomaticLayoutFrame];
  shadowView.image = [UIImage imageNamed:@"Kal.bundle/kal_grid_shadow.png"];
	shadowView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
  shadowView.height = shadowView.image.size.height;
  //[contentView addSubview:shadowView];
  
  // Trigger the initial KVO update to finish the contentView layout
  [gridView sizeToFit];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  if (object == gridView && [keyPath isEqualToString:@"frame"]) {
    
    /* Animate tableView filling the remaining space after the
     * gridView expanded or contracted to fit the # of weeks
     * for the month that is being displayed.
     *
     * This observer method will be called when gridView's height
     * changes, which we know to occur inside a Core Animation
     * transaction. Hence, when I set the "frame" property on
     * tableView here, I do not need to wrap it in a
     * [UIView beginAnimations:context:].
     */
    CGFloat gridBottom = gridView.top + gridView.height;
    CGRect frame = tableView.frame;
    frame.origin.y = gridBottom;
    frame.size.height = tableView.superview.height - gridBottom;
    tableView.frame = frame;
    shadowView.top = gridBottom;
    
  } else if ([keyPath isEqualToString:@"selectedMonthNameAndYear"]) {
    [self setHeaderTitleText:[change objectForKey:NSKeyValueChangeNewKey]];
    
  } else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

- (void)setHeaderTitleText:(NSString *)text
{
  [headerTitleLabel setText:text];
  [headerTitleLabel sizeToFit];
  headerTitleLabel.left = floorf(self.width/2.f - headerTitleLabel.width/2.f);
}

- (void)jumpToSelectedMonth { [gridView jumpToSelectedMonth]; }

- (void)selectDate:(KalDate *)date { [gridView selectDate:date]; }

- (BOOL)isSliding { return gridView.transitioning; }

- (void)markTilesForDates:(NSArray *)dates { [gridView markTilesForDates:dates]; }

- (KalDate *)selectedDate { return gridView.selectedDate; }

- (void)dealloc
{
  [logic removeObserver:self forKeyPath:@"selectedMonthNameAndYear"];
  
  [gridView removeObserver:self forKeyPath:@"frame"];
}

@end
