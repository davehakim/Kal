/* 
 * Copyright (c) 2010 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import "CustomCalAppDelegate.h"
#import "EventKitDataSource.h"
#import "Kal.h"

#import "KalTileView.h"
#import "KalGridView.h"

#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>

@implementation CustomCalAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
  /*
   *    Kal Initialization
   *
   * When the calendar is first displayed to the user, Kal will automatically select today's date.
   * If your application requires an arbitrary starting date, use -[KalViewController initWithSelectedDate:]
   * instead of -[KalViewController init].
   */
  kal = [[KalViewController alloc] init];
  kal.title = @"NativeCal";

  /*
   *    Kal Configuration
   *
   */
  kal.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Today" style:UIBarButtonItemStyleBordered target:self action:@selector(showAndSelectToday)] autorelease];
  kal.delegate = self;
  dataSource = [[EventKitDataSource alloc] init];
  kal.dataSource = dataSource;

  // Setup the navigation stack and display it.
  navController = [[UINavigationController alloc] initWithRootViewController:kal];
	navController.navigationBar.translucent = NO;
	window.rootViewController = navController;

	[self customizeAppearance];
  [window makeKeyAndVisible];
}

- (void) customizeAppearance {
	[[KalTileView appearance] setFont:[UIFont fontWithName:@"HelveticaNeue" size:12]];
	[[KalTileView appearance] setTextAlignment:NSTextAlignmentLeft];
	[[KalTileView appearance] setTextVAlignment:0];
	[[KalTileView appearance] setTextColor:[UIColor whiteColor]];
	[[KalTileView appearance] setTextColorSelected:[UIColor blackColor]];
	[[KalTileView appearance] setTextShadowColor:nil];
	[[KalTileView appearance] setTextShadowColorAdjacentMonth:nil];
	[[KalTileView appearance] setTextShadowColorSelected:nil];
	[[KalTileView appearance] setTextXOffset:4];
	
	UIImage* tileImageTodaySelected = [[UIImage imageNamed:@"calendarSelectedTileBackground"] resizableImageWithCapInsets:UIEdgeInsetsMake(1, 5, 1, 5)];
	[[KalTileView appearance] setTileImageTodaySelected:tileImageTodaySelected ];
	
	UIImage* tileImageToday = [[UIImage imageNamed:@"calendarTodayTileBackground"] resizableImageWithCapInsets:UIEdgeInsetsMake(1, 5, 1, 5)];
	[[KalTileView appearance] setTileImageToday:tileImageToday ];
	
	UIImage* tileImageSelected = [[UIImage imageNamed:@"calendarSelectedTileBackground"] resizableImageWithCapInsets:UIEdgeInsetsMake(1, 5, 1, 5)];
	[[KalTileView appearance] setTileImageSelected:tileImageSelected];
	
	UIImage* tileBackgroundImage = [[UIImage imageNamed:@"calendarTileBackground"] resizableImageWithCapInsets:UIEdgeInsetsMake(1, 5, 1, 5)];
	[[KalTileView appearance] setTileBackgroundImage:tileBackgroundImage];
	
	[KalGridView appearance].gridBackgroundImage=[UIImage imageNamed:@"calendarGridBackground"];
	[KalGridView appearance].slideHorizontal = YES;
	[KalGridView appearance].fadeMonthsOnSlide = NO;
	
	[KalView appearance].backgroundColor = [UIColor blackColor];
	[KalView appearance].backgroundImage = nil;
	[KalView appearance].leftArrowImage = [UIImage imageNamed:@"calendarLeftArrow"];
	[KalView appearance].rightArrowImage = [UIImage imageNamed:@"calendarRightArrow"];;
	[KalView appearance].titleFont = [UIFont fontWithName:@"HelveticaNeue" size:18];
	[KalView appearance].titleColor = [UIColor whiteColor];
	[KalView appearance].titleShadowColor = nil;
	[KalView appearance].weekdayFont = [UIFont fontWithName:@"HelveticaNeue" size:10];
	[KalView appearance].weekdayColor = [UIColor whiteColor];
	[KalView appearance].weekdayShadowColor = nil;
}

// Action handler for the navigation bar's right bar button item.
- (void)showAndSelectToday
{
  [kal showAndSelectDate:[NSDate date]];
}

#pragma mark UITableViewDelegate protocol conformance

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  // Display a details screen for the selected event/row.
  EKEventViewController *vc = [[[EKEventViewController alloc] init] autorelease];
  vc.event = [dataSource eventAtIndexPath:indexPath];
  vc.allowsEditing = NO;
  [navController pushViewController:vc animated:YES];
}

#pragma mark -

- (void)dealloc
{
  [kal release];
  [dataSource release];
  [window release];
  [navController release];
  [super dealloc];
}

@end
