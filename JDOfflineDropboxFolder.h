//
//  JDOfflineDropboxFolder.h
//  Pods
//
//  Created by Johannes Dörr on 25.06.17.
//
//

#import <Foundation/Foundation.h>
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>
#import <Reachability.h>


extern NSString * _Nonnull const JDOfflineDropboxFolderChangedNotification;


typedef enum
{
    JDOfflineDropboxFolderSyncStatusSyncing,
    JDOfflineDropboxFolderSyncStatusIdle,
    JDOfflineDropboxFolderSyncStatusOffline
}
JDOfflineDropboxFolderSyncStatus;


typedef enum
{
    JDOfflineDropboxFolderSyncDataTypeFile,
    JDOfflineDropboxFolderSyncDataTypeMeta
}
JDOfflineDropboxFolderSyncDataType;


@interface JDOfflineDropboxFolder : NSObject

@property (nonatomic, strong, readonly) NSString * _Nonnull path;
@property (nonatomic, assign) JDOfflineDropboxFolderSyncStatus status;

- (id _Nullable)initWithPath:(NSString * _Nonnull)path;
- (NSURL * _Nonnull)URLforFilePath:(NSString * _Nonnull)path dataType:(JDOfflineDropboxFolderSyncDataType)dataType;
- (NSURL * _Nonnull)URLforFilePath:(NSString * _Nonnull)path;
- (NSArray <NSURL *> * _Nonnull)urlsForLocalFiles;
- (NSArray <NSString *> * _Nonnull)localFilePaths;

@end


@interface JDOfflineDropboxFolder ()
{
    Reachability *reachability;
    NSMutableDictionary<NSString *, DBDownloadUrlTask *> *downloadTasks;
    DBRpcTask *listFolderTask;
    NSString *listFolderCursor;
    NSMutableArray<NSString *> *obsoleteFilePaths;
}
@end
