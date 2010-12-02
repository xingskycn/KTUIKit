//
//  KTSearchFieldIntegration.m
//  KTUIKit
//
//  Created by Cathy Shive on 11/2/08.
//  Copyright 2008 Cathy Shive. All rights reserved.
//

#import <InterfaceBuilderKit/InterfaceBuilderKit.h>

// Import your framework view and your inspector 
 #import <KTUIKit/KTSearchField.h>
 #import "KTLayoutManagerInspector.h"

@implementation KTSearchField ( KTSearchFieldIntegration )

- (void)ibPopulateKeyPaths:(NSMutableDictionary *)keyPaths {
    [super ibPopulateKeyPaths:keyPaths];

	// Remove the comments and replace "MyFirstProperty" and "MySecondProperty" 
	// in the following line with a list of your view's KVC-compliant properties.
    [[keyPaths objectForKey:IBAttributeKeyPaths] addObjectsFromArray:[NSArray arrayWithObjects:/* @"MyFirstProperty", @"MySecondProperty",*/ nil]];
}

- (void)ibPopulateAttributeInspectorClasses:(NSMutableArray *)classes {
    [super ibPopulateAttributeInspectorClasses:classes];
	// Replace "KTSearchFieldIntegrationInspector" with the name of your inspector class.
    [classes addObject:[KTLayoutManagerInspector class]];
}

@end
