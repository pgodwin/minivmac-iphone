//
//  AppDelegate.h
//  minivmac
//
//  Created by Peter Godwin on 21/11/11.
//  Copyright Queensland Health 2011. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RootViewController;

@interface AppDelegate : NSObject <UIApplicationDelegate> {
	UIWindow			*window;
	RootViewController	*viewController;
}

@property (nonatomic, retain) UIWindow *window;

@end
