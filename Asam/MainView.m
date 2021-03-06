#import "MainView.h"
#import "AppDelegate.h"
#import "DSActivityView.h"
#import "AsamDisclaimerView.h"
#import "REVClusterMap.h"
#import "REVClusterAnnotationView.h"
#import "AsamUtility.h"
#import <MapKit/MapKit.h>
#import "AsamDetailView.h"
#import "AsamSearch.h"
#import "AsamListView.h"
#import "SubRegionView.h"
#import "AboutAsam.h"
#import "SettingsViewController.h"
#import "Asam.h"
#import "AsamFetch.h"
#import "DDActionHeaderView.h"
#import "AsamDownloader.h"
#import "AsamConstants.h"
#import "NSString+StringFromDate.h"
#import "OfflineMapUtility.h"
#import "MapLayoutGuide.h"


@interface MainView() <UIPopoverControllerDelegate, MKMapViewDelegate, AsamSearchDelegate, SubRegionDelegate, AsamUpdateDelegate>

@property (nonatomic, strong) NSArray *asamArray;
@property (nonatomic, strong) NSArray *displayAsamInListArray;
@property (nonatomic, strong) UIPopoverController *asamListPopOver;
@property (nonatomic, strong) UIPopoverController *callOutPopOver;
@property (nonatomic, strong) UIPopoverController *settingsPopOver; 
@property (nonatomic, strong) UIPopoverController *asamSearchPopOver;
@property (nonatomic, strong) SettingsViewController *asamSettingsView;
@property (nonatomic, strong) AsamListView *asamListView;
@property (nonatomic, strong) AsamDetailView *asamDetailView;
@property (nonatomic, strong) IBOutlet DDActionHeaderView *actionHeaderView;
@property (nonatomic, strong) AsamSearch *asamSearchView;
@property (nonatomic, strong) IBOutlet UISlider *slider;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *titleButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *asamListButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *subregionsButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *settingsButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *searchButton;
@property (nonatomic, strong) IBOutlet REVClusterMapView *mapView;
@property (nonatomic, strong) IBOutlet UIToolbar *toolBar;
@property (nonatomic, strong) IBOutlet UILabel *asamTotalLabel;
@property (nonatomic, strong) IBOutlet UILabel *asamLabelDisplayed;
@property (nonatomic, strong) AsamUtility *asamUtil;
@property (nonatomic, strong) UIButton *restartButton;
@property (weak, nonatomic) IBOutlet UIView *statusBarBackground;

- (IBAction)showAsamList:(id)sender;
- (IBAction)asamSearchView:(id)sender;
- (IBAction)showAsamSettings:(id)sender;
- (IBAction)sliderChanged:(id)sender;
- (IBAction)restart:(id)sender;
- (IBAction)goToSubregionView:(id)sender;
- (IBAction)aboutAsam:(id)sender;

- (void)populateAsams:(id)sender;
- (void)populateMap:(NSArray *)array withNumber:(id)numberOfAsam initializeWithOneYear:(BOOL)oneYear;
- (void)updateAsamFromDate;
- (NSInteger)getPositionOfIndexInArrayByDate:(NSArray *)array withNumber:(NSUInteger)numberOfAsam withDate:(NSDate *)targetDate;
- (void)populateMapWithAsams:(id)sender;
- (void)setMapType: (NSString *)type;

@end


@implementation MainView

#pragma mark - Functions
- (IBAction)showAsamList:(id)sender {
    
    // Dismiss the other popovers if visible
    if ([self.settingsPopOver isPopoverVisible]) {
        [self.settingsPopOver dismissPopoverAnimated:YES];
    }
    if ([self.asamSearchPopOver isPopoverVisible]) {
        [self.asamSearchPopOver dismissPopoverAnimated:YES];
    }
    
    if (![self.asamListPopOver isPopoverVisible]) {
		AsamListView *asamListView = [[AsamListView alloc] initWithNibName:@"AsamListView" bundle:nil];
        NSSortDescriptor *dateDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"dateofOccurrence" ascending:NO selector:@selector(compare:)];
        NSArray *sortDescriptors = @[dateDescriptor];
        asamListView.asamArray = [self.displayAsamInListArray sortedArrayUsingDescriptors:sortDescriptors];

        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:asamListView];

		self.asamListPopOver = [[UIPopoverController alloc] initWithContentViewController:navController];
        
        if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) { // iOS 7+
            self.asamListView.edgesForExtendedLayout = UIRectEdgeNone;
            self.asamListPopOver.backgroundColor = [UIColor colorWithWhite:(64/255.0f) alpha:1.0f];
            navController.navigationBar.tintColor = [UIColor whiteColor];
        }
        self.asamListPopOver.delegate = self;
        
        if ([navController respondsToSelector:@selector(setPreferredContentSize:)]) {
            [navController setPreferredContentSize:CGSizeMake(320.0f, 500.0f)];
        }
        else {
            self.asamListView.contentSizeForViewInPopover = CGSizeMake(320.0f, 500.0f);
        }

        [self.navigationController pushViewController:asamListView animated:YES];
        
        [self.asamListPopOver presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];

	}
    else {
		[self.asamListPopOver dismissPopoverAnimated:YES];
	}
}

- (IBAction)showAsamSettings:(id)sender {
    
    // Dismiss the other popovers if visible
    if ([self.asamListPopOver isPopoverVisible]) {
        [self.asamListPopOver dismissPopoverAnimated:YES];
    }
    if ([self.asamSearchPopOver isPopoverVisible]) {
        [self.asamSearchPopOver dismissPopoverAnimated:YES];
    }
    
    if (![self.settingsPopOver isPopoverVisible]) {
		self.asamSettingsView = [[SettingsViewController alloc] initWithNibName:@"SettingsView" bundle:nil];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.asamSettingsView];
        
        self.settingsPopOver = [[UIPopoverController alloc] initWithContentViewController:navController];

        if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) { // iOS 7+
            self.asamSettingsView.edgesForExtendedLayout = UIRectEdgeNone;
            self.settingsPopOver.backgroundColor = [UIColor colorWithWhite:(64/255.0f) alpha:1.0f];
            self.settingsPopOver.popoverContentSize = CGSizeMake(400.0f, 235.0f);
            navController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
            navController.navigationBar.barTintColor = [UIColor colorWithWhite:(64/255.0f) alpha:1.0f];
            navController.navigationBar.translucent = NO;
            navController.navigationBar.tintColor = [UIColor whiteColor];
        }
        else {
            self.settingsPopOver.popoverContentSize = CGSizeMake(400.0f, 250.0f);
        }
        [self.settingsPopOver presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        self.asamSettingsView.asamUpdateDelegate = self;

	}
    else {
		[self.settingsPopOver dismissPopoverAnimated:YES];
	}
}

- (IBAction)asamSearchView:(id)sender {
    
    // Dismiss the other popovers if visible
    if ([self.asamListPopOver isPopoverVisible]) {
        [self.asamListPopOver dismissPopoverAnimated:YES];
    }
    if ([self.settingsPopOver isPopoverVisible]) {
        [self.settingsPopOver dismissPopoverAnimated:YES];
    }
    
    if (![self.asamSearchPopOver isPopoverVisible]) {
		self.asamSearchView = [[AsamSearch alloc] initWithNibName:@"AsamSearch" bundle:nil];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.asamSearchView];
                
        self.asamSearchPopOver = [[UIPopoverController alloc] initWithContentViewController:navController];

        if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) { // iOS 7+
            self.asamSearchView.edgesForExtendedLayout = UIRectEdgeNone;
            self.asamSearchPopOver.backgroundColor = [UIColor colorWithWhite:(64/255.0f) alpha:1.0f];
            navController.navigationBar.tintColor = [UIColor whiteColor];
        }
        if ([self.asamSearchView respondsToSelector:@selector(setPreferredContentSize:)]) {
            self.asamSearchView.preferredContentSize = CGSizeMake(320.0f, 400.0f);
        }
        else {
            self.asamSearchView.contentSizeForViewInPopover = CGSizeMake(320.0f, 400.0f);
        }
        self.asamSearchView.asamSearchDelegate = self;
		[self.asamSearchPopOver presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        self.asamSearchPopOver.delegate = self;
	}
    else {
		[self.asamSearchPopOver dismissPopoverAnimated:YES];
	}
}

- (IBAction)goToSubregionView:(id)sender {
    SubRegionView *subRegion = [[SubRegionView alloc] initWithNibName:@"SubRegionView" bundle:[NSBundle mainBundle]];
    subRegion.subRegionDelegate = self;
    subRegion.modalPresentationStyle = UIModalPresentationFullScreen;
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) { // iOS 7+
        subRegion.view.backgroundColor = [UIColor clearColor];
    }
    [self presentViewController:subRegion animated:YES completion:nil];
}

- (IBAction)aboutAsam:(id)sender {
    AboutAsam *viewController = [[AboutAsam alloc] initWithNibName:@"AboutAsam" bundle:nil];
	UINavigationController *modalViewNavController = [[UINavigationController alloc] initWithRootViewController:viewController];
    
    modalViewNavController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	modalViewNavController.modalPresentationStyle = UIModalPresentationFormSheet;;
    [self presentViewController:modalViewNavController animated:YES completion:nil];
}

- (IBAction)sliderChanged:(id)sender {
    int progressAsInt = (int)(self.slider.value);
    self.asamTotalLabel.text = [NSString stringWithFormat:@"Showing %i out of %lu ASAM(s)", progressAsInt, (unsigned long)[self.asamArray count]];
    NSInteger arg = progressAsInt;
    id withObject = [NSNumber numberWithInt:(int)arg];
    [DSBezelActivityView activityViewForView:self.view withLabel:@"Fetching ASAM(s)..." width:180];
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    dispatch_async(mainQueue, ^{
        if (self.mapView.annotations != nil && self.mapView.annotations.count > 0) {
            [self.mapView removeAnnotations:self.mapView.annotations];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self populateMap:self.asamArray withNumber:withObject initializeWithOneYear:FALSE];
        });
        dispatch_async(mainQueue, ^{
            [DSBezelActivityView removeViewAnimated:YES];
        });
    });
}

- (IBAction)restart:(id)sender {
    [self.restartButton setEnabled:NO];
    [self populateMapWithAsams:@"90"];
}

- (void)populateAsams:(id)sender {
    NSSortDescriptor *dateDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"dateofOccurrence" ascending:NO selector:@selector(compare:)];
    NSArray *sortDescriptors = @[dateDescriptor];
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] init];	
    context.persistentStoreCoordinator = [appDelegate persistentStoreCoordinator];

    if ([sender isKindOfClass:[NSString class]]) {
        self.asamArray = [[context fetchObjectsForEntityName:@"Asam"] sortedArrayUsingDescriptors:sortDescriptors];
    }
    else if ([sender isKindOfClass:[NSPredicate class]]) {
        self.asamArray = [[context fetchObjectsForEntityName:@"Asam" withPredicate:sender] sortedArrayUsingDescriptors:sortDescriptors];
    }
    
    if (self.asamArray.count == 0) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"0 ASAM found" message:@"Select a different search parameter." delegate:nil  cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [self.asamTotalLabel setText:@"0 ASAM(s) found"];
        if (self.mapView.annotations != nil && self.mapView.annotations.count > 0) {
            [self.mapView removeAnnotations:self.mapView.annotations];
        }
        self.slider.enabled = NO;
        self.asamLabelDisplayed.text =  @"";
        self.asamArray = nil;
        self.displayAsamInListArray = nil;
        [message show];
        return;
    }

    int sliderValue;
    BOOL oneYear = FALSE;
    if (self.asamArray.count <= 100) {
        self.asamTotalLabel.text = [NSString stringWithFormat:@"Showing %lu ASAM(s)", (unsigned long)self.asamArray.count];
        sliderValue = (int)self.asamArray.count;
        self.slider.enabled = NO;
    }
    else {
        sliderValue = self.asamArray.count * 0.10;
        if ([sender isKindOfClass:[NSString class]]) {
            oneYear = TRUE;
            NSDate *today = [[NSDate alloc] init];
            NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
            NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
            [offsetComponents setYear:-1];
            NSDate *targetDate = [gregorian dateByAddingComponents:offsetComponents toDate:today options:0];
            sliderValue = (int)[self getPositionOfIndexInArrayByDate:self.asamArray withNumber:self.asamArray.count withDate:targetDate];
            if (sliderValue == 0) {
                sliderValue = 1;
            }
        }
        else if ([sender isKindOfClass:[NSPredicate class]]) {
            sliderValue = (int)self.asamArray.count;
        }
            
        self.slider.minimumValue = 1.0;
        self.slider.maximumValue = self.asamArray.count;
        self.slider.continuous = NO;
        self.slider.value = sliderValue;

        self.asamTotalLabel.text = [NSString stringWithFormat:@"Showing %i out of %lu ASAM(s)", sliderValue, (unsigned long)self.asamArray.count];
        self.slider.enabled = YES;
    }
    NSInteger arg = sliderValue;
    id senderValue = [NSNumber numberWithInt:(int)arg];
    [self populateMap:self.asamArray withNumber:senderValue initializeWithOneYear:oneYear];
}

- (void)populateMap:(NSArray *)array withNumber:(id)numberOfAsam initializeWithOneYear:(BOOL)oneYear {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"MM/dd/yyyy";
    NSMutableArray *pins = [[NSMutableArray alloc] init];
    for (NSManagedObject *asamManagedObject in self.asamArray) {
        Asam *asam = (Asam*)[appDelegate.managedObjectContext objectWithID:asamManagedObject.objectID];
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([asam.decimalLatitude doubleValue], [asam.decimalLongitude doubleValue]);
        
        REVClusterPin *pin = [[REVClusterPin alloc] init];
        pin.title = asam.victim;
        pin.subtitle = [formatter stringFromDate:asam.dateofOccurrence];
        pin.victim = asam.victim;
        pin.dateofOccurrence = asam.dateofOccurrence;
        pin.geographicalSubregion = asam.geographicalSubregion;
        pin.aggressor = asam.aggressor;
        pin.theCoordinate = coordinate;
        pin.asamDescription = asam.asamDescription;
        pin.referenceNumber = asam.referenceNumber;
        pin.degreeLongitude = [asam formatLongitude];
        pin.degreeLatitude = [asam formatLatitude];
        pin.coordinate = coordinate;
        [pins addObject:pin];
        if (pins.count == [numberOfAsam integerValue]) {
            break;
        }
    }
    [self.mapView addAnnotations:pins];
    
     // Walk the list of overlays and annotations and create a MKMapRect that
     // bounds all of them and store it into flyTo.
     MKMapRect flyTo = MKMapRectNull;
     for (id<MKAnnotation> annotation in pins) {
         MKMapPoint annotationPoint;
         if (![annotation isKindOfClass:[MKUserLocation class]]) {
            if ([annotation isKindOfClass:[REVClusterPin class]]) {
                REVClusterPin *pin = (REVClusterPin *)annotation;
                if (pin.nodeCount > 0) {
                    REVClusterPin *selectedPin = (REVClusterPin *)[pin.nodes objectAtIndex:0];
                    annotationPoint = MKMapPointForCoordinate(selectedPin.coordinate);
                }
                else {
                    annotationPoint = MKMapPointForCoordinate(annotation.coordinate);
                }
            }
            MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0, 0);
            if (MKMapRectIsNull(flyTo)) {
                flyTo = pointRect;
            }
            else {
                flyTo = MKMapRectUnion(flyTo, pointRect);
            }
        }
    }
    
    // Position the map so that all overlays and annotations are visible on screen.
    self.mapView.visibleMapRect = flyTo;
    self.displayAsamInListArray = [NSArray arrayWithArray:pins];
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *formattedDate = [prefs objectForKey:kLastSyncDateKey];
    if (formattedDate == nil) {
        formattedDate = [NSString getStringFromDate:[AsamUtility fetchAndFomatLastSyncDate]];
        [prefs setObject:formattedDate forKey:kLastSyncDateKey];
        [prefs synchronize];
    }
    if (oneYear) {
        NSDate *today = [[NSDate alloc] init];
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
        [offsetComponents setYear:-1];
        NSDate *lastYear = [gregorian dateByAddingComponents:offsetComponents toDate:today options:0];
        self.asamLabelDisplayed.text = [NSString stringWithFormat:@"%@ to %@", formattedDate, [self.asamUtil getStringFromDate:lastYear]];
    }
    else {
        self.asamLabelDisplayed.text = [NSString stringWithFormat:@"%@ to %@", formattedDate, [self.asamUtil getStringFromDate:[self.asamUtil getOlderDateInArray:pins]]];
    }
}

- (void)updateAsamFromDate {
    if ([self.settingsPopOver isPopoverVisible]) {
		[self.settingsPopOver dismissPopoverAnimated:YES];
    }
    if (![AsamUtility reachable]) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Your device is not connected to the Internet" message:@"Network is currently offline" delegate:nil cancelButtonTitle:@"OK"  otherButtonTitles:nil];
        [message show];
        return;
    }
    [DSBezelActivityView activityViewForView:self.view withLabel:@"Fetching ASAM(s)..." width:160];
    AsamDownloader *asamDownloader = [[AsamDownloader alloc] init];
    NSString *urlToCall = [NSString stringWithFormat:@"%@%@%@%@", kAsamBaseUrl, [AsamUtility fetchAndFomatLastSyncDate], kAsamPartTwo, [AsamUtility formatTodaysDate]];
    [asamDownloader downloadAndSaveAsamsWithURL:[NSURL URLWithString:urlToCall] completionBlock:^(BOOL success,NSError *error) {
        if (!error) {
            [self populateMapWithAsams:@"90"];
            [DSBezelActivityView removeViewAnimated:YES];
        }
        else {
            [DSBezelActivityView removeViewAnimated:YES];
            UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Download Asams failed" message:@"Try again later" delegate:nil cancelButtonTitle:@"OK"  otherButtonTitles:nil];
            [message show];
            return;
        }
    }];
}

#pragma mark - Memory Warning
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma 
#pragma mark - View lifecycle
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if ((toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft)|| (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
        CGRect labelFrame = CGRectMake(750.0f, 10.0f, 210, 30);
        self.asamTotalLabel.frame = labelFrame;
    }
    else {
        CGRect labelFrame = CGRectMake(510.0f, 10, 210, 30);
        self.asamTotalLabel.frame = labelFrame;
    }
    if ([self.callOutPopOver isPopoverVisible]) {
        [self.callOutPopOver dismissPopoverAnimated:YES];
    }
    if ([self.asamListPopOver isPopoverVisible]) {
        [self.asamListPopOver dismissPopoverAnimated:YES];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *mapType = [defaults objectForKey:@"maptype"];
    [self setMapType:mapType];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkRotation:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    self.asamUtil = [[AsamUtility alloc] init];

    if ([self checkRotation:nil]) {
        CGRect labelFrame = CGRectMake(750.0f, 10.0f, 210, 30);
        self.asamTotalLabel = [[UILabel alloc] initWithFrame:labelFrame];
    }
    else {
        CGRect labelFrame = CGRectMake(510.0f, 10, 210, 30);
        self.asamTotalLabel = [[UILabel alloc] initWithFrame:labelFrame];
    }
  
    self.restartButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.restartButton addTarget:self action:@selector(restart:) forControlEvents:UIControlEventTouchUpInside];
    [self.restartButton setImage:[UIImage imageNamed:@"reset"] forState:UIControlStateNormal];
    self.restartButton.frame = CGRectMake(0.0f, 0.0f, 60.0f, 60.0f);
    self.restartButton.center = CGPointMake(25.0f, 25.0f);
    self.restartButton.accessibilityIdentifier = @"reset";
    
    self.asamLabelDisplayed.backgroundColor = [UIColor clearColor];
    self.asamLabelDisplayed.textColor = [UIColor whiteColor];
    self.asamLabelDisplayed.font = [UIFont fontWithName:@"HelveticaNeue" size:13.0];
    
    [self.slider addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
    self.slider.backgroundColor = [UIColor clearColor];
    
    self.asamTotalLabel.backgroundColor = [UIColor clearColor];
    self.asamTotalLabel.textColor = [UIColor whiteColor];
    self.asamTotalLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:13.0];
    
    UIImage *stretchableFillImage = [[UIImage imageNamed:@"slider-fill"] resizableImageWithCapInsets:UIEdgeInsetsMake(0.0f, 6.0f, 0.0f, 6.0f)];
    UIImage *stretchableTrackImage = [[UIImage imageNamed:@"slider-track"] resizableImageWithCapInsets:UIEdgeInsetsMake(0.0f, 6.0f, 0.0f, 6.0f)];
    [self.slider setMinimumTrackImage:stretchableFillImage forState:UIControlStateNormal];
    [self.slider setMaximumTrackImage:stretchableTrackImage forState:UIControlStateNormal];
    
    self.actionHeaderView.items = @[self.restartButton, self.asamLabelDisplayed, self.slider, self.asamTotalLabel];
    [self populateMapWithAsams:@"90"];
    
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) { // iOS 7+
        self.toolBar.tintColor = [UIColor whiteColor];
        self.toolBar.barTintColor = [UIColor blackColor];
        self.toolBar.alpha = .8f;
        self.view.backgroundColor = [UIColor whiteColor];
        self.asamListButton.tintColor = [UIColor whiteColor];
        self.settingsButton.tintColor = [UIColor whiteColor];
        self.subregionsButton.tintColor = [UIColor whiteColor];
        self.searchButton.tintColor = [UIColor whiteColor];
        
        [self.restartButton setTitle:@"Reset" forState:UIControlStateNormal];
        self.restartButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:13.0];
        [self.restartButton setImage:nil forState:UIControlStateNormal];
    } else {
        self.statusBarBackground.hidden = YES;
    }
}

- (void)viewDidUnload {
    self.toolBar = nil;
    self.asamListButton = nil;
    self.asamListView = nil;
    self.asamListPopOver = nil;
    self.mapView = nil;
    self.titleButton = nil;
    self.asamArray = nil;
    self.settingsPopOver = nil;
    self.asamSettingsView = nil;
    self.asamUtil = nil;
    self.actionHeaderView = nil;
    self.slider = nil;
    self.callOutPopOver = nil;
    self.asamDetailView = nil;
    self.asamTotalLabel = nil;
    self.asamLabelDisplayed = nil;
    self.asamSearchPopOver = nil;
    self.asamSearchView = nil;
    self.displayAsamInListArray = nil;
    self.restartButton = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidUnload];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.asamListPopOver dismissPopoverAnimated:YES];
    [self.settingsPopOver dismissPopoverAnimated:YES];
    [self.callOutPopOver dismissPopoverAnimated:YES];
    [self.asamSearchPopOver dismissPopoverAnimated:YES];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObserver:self forKeyPath:@"maptype"];
}

-(void)viewDidAppear:(BOOL)animated {
    
    //listen for changes to map type
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults addObserver:self
               forKeyPath:@"maptype"
                  options:NSKeyValueObservingOptionNew
                  context:NULL];
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController.navigationBar setTranslucent:NO];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

#pragma mark - Subregion delegates
- (void)setPredicate:(NSPredicate *)predicate {
    [self populateMapWithAsams:predicate];
}

- (void)isDeviceInLandscapeMode:(BOOL)value {
    if ((self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (self.interfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
        CGRect labelFrame = CGRectMake(750.0f, 10.0f, 210, 30);
        self.asamTotalLabel.frame = labelFrame;
    }
    else {
        CGRect labelFrame = CGRectMake(510.0f, 10, 210, 30);
        self.asamTotalLabel.frame = labelFrame;
    }
}

- (void)setPredicateForSearching:(NSPredicate *)predicateForSearching {
    [self populateMapWithAsams:predicateForSearching];
    [self.asamSearchPopOver dismissPopoverAnimated:YES];
}

#pragma mark - Map
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if ([annotation class] == MKUserLocation.class) {
		return nil;
	}
    REVClusterPin *pin = (REVClusterPin *)annotation;
    MKAnnotationView *annView;
    if (pin.nodeCount > 0) {
        pin.title = [NSString stringWithFormat:@"%lu ASAM(s)", (unsigned long)pin.nodeCount];
        annView = (REVClusterAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:@"cluster"];
        if (!annView) {
            annView = (REVClusterAnnotationView*)[[REVClusterAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"cluster"];
        }
        annView.image = [UIImage imageNamed:@"cluster"];
        [(REVClusterAnnotationView*)annView setClusterText:[NSString stringWithFormat:@"%lu", (unsigned long)pin.nodeCount]];
        annView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        annView.canShowCallout = NO;
    }
    else {
        annView = (REVClusterAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:@"pin"];
        if (!annView) {
            annView = (REVClusterAnnotationView*)[[REVClusterAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"pin"];
        }
        annView.image = [UIImage imageNamed:@"pirate"];
        annView.canShowCallout = NO;
        annView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        annView.calloutOffset = CGPointMake(-6.0, 0.0);
    }
    return annView;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    [mapView deselectAnnotation:view.annotation animated:YES];
    
    REVClusterPin *selectedObject = (REVClusterPin *)view.annotation;

    if (selectedObject.nodeCount > 1) {
        AsamListView *asamListView = [[AsamListView alloc] initWithNibName:@"AsamListView" bundle:nil];
        NSSortDescriptor *dateDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"dateofOccurrence" ascending:NO selector:@selector(compare:)];
        NSArray *sortDescriptors = @[dateDescriptor];
        
        asamListView.asamArray = [selectedObject.nodes sortedArrayUsingDescriptors:sortDescriptors];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:asamListView];
        self.asamListPopOver = [[UIPopoverController alloc] initWithContentViewController:navController];
        if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) { // iOS 7+
            self.asamListPopOver.backgroundColor = [UIColor blackColor];
        }
        
        if ([navController respondsToSelector:@selector(setPreferredContentSize:)]) {
            [navController setPreferredContentSize:CGSizeMake(320.0f, 500.0f)];
        }
        else {
            self.asamListView.contentSizeForViewInPopover = CGSizeMake(320.0f, 500.0f);
        }

        self.asamListPopOver.delegate = self;

        [self.navigationController pushViewController:asamListView animated:YES];
        [self.asamListPopOver presentPopoverFromRect:view.bounds inView:view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        AsamDetailView *asamDetail = [[AsamDetailView alloc] initWithNibName:@"AsamDetailView" bundle:nil];
        asamDetail.asam = selectedObject;
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:asamDetail];
        self.asamListView.navigationItem.title = @"ASAM Detail";
        self.callOutPopOver = [[UIPopoverController alloc] initWithContentViewController:navController];
        if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) { // iOS 7+
            self.callOutPopOver.backgroundColor = [UIColor blackColor];
            navController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
            navController.navigationBar.barTintColor = [UIColor colorWithWhite:(64/255.0f) alpha:1.0f];
            navController.navigationBar.translucent = NO;
        }
        
        self.callOutPopOver.delegate = self;
        self.callOutPopOver.popoverContentSize = CGSizeMake(320.0f, 400.0f);
        [self.callOutPopOver presentPopoverFromRect:view.bounds inView:view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

#pragma
#pragma mark - Private methods (UIActivityIndicator) impl.
- (void)populateMapWithAsams:(id)sender {
    [DSBezelActivityView activityViewForView:self.view withLabel:@"Fetching ASAM(s)..." width:180];
    if(self.mapView.annotations != nil && self.mapView.annotations.count > 0) {
        [self.mapView removeAnnotations:self.mapView.annotations];
    }
    
    // Fix a bug with iOS 7 in that performing this in the background fails to draw the pins.
//    [self performSelectorInBackground:@selector(populateAsams:) withObject:sender];
    [self populateAsams:sender];
    if (![self.restartButton isEnabled]) {
        self.restartButton.enabled = YES;
    }
    [DSBezelActivityView removeViewAnimated:YES];
}

- (BOOL)checkRotation:(NSNotification*)notification {
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
        return TRUE;
    }
    return FALSE;
}

- (NSInteger)getPositionOfIndexInArrayByDate:(NSArray *)array withNumber:(NSUInteger)numberOfAsam withDate:(NSDate *)targetDate {
    NSMutableArray *asamDates = [[NSMutableArray alloc]init];
    for (NSManagedObject *asamManagedObject in array) {
        Asam *asam = (Asam *)asamManagedObject;
        [asamDates addObject:asam.dateofOccurrence];
        if (asamDates.count == numberOfAsam) {
            break;
        }
    }
    
    NSArray *sorted = [asamDates sortedArrayUsingComparator:^(id obj1, id obj2) {
        if ([obj1 isKindOfClass:[NSDate class]] && [obj2 isKindOfClass:[NSDate class]]) {            
            return [(NSDate*)obj2 compare:(NSDate*)obj1];
        }
        return (NSComparisonResult)NSOrderedSame;
    }];
    for (int i = 0; i < sorted.count; i++) {
        NSDate *thisDate = (NSDate *)[sorted objectAtIndex:i];
        if ([targetDate compare:thisDate] == NSOrderedDescending) {
            return i;
        }
    }
    return [sorted count];
}

-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
{
    [self setMapType:[object objectForKey:keyPath]];
}

- (void)setMapType:(NSString *) type {

    [_mapView removeOverlays:_mapView.overlays];
    
    //set the maptype
    if ([@"Satellite" isEqual:type]) {
        _mapView.mapType = MKMapTypeSatellite;
    }
    else if ([@"Hybrid" isEqual:type]) {
        _mapView.mapType = MKMapTypeHybrid;
    }
    else if ([@"Offline" isEqual:type]) {
        _mapView.mapType = MKMapTypeStandard;
        [_mapView addOverlays:[OfflineMapUtility getPolygons]];
    }
    else {
        _mapView.mapType = MKMapTypeStandard;
    }

}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay
{
    MKPolygonView *polygonView = [[MKPolygonView alloc] initWithPolygon:overlay];
    
    if ([overlay.title isEqualToString:@"ocean"]) {
        polygonView.fillColor = [UIColor colorWithRed:127/255.0 green:153/255.0 blue:171/255.0 alpha:1];
        polygonView.strokeColor = [UIColor clearColor];
        polygonView.lineWidth = 0.0;
    }
    else {
        polygonView.fillColor = [UIColor colorWithRed:221/255.0 green:221/255.0 blue:221/255.0 alpha:1];
        polygonView.strokeColor = [UIColor clearColor];
        polygonView.lineWidth = 0.0;
    }
    return polygonView;
}

- (id)bottomLayoutGuide {
    return [[MapLayoutGuide alloc] initWithLength:55];
}

@end
