//
//  KTViewController.m
//  View Controllers
//
//  Created by Jonathan Dann and Cathy Shive on 14/04/2008.
//
// Copyright (c) 2008 Jonathan Dann and Cathy Shive
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//
// If you use it, acknowledgement in an About Page or other appropriate place would be nice.
// For example, "Contains "View Controllers" by Jonathan Dann and Cathy Shive" will do.


/*
	(Cathy 11/10/08) NOTE:
	I've made the following changes that need to be documented:
	• When a child is removed, its view is removed from its superview and it is sent a "removeObservations" message
	• Added 'removeChild:(KTViewController*)theChild' method to remove specific subcontrollers
	• Added 'loadNibNamed' and 'releaseNibObjects' to support loading more than one nib per view controller.  These take care
	of releasing the top level nib objects for those nib files. Users have to unbind any bindings in those nibs in the view
	controller's removeObservations method.
	• Added class method, 'viewControllerWithWindowController'
	• I'm considering overriding 'view' and 'setView:' so that the view controller only deals with KTViews.
*/


#import "KTViewController.h"
#import "KTWindowController.h"
#import "KTLayerController.h"

NSString *const KTViewControllerViewControllersKey = @"viewControllers";
NSString *const KTViewControllerLayerControllersKey = @"layerControllers";

@interface KTViewController ()
@property (readwrite, nonatomic, assign, setter = _setParentViewController:) KTViewController *parentViewController;

@property (readonly, nonatomic) NSMutableArray *primitiveViewControllers;
@property (readonly, nonatomic) NSMutableArray *primitiveLayerControllers;

@property (readwrite, nonatomic, copy) NSArray *topLevelObjects;

@property (nonatomic, getter = isViewLoaded) BOOL viewLoaded;

- (void)_setHidden:(BOOL)theHiddenFlag patchResponderChain:(BOOL)thePatchFlag;
@end

@implementation KTViewController

@synthesize windowController = wWindowController;
@synthesize parentViewController = wParentViewController;

@synthesize hidden = mHidden;

@synthesize topLevelObjects = mTopLevelNibObjects;

@synthesize viewLoaded = mViewLoaded;

+ (id)viewControllerWithWindowController:(KTWindowController *)theWindowController
{
	return [[[self alloc] initWithNibName:[self nibName] bundle:[self nibBundle] windowController:theWindowController] autorelease];
}

- (id)initWithNibName:(NSString *)theNibName bundle:(NSBundle *)theBundle windowController:(KTWindowController *)theWindowController;
{
	if ((self = [super initWithNibName:theNibName bundle:theBundle])) {
		wWindowController = theWindowController;
	}
	return self;
}

- (id)initWithNibName:(NSString *)theName bundle:(NSBundle *)theBundle;
{
	[NSException raise:@"KTViewControllerException" format:@"An instance of an KTViewController concrete subclass was initialized using the NSViewController method -initWithNibName:bundle: all view controllers in the enusing tree will have no reference to an KTWindowController object and cannot be automatically added to the responder chain"];
	return nil;
}

// On 10.6 NSObject implements -awakeFromNib. It's a very common mistake to call super when compiling for 10.5+, we implement -awakeFromNib here so subclasses can safely call super.
- (void)awakeFromNib;
{}

- (void)dealloc;
{
	[mPrimitiveViewControllers release];
	[mPrimitiveLayerControllers release];

	[mTopLevelNibObjects release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Accessors

// -hidden is deprecated in favour of -isHidden
- (BOOL)hidden;
{
	return [self isHidden];
}

- (NSString *)description;
{
	return [NSString stringWithFormat:@"%@ hidden:%@ viewLoaded:%@", [super description], [self isHidden] ? @"YES" : @"NO", [self isViewLoaded] ? @"YES" : @"NO"];
}

- (void)setWindowController:(KTWindowController *)theWindowController;
{
	if (wWindowController == theWindowController) return;
	wWindowController = theWindowController;
	[[self subcontrollers] makeObjectsPerformSelector:@selector(setWindowController:) withObject:theWindowController];
	[theWindowController _patchResponderChain];
}

- (void)setHidden:(BOOL)theHidden;
{
	[self _setHidden:theHidden patchResponderChain:YES];
}

- (void)_setHidden:(BOOL)theHidden patchResponderChain:(BOOL)thePatch;
{
	if (mHidden == theHidden) return;
	mHidden = theHidden;	
	
	for (KTViewController *aViewController in [self subcontrollers]) {
		[aViewController _setHidden:theHidden patchResponderChain:NO];
	}
	
	for (KTLayerController *aLayerController in [self layerControllers]) {
		[aLayerController _setHidden:theHidden patchResponderChain:NO];
	}
	
	if (thePatch) {
		[[self windowController] _patchResponderChain];			
	}
}

#pragma mark -
#pragma mark View Loading

+ (Class)viewClass;
{
	return [NSView class]; // Note that out of the box, KTViewController should work correctly with NSViews, not KTViews.
}

+ (NSString *)nibName;
{
	return nil;
}

+ (NSBundle *)nibBundle;
{
	return [NSBundle bundleForClass:self];
}

- (BOOL)_shouldLoadDefaultView;
{
	return ([[self class] nibName] == nil && [self nibName] == nil);
}

- (void)loadView;
{		
	NSParameterAssert([self isViewLoaded] == NO);
	[self viewWillLoad];
	
	if ([self _shouldLoadDefaultView]) {
		Class aDefaultViewClass = [[self class] viewClass];
		NSParameterAssert(aDefaultViewClass != Nil);
		NSView *aView = [[[aDefaultViewClass alloc] initWithFrame:NSZeroRect] autorelease];
		[self setView:aView];
	} else {
		[super loadView];
	}
	
	[self setViewLoaded:YES];
	NSAutoreleasePool *aPool = [[NSAutoreleasePool alloc] init];
	[self viewDidLoad];
	[aPool drain];
}

- (void)viewWillLoad;
{
	// Intetionally does nothing.
}

- (void)viewDidLoad;
{
	// Intetionally does nothing.
}

#pragma mark View Controllers

- (NSMutableArray *)primitiveViewControllers;
{
	if (mPrimitiveViewControllers != nil) return mPrimitiveViewControllers;
	mPrimitiveViewControllers = [[NSMutableArray alloc] init];
	return mPrimitiveViewControllers;
}

- (NSArray *)viewControllers;
{
	return [[[self primitiveViewControllers] copy] autorelease];
}

- (NSUInteger)countOfViewControllers;
{
	return [[self primitiveViewControllers] count];
}

- (id)objectInViewControllersAtIndex:(NSUInteger)theIndex;
{
	return [[self primitiveViewControllers] objectAtIndex:theIndex];
}

// These methods are merely for mutating the |primitiveViewControllers| array. See the public |-add/removeViewController:| methods for places where connections to other view controllers are maintained and |removeObservations| is called.
- (void)insertObject:(KTViewController *)theViewController inViewControllersAtIndex:(NSUInteger)theIndex;
{
	[[self primitiveViewControllers] insertObject:theViewController atIndex:theIndex];
}

- (void)removeObjectFromViewControllersAtIndex:(NSUInteger)theIndex;
{
	[[self primitiveViewControllers] removeObjectAtIndex:theIndex];
}

#pragma mark Public View Controller API

- (void)addViewController:(KTViewController *)theViewController;
{
	if (theViewController == nil) return;
	NSParameterAssert(![[self primitiveViewControllers] containsObject:theViewController]);
	[[self mutableArrayValueForKey:KTViewControllerViewControllersKey] addObject:theViewController];
	[theViewController _setParentViewController:self];
	[[self windowController] _patchResponderChain];
}

- (void)removeViewController:(KTViewController *)theViewController;
{
	if (theViewController == nil) return;
	NSParameterAssert([[self primitiveViewControllers] containsObject:theViewController]);
	[theViewController retain];
	{
		[[self mutableArrayValueForKey:KTViewControllerViewControllersKey] removeObject:theViewController];
		[theViewController removeObservations];
		[theViewController _setParentViewController:nil];		
	}
	[theViewController release];
	[[self windowController] _patchResponderChain];
}

- (void)removeAllViewControllers;
{
	NSArray *aViewControllers = [[self primitiveViewControllers] retain];
	{
		[[self mutableArrayValueForKey:KTViewControllerViewControllersKey] removeAllObjects];
		[aViewControllers makeObjectsPerformSelector:@selector(removeObservations)];
		[aViewControllers makeObjectsPerformSelector:@selector(_setParentViewController:) withObject:nil];		
	}
	[aViewControllers release];
	[[self windowController] _patchResponderChain];
}

#pragma mark Old Subcontroller API
// TODO: These methods should be deprecated in favour of the "viewController" variants
- (NSArray *)subcontrollers;
{
	return [self viewControllers];
}

- (void)setSubcontrollers:(NSArray *)theSubcontrollers;
{
	[theSubcontrollers retain];
	{
		[self removeAllViewControllers];
		[[self mutableArrayValueForKey:KTViewControllerViewControllersKey] addObjectsFromArray:theSubcontrollers];
		[theSubcontrollers makeObjectsPerformSelector:@selector(_setParentViewController:) withObject:self];		
	}
	[theSubcontrollers release];
	[[self windowController] _patchResponderChain];
}

- (void)addSubcontroller:(KTViewController *)theViewController;
{
	[self addViewController:theViewController];
}

- (void)removeSubcontroller:(KTViewController *)theViewController;
{
	[self removeViewController:theViewController];
}

- (void)removeAllSubcontrollers
{
	[self removeAllViewControllers];
}

#pragma mark Layer Controllers

- (NSMutableArray *)primitiveLayerControllers;
{
	if (mPrimitiveLayerControllers != nil) return mPrimitiveLayerControllers;
	mPrimitiveLayerControllers = [[NSMutableArray alloc] init];
	return mPrimitiveLayerControllers;
}

- (NSArray *)layerControllers;
{
	return [[[self primitiveLayerControllers] copy] autorelease];
}

- (NSUInteger)countOfLayerControllers;
{
	return [[self primitiveLayerControllers] count];
}

- (id)objectInLayerControllersAtIndex:(NSUInteger)theIndex;
{
	return [[self primitiveLayerControllers] objectAtIndex:theIndex];
}

- (void)insertObject:(KTLayerController *)theLayerController inLayerControllersAtIndex:(NSUInteger)theIndex;
{
	[[self primitiveLayerControllers] insertObject:theLayerController atIndex:theIndex];
}

- (void)removeObjectFromLayerControllersAtIndex:(NSUInteger)theIndex;
{
	[[self primitiveLayerControllers] removeObjectAtIndex:theIndex];
}

- (void)addLayerController:(KTLayerController *)theLayerController;
{
	if (theLayerController == nil) return;
	NSParameterAssert(![[self primitiveLayerControllers] containsObject:theLayerController]);
	[[self mutableArrayValueForKey:KTViewControllerLayerControllersKey] addObject:theLayerController];
	[[self windowController] _patchResponderChain];
}

- (void)removeLayerController:(KTLayerController *)theLayerController;
{
	if (theLayerController == nil) return;
	NSParameterAssert([[self primitiveLayerControllers] containsObject:theLayerController]);
	[theLayerController retain];
	{
		[[self mutableArrayValueForKey:KTViewControllerLayerControllersKey] addObject:theLayerController];
		[theLayerController removeObservations];
	}
	[theLayerController release];
	[[self windowController] _patchResponderChain];
}

#pragma mark -
#pragma mark Descedants

static void _KTDescendantsAggregate(NSResponder <KTController> *theController, BOOL *theStopFlag, void *theContext) {
	CFMutableArrayRef aContext = (CFMutableArrayRef)theContext;
	CFArrayAppendValue(aContext, theController);
}

- (NSArray *)descendants
{
	CFMutableArrayRef aMutableDescendants = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
	[self _enumerateSubControllers:&_KTDescendantsAggregate context:aMutableDescendants];	
	CFArrayRef aDescendants = CFArrayCreateCopy(kCFAllocatorDefault, aMutableDescendants);
	CFRelease(aMutableDescendants);
	return [NSMakeCollectable(aDescendants) autorelease];
}

// As the view controllers are stored in a tree structure, if we want to stop the enumeration, we need to be able to pass the stop flag down through each invocation.
void _KTViewControllerEnumerateSubControllers(KTViewController *theViewController, _KTControllerEnumerationOptions theOptions, BOOL *theStopFlag, _KTControllerEnumeratorCallBack theCallBackFunction, void *theContext)
{
	NSCParameterAssert(theStopFlag != NULL);
	if (*theStopFlag == YES) return; // I'm not convinced this early return is necessary, but it's more defensive. The breaks in the loops should be taking care that we don't continue the recursion.
	
	theCallBackFunction(theViewController, theStopFlag, theContext);
	if (*theStopFlag == YES) return;
	
	/*
	 1) Enumerate our child view controllers
	 2) Enumerate our child layer controllers
	 // FIXME: The problem we have here is that we can enumerate (depth-first) down the whole tree of view controllers before conceptually moving back to the start (with self as the root) and doing the same for layer controllers. I wonder if, for each level we should enumerate all the child controllers, before moving down to the next level. The enumeration order is incorrect here, making layer controllers second-class citizens.
	 */
	
	BOOL aShouldIncludeHiddenControllers = ((theOptions & _KTControllerEnumerationOptionsIncludeHiddenControllers) != 0);
	
	BOOL aShouldIgnoreViewControllers = ((theOptions & _KTControllerEnumerationOptionsIgnoreViewControllers) != 0);
	if (!aShouldIgnoreViewControllers) {
		NSAutoreleasePool *aPool = [[NSAutoreleasePool alloc] init];
		for (KTViewController *aViewController in [theViewController viewControllers]) {
			if (!aShouldIncludeHiddenControllers && [aViewController isHidden]) continue;
			_KTViewControllerEnumerateSubControllers(aViewController, theOptions, theStopFlag, theCallBackFunction, theContext);
			if (*theStopFlag == YES) break;
		}
		[aPool drain];
	}
	
	if (*theStopFlag == YES) return;
	
	BOOL aShouldIgnoreLayerControllers = ((theOptions & _KTControllerEnumerationOptionsIgnoreLayerControllers) != 0);
	if (!aShouldIgnoreLayerControllers) {
		NSAutoreleasePool *aPool = [[NSAutoreleasePool alloc] init];
		for (KTLayerController *aLayerController in [theViewController layerControllers]) {
			if (!aShouldIncludeHiddenControllers && [aLayerController isHidden]) continue;
			_KTLayerControllerEnumerateSubControllers(aLayerController, theOptions, theStopFlag, theCallBackFunction, theContext);
			if (*theStopFlag == YES) break;
		}
		[aPool drain];
	}
}

- (void)_enumerateSubControllers:(_KTControllerEnumeratorCallBack)theCallBackFunction context:(void *)theContext;
{
	[self _enumerateSubControllersWithOptions:_KTControllerEnumerationOptionsNone callBack:theCallBackFunction context:theContext];
}

- (void)_enumerateSubControllersWithOptions:(_KTControllerEnumerationOptions)theOptions callBack:(_KTControllerEnumeratorCallBack)theCallBackFunction context:(void *)theContext;
{
	BOOL aStopFlag = NO;
	_KTViewControllerEnumerateSubControllers(self, theOptions, &aStopFlag, theCallBackFunction, theContext);
}

#pragma mark -
#pragma mark KVO Teardown

- (void)removeObservations
{
	[[self viewControllers] makeObjectsPerformSelector:@selector(removeObservations)];
	[[self layerControllers] makeObjectsPerformSelector:@selector(removeObservations)];
}

#pragma mark -
#pragma mark Nib Management

- (BOOL)loadNibNamed:(NSString*)theNibName bundle:(NSBundle*)theBundle
{
	NSNib *aNib = [[NSNib alloc] initWithNibNamed:theNibName bundle:theBundle];
	NSArray *aTopLevelObjects = nil;
	BOOL aSuccess = NO;
	if ((aSuccess = [aNib instantiateNibWithOwner:self topLevelObjects:&aTopLevelObjects])) {
		[self setTopLevelObjects:aTopLevelObjects];
	}
	[aNib release];
	return aSuccess;
}

#pragma mark -
#pragma mark Experimental

- (BOOL)viewHierarchyContainsView:(NSView *)theView;
{
	NSParameterAssert(theView != nil);
	if (![self isViewLoaded]) return NO;
	NSView *aView = [self view];
	return [theView isDescendantOf:aView]; // Also returns YES if [theView isEqual:aView];
}

struct __KTOwningViewControllerContext {
	NSView *view;
	NSViewController <KTController> *owningController;
};
typedef struct __KTOwningViewControllerContext _KTOwningViewControllerContext;

static void _KTOwningViewControllerCallBack(id <KTController> theController, BOOL *theStopFlag, void *theContext) {
	_KTOwningViewControllerContext *aContext = (_KTOwningViewControllerContext *)theContext;
	NSCParameterAssert([theController isKindOfClass:[KTViewController class]]);
	NSCParameterAssert([theController conformsToProtocol:@protocol(KTController)]);
	if ([theController isKindOfClass:[KTViewController class]]) {
		KTViewController <KTController> *aController = (KTViewController <KTController> *)theController;
		BOOL anIsPartOfControllersViewHierarchy = [aController viewHierarchyContainsView:(aContext->view)];
		if (anIsPartOfControllersViewHierarchy) {
			aContext->owningController = aController;			
		}
		// The trick here is not to break by setting |theStopFlag| to YES. If we did that, we may return when testing the left-branch of the controller heirarchy when the view is a subview of the right branch. We enumerate the whole view controller tree for the window, therefore the final view controller that is assigned to |theContext->owningController| is the last one which reported that it had anything to do with the view in question.
	}
}

- (NSViewController <KTController> *)owningViewControllerForView:(NSView *)theView;
{
	NSParameterAssert(theView != nil);
	if (![self viewHierarchyContainsView:theView]) return nil;
	_KTOwningViewControllerContext aContext = (_KTOwningViewControllerContext){.view = theView, .owningController = nil};
	[self _enumerateSubControllersWithOptions:(_KTControllerEnumerationOptionsIgnoreLayerControllers) callBack:&_KTOwningViewControllerCallBack context:&aContext]; // On return aContext.owningController contains the deepest view controller in the view controller tree that reported the view as its view or one of its subviews.
	return aContext.owningController;
}

@end
