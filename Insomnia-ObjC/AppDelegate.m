//
//  AppDelegate.m
//  Insomnia
//
//  Created by Pat on 2015-11-28.
//  Copyright © 2015 Pat Wilson Software Design. All rights reserved.
//

#import <IOKit/pwr_mgt/IOPMLib.h>
#import <objc/runtime.h>
#import <Foundation/Foundation.h>

#import "AppDelegate.h"

// This is to work around the selector _lockScreenMenuHit
// not being visible until runtime.
@interface derivedPrincipalClass : NSBundle
- (void)_lockScreenMenuHit:(id)a;
@end

@interface AppDelegate ()

- (void)readDefaults;
- (void)updateDefaults;

@property (assign, nonatomic) IOPMAssertionID assertionID;

- (void)updateStatus;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    _screenSaverMenu = [[NSMenu alloc] initWithTitle:@""];

    [_screenSaverMenu setAutoenablesItems:NO];
    
    // This menu item has its own property so we can reference it when
    // adding or removing checkmark, i.e. showing its state
    //
    _disableEnableScreenSaverMenuItem = [[NSMenuItem alloc] initWithTitle:@"Disable ScreenSaver"
                                                                       action:@selector(performDisableEnableScreenSaver:)keyEquivalent:@""];

    [_screenSaverMenu addItem:_disableEnableScreenSaverMenuItem];

    [_screenSaverMenu addItemWithTitle:@"Preferences..." action:@selector(showPreferenceWindow:) keyEquivalent:@""];
    
    // No point in allocating memory for and initialising preferences window
    // unless and until we actually need it; as it will rarely be used.
    //
    _prefMgr = nil;

    // This lets us know when user changes anything in prefs window
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(updatePreferencesChange:)
               name:PreferenceManagerPrefsChange
             object:nil];

    [_screenSaverMenu addItem:[NSMenuItem separatorItem]];
    
    [_screenSaverMenu addItemWithTitle:@"Lock Screen" action:@selector(performLockScreen:) keyEquivalent:@""];
    
    // Prior to locking screen (from above menu item) we enable screensaver
    // if it is currently disabled. We need to restore this
    // setting after screen is unlocked.
    //
    NSNotificationCenter *sharedNc = [[NSWorkspace sharedWorkspace] notificationCenter];
    [sharedNc addObserver:self
           selector:@selector(performWakeNotificationActions:)
               name:NSWorkspaceScreensDidWakeNotification
             object:nil];
    
    [_screenSaverMenu addItem:[NSMenuItem separatorItem]];
    
    [[_screenSaverMenu addItemWithTitle:@"Quit Insomnia" action:@selector(terminate:) keyEquivalent:@""] setKeyEquivalentModifierMask:NSCommandKeyMask];
    
    
    // Change image in menubar to indicate current state of _bScreenSaverIsAdminDisabled
    _disabledImage = [NSImage imageNamed:@"InsomniaIcon20.png"];
    _enabledImage = [NSImage imageNamed:@"InsomniaXIcon20.png"];
    
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    _statusItem.highlightMode = YES;
    [_statusItem setMenu:_screenSaverMenu];
    
    [self readDefaults];
    
    _bScreenSaverIsAdminDisabled = !!_bDefaultDisableScreensaver;
    _bScreenSaverIsOperDisabled = NO;

    [self disableEnableScreenSaver:_bScreenSaverIsAdminDisabled];

    [self updateStatus];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {

    // enable screensaver before we go...
    [self disableEnableScreenSaver:NO];
}

- (void)performDisableEnableScreenSaver:(id) sender
{
    _bScreenSaverIsAdminDisabled = !_bScreenSaverIsAdminDisabled;

    [self disableEnableScreenSaver:_bScreenSaverIsAdminDisabled];
    
    [self updateStatus];
}

- (void)disableEnableScreenSaver:(BOOL) bDisable
{
    IOReturn success = kIOReturnSuccess;
    
    if (bDisable == _bScreenSaverIsOperDisabled) {
        // nothing to do
        return;
    }

    if (bDisable) {
        CFStringRef reasonForActivity = CFSTR("Prevent Screensaver running");
        success = IOPMAssertionCreateWithName(kIOPMAssertionTypeNoDisplaySleep,
                                                       kIOPMAssertionLevelOn,
                                                       reasonForActivity,
                                                       &_assertionID);
    } else {
        success = IOPMAssertionRelease(_assertionID);
    }

    if (success == kIOReturnSuccess) {
        _bScreenSaverIsOperDisabled = bDisable;

    } else {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        if (bDisable) {
            [alert setMessageText:@"Unable to disable ScreenSaver"];
        } else {
            [alert setMessageText:@"Unable to enable ScreenSaver"];
        }
        [alert setAlertStyle:NSCriticalAlertStyle];
        [alert runModal];
        [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:0.0];
    }
}

- (void)performLockScreen:(id) sender
{
    // Do whatever Keychain Access's Lock Screen menu item does.
    NSBundle *bundle = [NSBundle bundleWithPath:@"/Applications/Utilities/Keychain Access.app/Contents/Resources/Keychain.menu"];
    
    Class derivedPrincipalClass = [bundle principalClass];
    
    id instance = [[derivedPrincipalClass alloc] init];
    
    if (_bScreenSaverIsOperDisabled) {
        // Need to enable screensaver before locking screen.
        // We will restore state when screen is unlocked.
        //
        [self disableEnableScreenSaver:NO];
    }
    
    [instance _lockScreenMenuHit:nil];
}

- (void)performWakeNotificationActions:(NSNotification *)note
{
    if (_bScreenSaverIsOperDisabled != _bScreenSaverIsAdminDisabled) {
        // Restore state when screen is unlocked.
        //
        [self disableEnableScreenSaver:_bScreenSaverIsAdminDisabled];
        _bScreenSaverIsOperDisabled = _bScreenSaverIsAdminDisabled;
    }
}

- (void)updateStatus
{
    if (_bScreenSaverIsAdminDisabled) {
        _statusItem.image =_disabledImage;
        _statusItem.alternateImage = _disabledImage;
        [_disableEnableScreenSaverMenuItem setState:NSOnState];
        if (_bShowToolTips) {
            _statusItem.toolTip = @"Screensaver is disabled";
        }
    } else {
        _statusItem.image = _enabledImage;
        _statusItem.alternateImage = _enabledImage;
        [_disableEnableScreenSaverMenuItem setState:NSOffState];
        if (_bShowToolTips) {
            _statusItem.toolTip = @"Screensaver is enabled";
        }
    }
}

- (void)readDefaults {
    // Retrieve initial (default) value of _bScreenSaverIsAdminDisabled.
    // We check if defaults were previously saved or if this is brand spanking new.
    //
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    const NSInteger defaultsMagicNumber = 0xc0ffee;
    NSInteger magicNumberCheck = [defaults integerForKey:@"MagicNumber"];
    if (magicNumberCheck != defaultsMagicNumber) {
        // No defaults, so we'll write them now
        [defaults setInteger:defaultsMagicNumber forKey:@"MagicNumber"];
        
        _bDefaultDisableScreensaver = YES;
        [defaults setBool:_bDefaultDisableScreensaver forKey:@"DisableScreensaver"];
        
        // other prefs which aren't in Preferences window
        _bShowToolTips = YES;
        [defaults setBool:_bShowToolTips forKey:@"ShowToolTips"];

        [defaults synchronize];
        
    } else {
        _bDefaultDisableScreensaver = [defaults boolForKey:@"DisableScreensaver"];
        _bShowToolTips = [defaults boolForKey:@"ShowToolTips"];
    }
}

- (void)updateDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // only update changes
    if ([defaults boolForKey:@"DisableScreensaver"] != _bDefaultDisableScreensaver) {
        [defaults setBool:_bDefaultDisableScreensaver forKey:@"DisableScreensaver"];
        [defaults synchronize];
    }
}

- (IBAction)showPreferenceWindow:(id)sender {
    if (_prefMgr == nil) {
        _prefMgr = [[PreferenceManager alloc] init];
        NSLog(@"alloc prefWindow");
    }
    
    [_prefMgr setBDefaultDisableScreensaver:_bDefaultDisableScreensaver];
    
    [_prefMgr showWindow:self];

    // kludgy way to force prefs window to front. Needed because
    // this is a menubar app. We temporarily bump up the level,
    // but set it back again when we've done what we need to.
    //
    NSInteger currLevel = [[_prefMgr window] level];
    [[_prefMgr window] setLevel:NSStatusWindowLevel+1];
    [[_prefMgr window] setLevel:currLevel];
    [[_prefMgr window] makeMainWindow];
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

- (void)updatePreferencesChange:(id)sender {
    if ([_prefMgr bDefaultDisableScreensaver] != _bDefaultDisableScreensaver) {
        _bDefaultDisableScreensaver = [_prefMgr bDefaultDisableScreensaver];
        [self updateDefaults];
    }
}

@end
