//
//  DBAccount+EnsureLogin.h
//  iMIDIPatchbay
//
//  Created by Johannes Dörr on 13.10.13.
//
//

#import <Dropbox/Dropbox.h>

typedef void (^DBAccountEnsureLoginBlockType)(BOOL loginSucceeded);
typedef void (^DBAccountWhenLoginBlockType)();

@interface DBAccount (EnsureLogin)

+ (void)ensureLogin:(DBAccountEnsureLoginBlockType)block withViewController:(UIViewController *)viewController;
+ (void)whenLogin:(DBAccountWhenLoginBlockType)block;
+ (BOOL)isLoggedIn;
+ (dispatch_queue_t)backgroundQueue;
+ (void)handleOpenUrl;

@end
