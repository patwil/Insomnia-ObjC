//
//  PreferenceManager.m
//  Insomnia
//
//  Created by Pat on 2015-12-03.
//  Copyright © 2015 Pat Wilson Software Design. All rights reserved.
//

#import "PreferenceManager.h"

@interface PreferenceManager ()

@end

NSString* const PreferenceManagerPrefsChange = @"PreferenceManagerPrefsChange";

@implementation PreferenceManager


- (id)init {
    self = [super initWithWindowNibName:@"PreferenceManager"];
    
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
}

- (IBAction)changeDefaultDisableScreensaver:(id)sender {
    // tell AppDelegate that something changed
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:PreferenceManagerPrefsChange object:self];
}

@end
