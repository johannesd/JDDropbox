//
//  DBAccount+EnsureLogin.m
//  iMIDIPatchbay
//
//  Created by Johannes Dörr on 13.10.13.
//
//

#import "DBAccount+EnsureLogin.h"
#import "DBFilesystem+AutoInstantiation.h"

static NSMutableArray *blocksToPerformAfterLogin;
static NSMutableArray *blocksToPerformWhenLogin;
static BOOL performingLogin;
static dispatch_queue_t clockQueue;

@implementation DBAccount (EnsureLogin)

+ (void)ensureLogin:(DBAccountEnsureLoginBlockType)block withViewController:(UIViewController *)viewController
{
    if ([self isLoggedIn]) {
        [DBFilesystem ensureSharedFilesystem];
        block(TRUE);
    }
    else {
        if (blocksToPerformAfterLogin == nil) {
            blocksToPerformAfterLogin = [NSMutableArray array];
        }
        if (!performingLogin) {
            [[DBAccountManager sharedManager] linkFromController:viewController];
            performingLogin = TRUE;
        }
        [blocksToPerformAfterLogin addObject:block];
    }
}

+ (void)whenLogin:(DBAccountWhenLoginBlockType)block
{
    if ([self isLoggedIn]) {
        [DBFilesystem ensureSharedFilesystem];
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
    BOOL loggedIn = [DBAccountManager sharedManager].linkedAccount != nil;
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

+ (void)handleOpenUrl
{
    DBAccount *account = [DBAccountManager sharedManager].linkedAccount;
    if (account) {
        [DBFilesystem ensureSharedFilesystem];
        NSLog(@"App linked successfully! Now wait for first sync to finish");
        [self completedFirstSyncChanged:nil];
    }
    else {
        for (DBAccountEnsureLoginBlockType block in blocksToPerformAfterLogin) {
            block(FALSE);
        }
        blocksToPerformAfterLogin = nil;
        performingLogin = FALSE;
    }
}

+ (void)completedFirstSyncChanged:(id)sender
{
    if (DBFilesystem.sharedFilesystem.completedFirstSync) {
        NSLog(@"First sync finished");
        for (DBAccountEnsureLoginBlockType block in blocksToPerformAfterLogin) {
            block(TRUE);
        }
        for (DBAccountWhenLoginBlockType block in blocksToPerformWhenLogin) {
            block();
        }
        blocksToPerformAfterLogin = nil;
        blocksToPerformWhenLogin = nil;
        performingLogin = FALSE;
    }
    else {
        NSLog(@"Waiting...");
        [((NSObject *)self) performSelector:@selector(completedFirstSyncChanged:) withObject:nil afterDelay:0.5];
    }
}

@end
