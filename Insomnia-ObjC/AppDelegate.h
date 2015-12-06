//
//  AppDelegate.h
//  Insomnia
//
//  Created by Pat on 2015-11-28.
//  Copyright © 2015 Pat Wilson Software Design. All rights reserved.
//

#ifndef _APPDELEGATE_H_
#define _APPDELEGATE_H_

#import <Cocoa/Cocoa.h>

#import "PreferenceManager.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

- (IBAction)showPreferenceWindow:(id)sender;
- (void)updatePreferencesChange:(id)sender;

- (void)performDisableEnableScreenSaver:(id) sender;
- (void)disableEnableScreenSaver:(BOOL) bDisable;
- (void)performLockScreen:(id) sender;

- (void)performWakeNotificationActions:(NSNotification *)note;

@property (weak) IBOutlet NSWindow *window;
@property (strong, nonatomic) PreferenceManager* prefMgr;

@property (strong, nonatomic) NSStatusItem *statusItem;

@property (strong, nonatomic) NSMenu *screenSaverMenu;
@property (strong, nonatomic) NSMenuItem *disableEnableScreenSaverMenuItem;

@property (assign, nonatomic) BOOL bScreenSaverIsAdminDisabled;
@property (assign, nonatomic) BOOL bScreenSaverIsOperDisabled;
@property (assign, nonatomic) BOOL bDefaultDisableScreensaver;
@property (assign, nonatomic) BOOL bShowToolTips;

@property (assign, nonatomic) NSImage *disabledImage; // used when screen saver disabled
@property (assign, nonatomic) NSImage *enabledImage; // used when screen saver enabled

@end

#endif /* _APPDELEGATE_H_ */
