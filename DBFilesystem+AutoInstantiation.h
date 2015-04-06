//
//  DBFilesystem+AutoInstantiation.h
//  iMIDIPatchbay
//
//  Created by Johannes Dörr on 14.11.13.
//
//

#import <Dropbox/Dropbox.h>

@interface DBFilesystem (EnsureInstantiation)

+ (DBFilesystem *)ensureSharedFilesystem;

@end
