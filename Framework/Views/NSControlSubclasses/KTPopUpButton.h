//
//  KTPopUpButton.h
//  KTUIKit
//
//  Created by Cathy Shive on 11/2/08.
//  Copyright 2008 Cathy Shive. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KTViewLayout.h"

@class KTLayoutManager;

@interface KTPopUpButton : NSPopUpButton <KTViewLayout> 
{
	KTLayoutManager *		mLayoutManager;
}
@end
