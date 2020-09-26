//
//  JDOfflineDropboxFolder.m
//  Pods
//
//  Created by Johannes Dörr on 25.06.17.
//
//

#import "JDOfflineDropboxFolder.h"
#import <BlocksKit/NSArray+BlocksKit.h>
#import <JDCategories/NSURL+JDCategories.h>
#import "DBClientsManager+JDEnsureLogin.h"


NSString * const JDOfflineDropboxFolderChangedNotification = @"JDOfflineDropboxFolderChangedNotification";


@implementation JDOfflineDropboxFolder

- (id _Nullable)initWithPath:(nonnull NSString *)path
{
    self = [super init];
    if (self) {
        if (![path hasPrefix:@"/"]) {
            path = [@"/" stringByAppendingString:path];
        }
        if (![path hasSuffix:@"/"]) {
            path = [path stringByAppendingString:@"/"];
        }
        _path = path;
        _status = JDOfflineDropboxFolderSyncStatusOffline;
        reachability = [Reachability reachabilityForInternetConnection];
        [reachability startNotifier];
        
        downloadTasks = [NSMutableDictionary dictionary];
        
        obsoleteFilePaths = [NSMutableArray array];
        
        __weak id weakSelf = self;
        [DBClientsManager whenLogin:^{
            [self syncRestart:@TRUE];
        }];
        reachability.reachableBlock = ^(Reachability * reachability) {
            [weakSelf syncRestart:@TRUE];
        };
        reachability.unreachableBlock = ^(Reachability * reachability) {
            [weakSelf cancelSync];
        };
    }
    return self;
}

- (void)performSync
{
    [self performSelector:@selector(syncRestart:) withObject:@FALSE afterDelay:0];
}

- (void)syncRestart:(NSNumber *)restart
{
    if ([DBClientsManager isLoggedIn]) {
        DBUserClient *client = [DBClientsManager authorizedClient];
        [listFolderTask cancel];
        
        if ([restart boolValue] || listFolderCursor == nil) {
            listFolderTask = [client.filesRoutes listFolder:self.path];
        }
        else {
            listFolderTask = [client.filesRoutes listFolderContinue:listFolderCursor];
        }
        
        NSURL *localFilesFolder = [self URLforFolderDataType:JDOfflineDropboxFolderSyncDataTypeFile];
        NSURL *localMetaFolder = [self URLforFolderDataType:JDOfflineDropboxFolderSyncDataTypeMeta];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error = nil;
        [fileManager createDirectoryAtURL:localFilesFolder withIntermediateDirectories:TRUE attributes:nil error:&error];
        [fileManager createDirectoryAtURL:localMetaFolder withIntermediateDirectories:TRUE attributes:nil error:&error];
        
        if ([restart boolValue]) {
            obsoleteFilePaths = [[self localFilePaths] mutableCopy];
        }
        
        __weak JDOfflineDropboxFolder *weakSelf = self;
        __weak NSMutableDictionary<NSString *, DBDownloadUrlTask *> *weakDownloadTasks = downloadTasks;
        __weak NSMutableArray<NSString *> *weakObsoleteFilePaths = obsoleteFilePaths;
        [listFolderTask setResponseBlock:^(DBFILESListFolderResult * _Nullable result, DBFILESListFolderError * _Nullable routeError, DBRequestError * _Nullable networkError) {
             if (!routeError && !networkError) {
                 listFolderCursor = result.cursor;
                 for (DBFILESMetadata *entry in result.entries) {
                     assert([entry.pathDisplay hasPrefix:weakSelf.path]);
                     NSString *path = [entry.pathDisplay substringFromIndex:weakSelf.path.length];
                     NSURL *localFileURL = [weakSelf URLforFilePath:path dataType:JDOfflineDropboxFolderSyncDataTypeFile];
                     NSURL *localMetaURL = [weakSelf URLforFilePath:path dataType:JDOfflineDropboxFolderSyncDataTypeMeta];
                     if ([entry isKindOfClass:[DBFILESFileMetadata class]]) {
                         [weakObsoleteFilePaths removeObject:path];
                         NSDictionary *meta = [NSDictionary dictionaryWithContentsOfURL:localMetaURL];
                         if ([meta[@"hash"] isEqualToString:((DBFILESFileMetadata *)entry).contentHash]) {
                             NSLog(@"File is up to date: %@", path);
                             continue;
                         }
                         BOOL isNewFile = meta == nil;
                         DBDownloadUrlTask *downloadTask = [client.filesRoutes downloadUrl:entry.pathDisplay overwrite:TRUE destination:localFileURL];
                         NSString *taskKey = entry.pathDisplay;
                         [downloadTask setResponseBlock:^(DBFILESFileMetadata * _Nullable result, DBFILESDownloadError * _Nullable routeError, DBRequestError * _Nullable networkError, NSURL * _Nonnull destination) {
                             if (!routeError && !networkError) {
                                 if (isNewFile) {
                                     NSLog(@"Added file: %@", path);
                                 }
                                 else {
                                     NSLog(@"Updated file: %@", path);
                                 }
                                 NSDictionary *meta = @{@"hash": result.contentHash};
                                 [meta writeToURL:localMetaURL atomically:TRUE];
                                 NSDictionary *userInfo = @{@"path": path, @"absolutePath": result.pathDisplay};
                                 [[NSNotificationCenter defaultCenter] postNotificationName:JDOfflineDropboxFolderChangedNotification object:nil userInfo:userInfo];
                             }
                             else {
                                 NSLog(@"File could not be downloaded: %@", path);
                                 // Note: Currently, no notification is sent when an error occures. The SheetsView might continue showing "Downloading file" although it already has failed
                             }
                             [weakDownloadTasks removeObjectForKey:taskKey];
                             if (weakDownloadTasks.count == 0) {
                                 weakSelf.status = JDOfflineDropboxFolderSyncStatusIdle;
                             }
                             
                         }];
                         weakDownloadTasks[taskKey] = downloadTask;
                         NSLog(@"Remote file: %@", path);
                         
                         NSDictionary *userInfo = @{@"path": path, @"absolutePath": entry.pathDisplay, @"downloading": @TRUE};
                         [[NSNotificationCenter defaultCenter] postNotificationName:JDOfflineDropboxFolderChangedNotification object:nil userInfo:userInfo];
                     }
                     else if ([entry isKindOfClass:[DBFILESDeletedMetadata class]]) {
                         NSFileManager *fileManager = [NSFileManager defaultManager];
                         NSError *error = nil;
                         [fileManager removeItemAtURL:localFileURL error:&error];
                         [fileManager removeItemAtURL:localMetaURL error:&error];
                         NSLog(@"Deleted file: %@", path);
                         NSDictionary *userInfo = @{@"path": path, @"absolutePath": entry.pathDisplay, @"deleted": @TRUE};
                         [[NSNotificationCenter defaultCenter] postNotificationName:JDOfflineDropboxFolderChangedNotification object:nil userInfo:userInfo];
                     }
                 }
                 if (weakDownloadTasks.count > 0) {
                     weakSelf.status = JDOfflineDropboxFolderSyncStatusSyncing;
                 }
                 else {
                     weakSelf.status = JDOfflineDropboxFolderSyncStatusIdle;
                 }
                 
                 if ([result.hasMore boolValue]) {
                     // Continue sync:
                     [weakSelf performSync];
                 }
                 else {
                     for (NSString *path in weakObsoleteFilePaths) {
                         NSURL *localFileURL = [weakSelf URLforFilePath:path dataType:JDOfflineDropboxFolderSyncDataTypeFile];
                         NSURL *localMetaURL = [weakSelf URLforFilePath:path dataType:JDOfflineDropboxFolderSyncDataTypeMeta];
                         NSError *error = nil;
                         NSFileManager *fileManager = [NSFileManager defaultManager];
                         [fileManager removeItemAtURL:localFileURL error:&error];
                         [fileManager removeItemAtURL:localMetaURL error:&error];
                         NSLog(@"Deleted obsolete file: %@", path);
                     }
                     [weakObsoleteFilePaths removeAllObjects];
                     
                     [[client.filesRoutes listFolderLongpoll:result.cursor] setResponseBlock:^(DBFILESListFolderLongpollResult * _Nullable result, DBFILESListFolderLongpollError * _Nullable routeError, DBRequestError * _Nullable networkError) {
                         if (!routeError && !networkError) {
                             // Sync when there are changes
                             [weakSelf performSync];
                         }
                         else {
                             NSLog(@"error");
                             [weakSelf cancelAndRestartSync];
                         }
                     }];
                 }
             }
             else {
                 NSLog(@"error");
                 [weakSelf cancelAndRestartSync];
             }
         }];
    }
}

- (void)cancelSync
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(syncRestart:) object:@FALSE];
    [listFolderTask cancel];
    listFolderTask = nil;
    for (DBDownloadUrlTask *downloadTask in downloadTasks.objectEnumerator) {
        [downloadTask cancel];
    }
    [downloadTasks removeAllObjects];
    self.status = JDOfflineDropboxFolderSyncStatusOffline;
}

- (void)cancelAndRestartSync
{
    [self cancelSync];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(syncRestart:) object:@TRUE];
    if ([reachability isReachable]) {
        // If we have no connection, sync will start when connection is back
        [self performSelector:@selector(syncRestart:) withObject:@TRUE afterDelay:60];
    }
}

- (NSURL * _Nonnull)URLforFolderDataType:(JDOfflineDropboxFolderSyncDataType)dataType
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *documentsFolder = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask][0] URLByResolvingSymlinksInPath];
    NSString *folderName = dataType == JDOfflineDropboxFolderSyncDataTypeFile ? @"offline-dropbox-files" : @"offline-dropbox-meta";
    return [[documentsFolder URLByAppendingPathComponent:folderName] URLBySavelyAppendingPathComponent:self.path];
}

- (NSURL * _Nonnull)URLforFilePath:(NSString * _Nonnull)path dataType:(JDOfflineDropboxFolderSyncDataType)dataType
{
    NSURL *folder = [self URLforFolderDataType:dataType];
    return [folder URLBySavelyAppendingPathComponent:path];
}

- (NSURL * _Nonnull)URLforFilePath:(NSString * _Nonnull)path
{
    return [self URLforFilePath:path dataType:JDOfflineDropboxFolderSyncDataTypeFile];
}

- (NSArray <NSURL *> *_Nonnull)urlsForLocalFiles
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *folder = [self URLforFolderDataType:JDOfflineDropboxFolderSyncDataTypeFile];
    NSError *error = nil;
    return [fileManager contentsOfDirectoryAtURL:folder includingPropertiesForKeys:nil options:0 error:&error];
}

- (NSArray <NSString *> * _Nonnull)localFilePaths
{
    return [[self urlsForLocalFiles] bk_map:^NSString *(NSURL *url) {
        return [url lastPathComponent];
    }];
}

@end
