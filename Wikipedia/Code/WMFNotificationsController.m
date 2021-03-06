#import "WMFNotificationsController.h"
#import "WMFFaceDetectionCache.h"
#import <WMFModel/WMFModel-Swift.h>
@import ImageIO;
@import UserNotifications;
@import WMFUtilities;

#define WMF_ALWAYS_ASK_FOR_NOTIFICATION_PERMISSION DEBUG && 0

NSString *const WMFInTheNewsNotificationCategoryIdentifier = @"inTheNewsNotificationCategoryIdentifier";
NSString *const WMFInTheNewsNotificationReadNowActionIdentifier = @"inTheNewsNotificationReadNowActionIdentifier";
NSString *const WMFInTheNewsNotificationSaveForLaterActionIdentifier = @"inTheNewsNotificationSaveForLaterActionIdentifier";
NSString *const WMFInTheNewsNotificationShareActionIdentifier = @"inTheNewsNotificationShareActionIdentifier";

uint64_t const WMFNotificationUpdateInterval = 10;

NSString *const WMFNotificationInfoArticleTitleKey = @"articleTitle";
NSString *const WMFNotificationInfoArticleURLStringKey = @"articleURLString";
NSString *const WMFNotificationInfoThumbnailURLStringKey = @"thumbnailURLString";
NSString *const WMFNotificationInfoArticleExtractKey = @"articleExtract";
NSString *const WMFNotificationInfoStoryHTMLKey = @"storyHTML";
NSString *const WMFNotificationInfoViewCountsKey = @"viewCounts";

//const CGFloat WMFNotificationImageCropNormalizedMinDimension = 1; //for some reason, cropping isn't respected if a full dimension (1) is indicated

@interface WMFNotificationsController ()

@property (nonatomic, readwrite, getter=isAuthorized) BOOL authorized;

@end

@implementation WMFNotificationsController

- (instancetype)init {
    self = [super init];
    if (self) {
#if WMF_ALWAYS_ASK_FOR_NOTIFICATION_PERMISSION
        [self requestAuthenticationIfNecessaryWithCompletionHandler:^(BOOL granted, NSError *_Nullable error){

        }];
#endif
    }
    return self;
}

- (void)requestAuthenticationIfNecessaryWithCompletionHandler:(void (^)(BOOL granted, NSError *__nullable error))completionHandler {
    if (![UNUserNotificationCenter class]) {
        completionHandler(NO, nil);
        return;
    }
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *_Nonnull settings) {
        switch (settings.authorizationStatus) {
            case UNAuthorizationStatusAuthorized:
                self.authorized = YES;
                completionHandler(YES, nil);
                break;
            case UNAuthorizationStatusDenied:
                self.authorized = NO;
                completionHandler(NO, nil);
                break;
            case UNAuthorizationStatusNotDetermined:
                [self requestAuthenticationWithCompletionHandler:completionHandler];
                break;
            default:
                break;
        }
    }];
}

- (void)requestAuthenticationWithCompletionHandler:(void (^)(BOOL, NSError *_Nullable))completionHandler {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    UNNotificationAction *readNowAction = [UNNotificationAction actionWithIdentifier:WMFInTheNewsNotificationReadNowActionIdentifier title:MWLocalizedString(@"in-the-news-notification-read-now-action-title", nil) options:UNNotificationActionOptionForeground];
    UNNotificationAction *saveForLaterAction = [UNNotificationAction actionWithIdentifier:WMFInTheNewsNotificationShareActionIdentifier title:MWLocalizedString(@"in-the-news-notification-share-action-title", nil) options:UNNotificationActionOptionForeground];
    UNNotificationAction *shareAction = [UNNotificationAction actionWithIdentifier:WMFInTheNewsNotificationSaveForLaterActionIdentifier title:MWLocalizedString(@"in-the-news-notification-save-for-later-action-title", nil) options:UNNotificationActionOptionForeground];

    if (!readNowAction || !saveForLaterAction || !shareAction) {
        self.authorized = NO;
        completionHandler(false, nil);
        return;
    }

    UNNotificationCategory *inTheNewsCategory = [UNNotificationCategory categoryWithIdentifier:WMFInTheNewsNotificationCategoryIdentifier actions:@[readNowAction, saveForLaterAction, shareAction] intentIdentifiers:@[] options:UNNotificationCategoryOptionNone];

    if (!inTheNewsCategory) {
        self.authorized = NO;
        completionHandler(false, nil);
        return;
    }

    [center setNotificationCategories:[NSSet setWithObject:inTheNewsCategory]];
    [center requestAuthorizationWithOptions:UNAuthorizationOptionAlert | UNAuthorizationOptionSound
                          completionHandler:^(BOOL granted, NSError *_Nullable error) {
                              self.authorized = granted;
                              completionHandler(granted, error);
                          }];
}

- (NSString *)sendNotificationWithTitle:(NSString *)title body:(NSString *)body categoryIdentifier:(NSString *)categoryIdentifier userInfo:(NSDictionary *)userInfo atDateComponents:(nullable NSDateComponents *)dateComponents withAttachements:(nullable NSArray<UNNotificationAttachment *> *)attachements {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = title;
    content.body = body;
    content.categoryIdentifier = categoryIdentifier;
    content.attachments = attachements;
    content.userInfo = userInfo;
    UNNotificationTrigger *trigger = nil;
    if (dateComponents) {
        trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:dateComponents repeats:NO];
    } else {
        trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1 repeats:NO];
    }
    NSString *identifier = [[NSUUID UUID] UUIDString];
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];
    [center addNotificationRequest:request
             withCompletionHandler:^(NSError *_Nullable error) {
                 if (error) {
                     DDLogError(@"Error adding notification request: %@", error);
                 }
             }];
    return identifier;
}

- (void)sendNotificationWithTitle:(NSString *)title body:(NSString *)body categoryIdentifier:(NSString *)categoryIdentifier userInfo:(NSDictionary *)userInfo atDateComponents:(nullable NSDateComponents *)dateComponents {
    if (![UNUserNotificationCenter class]) {
        return;
    }

    NSString *thumbnailURLString = userInfo[WMFNotificationInfoThumbnailURLStringKey];
    if (!thumbnailURLString) {
        [self sendNotificationWithTitle:title body:body categoryIdentifier:categoryIdentifier userInfo:userInfo atDateComponents:dateComponents withAttachements:nil];
        return;
    }

    NSURL *thumbnailURL = [NSURL URLWithString:thumbnailURLString];
    if (!thumbnailURL) {
        [self sendNotificationWithTitle:title body:body categoryIdentifier:categoryIdentifier userInfo:userInfo atDateComponents:dateComponents withAttachements:nil];
        return;
    }

    NSString *typeHint = nil;
    NSString *pathExtension = thumbnailURL.pathExtension.lowercaseString;
    if ([pathExtension isEqualToString:@"jpg"] || [pathExtension isEqualToString:@"jpeg"]) {
        typeHint = (NSString *)kUTTypeJPEG;
    }

    if (!typeHint) {
        [self sendNotificationWithTitle:title body:body categoryIdentifier:categoryIdentifier userInfo:userInfo atDateComponents:dateComponents withAttachements:nil];
        return;
    }

    WMFImageController *imageController = [WMFImageController sharedInstance];
    [imageController cacheImageWithURLInBackground:thumbnailURL
        failure:^(NSError *_Nonnull error) {
            [self sendNotificationWithTitle:title body:body categoryIdentifier:categoryIdentifier userInfo:userInfo atDateComponents:dateComponents withAttachements:nil];
        }
        success:^(BOOL didCache) {
            NSString *cachedThumbnailPath = [imageController cachePathForImageWithURL:thumbnailURL];
            NSURL *cachedThumbnailURL = [NSURL fileURLWithPath:cachedThumbnailPath];
            UIImage *image = [UIImage imageWithContentsOfFile:cachedThumbnailPath];

            if (!cachedThumbnailURL || !image) {
                [self sendNotificationWithTitle:title body:body categoryIdentifier:categoryIdentifier userInfo:userInfo atDateComponents:dateComponents withAttachements:nil];
                return;
            }

            WMFFaceDetectionCache *faceDetectionCache = [WMFFaceDetectionCache sharedCache];
            BOOL useGPU = YES;
            UNNotificationAttachment *attachement = [UNNotificationAttachment attachmentWithIdentifier:thumbnailURLString
                                                                                                   URL:cachedThumbnailURL
                                                                                               options:@{ UNNotificationAttachmentOptionsTypeHintKey: typeHint,
                                                                                                          UNNotificationAttachmentOptionsThumbnailClippingRectKey: (__bridge_transfer NSDictionary *)CGRectCreateDictionaryRepresentation(CGRectMake(0, 0, 1, 1)) }
                                                                                                 error:nil];
            NSArray *imageAttachements = nil;
            if (attachement) {
                imageAttachements = @[attachement];
            }

            [faceDetectionCache detectFaceBoundsInImage:image
                onGPU:useGPU
                URL:thumbnailURL
                failure:^(NSError *_Nonnull error) {
                    [self sendNotificationWithTitle:title body:body categoryIdentifier:categoryIdentifier userInfo:userInfo atDateComponents:dateComponents withAttachements:imageAttachements];
                }
                success:^(NSValue *faceRectValue) {
                    if (faceRectValue) {
                        //CGFloat aspect = image.size.width / image.size.height;
                        //                                                    CGRect cropRect = CGRectMake(0, 0, 1, 1);
                        //                                                    if (faceRectValue) {
                        //                                                        CGRect faceRect = [faceRectValue CGRectValue];
                        //                                                        if (aspect < 1) {
                        //                                                            CGFloat faceMidY = CGRectGetMidY(faceRect);
                        //                                                            CGFloat normalizedHeight = WMFNotificationImageCropNormalizedMinDimension * aspect;
                        //                                                            CGFloat halfNormalizedHeight = 0.5 * normalizedHeight;
                        //                                                            CGFloat originY = MAX(0, faceMidY - halfNormalizedHeight);
                        //                                                            CGFloat normalizedWidth = MAX(faceRect.size.width, WMFNotificationImageCropNormalizedMinDimension);
                        //                                                            CGFloat originX = 0.5 * (1 - normalizedWidth);
                        //                                                            cropRect = CGRectMake(originX, originY, normalizedWidth, normalizedHeight);
                        //                                                        } else {
                        //                                                            CGFloat faceMidX = CGRectGetMidX(faceRect);
                        //                                                            CGFloat normalizedWidth = WMFNotificationImageCropNormalizedMinDimension / aspect;
                        //                                                            CGFloat halfNormalizedWidth = 0.5 * normalizedWidth;
                        //                                                            CGFloat originX = MAX(0, faceMidX - halfNormalizedWidth);
                        //                                                            CGFloat normalizedHeight = MAX(faceRect.size.height, WMFNotificationImageCropNormalizedMinDimension);
                        //                                                            CGFloat originY = 0.5 * (1 - normalizedHeight);
                        //                                                            cropRect = CGRectMake(originX, originY, normalizedWidth, normalizedHeight);
                        //                                                        }
                        //                                                    }

                        //Since face cropping is broken, don't attach images with faces
                        [self sendNotificationWithTitle:title body:body categoryIdentifier:categoryIdentifier userInfo:userInfo atDateComponents:dateComponents withAttachements:nil];
                    } else {
                        [self sendNotificationWithTitle:title body:body categoryIdentifier:categoryIdentifier userInfo:userInfo atDateComponents:dateComponents withAttachements:imageAttachements];
                    }
                }];
        }];
}

@end
