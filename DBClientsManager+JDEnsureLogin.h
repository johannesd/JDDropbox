//
//  DBClientsManager+JDEnsureLogin.h
//
//  Created by Johannes Dörr on 13.10.13.
//
//

#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>


typedef void (^DBClientsManagerEnsureLoginBlockType)(BOOL loginSucceeded);
typedef void (^DBClientsManagerWhenLoginBlockType)();


@interface DBClientsManager (JDEnsureLogin)

+ (void)ensureLogin:(DBClientsManagerEnsureLoginBlockType)block withViewController:(UIViewController *)viewController;
+ (void)whenLogin:(DBClientsManagerWhenLoginBlockType)block;
+ (BOOL)isLoggedIn;
+ (dispatch_queue_t)backgroundQueue;
+ (void)handleOpenURL;

@end
