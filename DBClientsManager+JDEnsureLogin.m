//
//  DBClientsManager+JDEnsureLogin.m
//
//  Created by Johannes Dörr on 13.10.13.
//
//

#import "DBClientsManager+JDEnsureLogin.h"


static NSMutableArray *blocksToPerformAfterLogin;
static NSMutableArray *blocksToPerformWhenLogin;
static BOOL performingLogin;
static dispatch_queue_t clockQueue;


@implementation DBClientsManager (JDEnsureLogin)

+ (void)ensureLogin:(DBClientsManagerEnsureLoginBlockType)block withViewController:(UIViewController *)viewController
{
    if ([self isLoggedIn]) {
        block(TRUE);
    }
    else {
        if (blocksToPerformAfterLogin == nil) {
            blocksToPerformAfterLogin = [NSMutableArray array];
        }
        if (!performingLogin) {
            [DBClientsManager authorizeFromController:[UIApplication sharedApplication]
                                           controller:viewController
                                              openURL:^(NSURL *url) {
                                                  [[UIApplication sharedApplication] openURL:url];
                                              }];
            performingLogin = TRUE;
        }
        [blocksToPerformAfterLogin addObject:block];
    }
}

+ (void)whenLogin:(DBClientsManagerWhenLoginBlockType)block
{
    if ([self isLoggedIn]) {
        block(TRUE);
    }
    else {
        if (blocksToPerformWhenLogin == nil) {
            blocksToPerformWhenLogin = [NSMutableArray array];
        }
        [blocksToPerformWhenLogin addObject:block];
    }
}

+ (BOOL)isLoggedIn
{
    BOOL loggedIn = [DBClientsManager authorizedClient] != nil;
//    NSLog(@"logged in? %@", loggedIn ? @"YES" : @"NO");
    return loggedIn;
}

+ (dispatch_queue_t)backgroundQueue
{
    if (clockQueue == nil) {
        clockQueue = dispatch_queue_create("Dropbox Sync Queue", NULL);
    }
    return clockQueue;
}

+ (void)handleOpenURL
{
    if ([self isLoggedIn]) {
        NSLog(@"App linked successfully! Now wait for first sync to finish");
        for (DBClientsManagerEnsureLoginBlockType block in blocksToPerformAfterLogin) {
            block(TRUE);
        }
        for (DBClientsManagerWhenLoginBlockType block in blocksToPerformWhenLogin) {
            block();
        }
        blocksToPerformAfterLogin = nil;
        blocksToPerformWhenLogin = nil;
        performingLogin = FALSE;
    }
    else {
        for (DBClientsManagerEnsureLoginBlockType block in blocksToPerformAfterLogin) {
            block(FALSE);
        }
        blocksToPerformAfterLogin = nil;
        performingLogin = FALSE;
    }
}

@end
