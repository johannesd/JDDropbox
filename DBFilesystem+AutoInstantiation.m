//
//  DBFilesystem+AutoInstantiation.m
//  iMIDIPatchbay
//
//  Created by Johannes Dörr on 14.11.13.
//
//

#import "DBFilesystem+AutoInstantiation.h"

@implementation DBFilesystem (EnsureInstantiation)

+ (DBFilesystem *)ensureSharedFilesystem
{
    DBAccount *account = [DBAccountManager sharedManager].linkedAccount;
    if (account) {
        if (DBFilesystem.sharedFilesystem == nil) {
            DBFilesystem *filesystem = [[DBFilesystem alloc] initWithAccount:account];
            [DBFilesystem setSharedFilesystem:filesystem];
        }
        return DBFilesystem.sharedFilesystem;
    }
    return nil;
}

@end
