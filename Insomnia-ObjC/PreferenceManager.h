//
//  PreferenceManager.h
//  Insomnia
//
//  Created by Pat on 2015-12-03.
//  Copyright © 2015 Pat Wilson Software Design. All rights reserved.
//

#ifndef _PREFERENCEMANAGER_
#define _PREFERENCEMANAGER_

#import <Cocoa/Cocoa.h>

extern NSString* const PreferenceManagerPrefsChange;

@interface PreferenceManager : NSWindowController {
    
    IBOutlet NSWindow *window;
}

- (IBAction)changeDefaultDisableScreensaver:(id)sender;

@property (strong) IBOutlet NSView *view;
@property (strong) IBOutlet NSButton *checkbox;

@property (assign, nonatomic) BOOL bDefaultDisableScreensaver;

@end

#endif /* _PREFERENCEMANAGER_ */
