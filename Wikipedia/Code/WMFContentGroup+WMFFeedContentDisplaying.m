#import "WMFContentGroup+WMFFeedContentDisplaying.h"
#import "NSDate+Utilities.h"

NS_ASSUME_NONNULL_BEGIN

@implementation WMFContentGroup (WMFContentManaging)

- (UIImage *)headerIcon {
    return [[UIImage alloc] init];
}

- (UIColor *)headerIconTintColor {
    return [UIColor wmf_exploreSectionHeaderIconTintColor];
}

- (UIColor *)headerIconBackgroundColor {
    return [UIColor wmf_exploreSectionHeaderIconBackgroundColor];
}

- (NSAttributedString *)headerTitle {
    return [[NSAttributedString alloc] init];
}

- (NSAttributedString *)headerSubTitle {
    return [[NSAttributedString alloc] init];
}

- (nullable NSURL *)headerContentURL {
    return nil;
}

- (WMFFeedHeaderActionType)headerActionType {
    return WMFFeedHeaderActionTypeOpenFirstItem;
}

- (WMFFeedBlacklistOption)blackListOptions {
    return WMFFeedBlacklistOptionNone;
}

- (WMFFeedDisplayType)displayType {
    return WMFFeedDisplayTypePage;
}

- (NSUInteger)maxNumberOfCells {
    return 1;
}

- (BOOL)prefersWiderColumn {
    return NO;
}

- (WMFFeedDetailType)detailType {
    return WMFFeedDetailTypePage;
}

- (nullable NSString *)footerText {
    return nil;
}

- (WMFFeedMoreType)moreType {
    return WMFFeedMoreTypeNone;
}

- (nullable NSString *)moreTitle {
    return nil;
}

- (NSString *)analyticsContentType {
    return @"Unknown Content Type";
}

@end

@implementation WMFContinueReadingContentGroup (WMFContentManaging)

- (UIImage *)headerIcon {
    return [UIImage imageNamed:@"home-continue-reading-mini"];
}

- (NSAttributedString *)headerTitle {
    return [[NSAttributedString alloc] initWithString:MWLocalizedString(@"explore-continue-reading-heading", nil) attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderTitleColor]}];
}

- (NSAttributedString *)headerSubTitle {
    NSString *relativeTimeString = [self.date wmf_relativeTimestamp];
    return [[NSAttributedString alloc] initWithString:[relativeTimeString wmf_stringByCapitalizingFirstCharacter] attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderSubTitleColor]}];
}

- (NSString *)analyticsContentType {
    return @"Continue Reading";
}

@end

@implementation WMFMainPageContentGroup (WMFContentManaging)

- (UIImage *)headerIcon {
    return [UIImage imageNamed:@"news-mini"];
}

- (NSAttributedString *)headerTitle {
    return [[NSAttributedString alloc] initWithString:MWLocalizedString(@"explore-main-page-heading", nil) attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderTitleColor]}];
}

- (NSAttributedString *)headerSubTitle {
    return [[NSAttributedString alloc] initWithString:[[NSDateFormatter wmf_dayNameMonthNameDayOfMonthNumberDateFormatter] stringFromDate:[NSDate date]] attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderSubTitleColor]}];
}

- (NSString *)analyticsContentType {
    return @"Main Page";
}

@end

@implementation WMFRelatedPagesContentGroup (WMFContentManaging)

- (UIImage *)headerIcon {
    return [UIImage imageNamed:@"recent-mini"];
}

- (NSAttributedString *)headerTitle {
    return [[NSAttributedString alloc] initWithString:MWLocalizedString(@"explore-continue-related-heading", nil) attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderTitleColor]}];
}

- (NSAttributedString *)headerSubTitle {
    return [[NSAttributedString alloc] initWithString:self.articleURL.wmf_title attributes:@{NSForegroundColorAttributeName: [UIColor wmf_blueTintColor]}];
}

- (nullable NSURL *)headerContentURL {
    return self.articleURL;
}

- (WMFFeedHeaderActionType)headerActionType {
    return WMFFeedHeaderActionTypeOpenHeaderContent;
}

- (WMFFeedBlacklistOption)blackListOptions {
    return WMFFeedBlacklistOptionContent;
}

- (WMFFeedDisplayType)displayType {
    return WMFFeedDisplayTypePageWithPreview;
}

- (BOOL)prefersWiderColumn {
    return YES /*FBTweakValue(@"Explore", @"General", @"Put 'Because You Read' in Wider Column", YES)*/;
}

- (NSUInteger)maxNumberOfCells {
    return 3;
}

- (nullable NSString *)footerText {
    return
        [MWLocalizedString(@"home-more-like-footer", nil) stringByReplacingOccurrencesOfString:@"$1"
                                                                                    withString:self.articleURL.wmf_title];
}

- (WMFFeedMoreType)moreType {
    return WMFFeedMoreTypePageList;
}

- (nullable NSString *)moreTitle {
    return [MWLocalizedString(@"home-more-like-footer", nil) stringByReplacingOccurrencesOfString:@"$1" withString:self.articleURL.wmf_title];
}

- (NSString *)analyticsContentType {
    return @"Recommended";
}

@end

@implementation WMFLocationContentGroup (WMFContentManaging)

- (UIImage *)headerIcon {
    return [UIImage imageNamed:@"nearby-mini"];
}

- (NSAttributedString *)headerTitle {
    return [[NSAttributedString alloc] initWithString:MWLocalizedString(@"explore-nearby-heading", nil) attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderTitleColor]}];
}

- (NSAttributedString *)headerSubTitle {
    if ([self.date isToday]) {
        return [[NSAttributedString alloc] initWithString:MWLocalizedString(@"explore-nearby-sub-heading-your-location", nil) attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderSubTitleColor]}];
    } else if (self.placemark) {
        return [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@, %@", self.placemark.name, self.placemark.locality] attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderSubTitleColor]}];
    } else {
        return [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%f, %f", self.location.coordinate.latitude, self.location.coordinate.longitude] attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderSubTitleColor]}];
    }
}

- (WMFFeedHeaderActionType)headerActionType {
    return WMFFeedHeaderActionTypeOpenMore;
}

- (WMFFeedDisplayType)displayType {
    return WMFFeedDisplayTypePageWithLocation;
}

- (NSUInteger)maxNumberOfCells {
    return 3;
}

- (nullable NSString *)footerText {
    if ([self.date isToday]) {
        return MWLocalizedString(@"home-nearby-footer", nil);
    } else {
        return [MWLocalizedString(@"home-nearby-location-footer", nil) stringByReplacingOccurrencesOfString:@"$1" withString:self.placemark.name];
    }
}

- (WMFFeedMoreType)moreType {
    return WMFFeedMoreTypePageListWithLocation;
}

- (nullable NSString *)moreTitle {
    return MWLocalizedString(@"main-menu-nearby", nil);
}

- (NSString *)analyticsContentType {
    return @"Nearby";
}

@end

@implementation WMFPictureOfTheDayContentGroup (WMFContentManaging)

- (UIImage *)headerIcon {
    return [UIImage imageNamed:@"potd-mini"];
}

- (NSAttributedString *)headerTitle {
    return [[NSAttributedString alloc] initWithString:MWLocalizedString(@"explore-potd-heading", nil) attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderTitleColor]}];
}

- (NSAttributedString *)headerSubTitle {
    return [[NSAttributedString alloc] initWithString:[[NSDateFormatter wmf_dayNameMonthNameDayOfMonthNumberDateFormatter] stringFromDate:self.date] attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderSubTitleColor]}];
}

- (WMFFeedDisplayType)displayType {
    return WMFFeedDisplayTypePhoto;
}

- (WMFFeedDetailType)detailType {
    return WMFFeedDetailTypeGallery;
}

- (NSString *)analyticsContentType {
    return @"Picture of the Day";
}

@end

@implementation WMFRandomContentGroup (WMFContentManaging)

- (UIImage *)headerIcon {
    return [UIImage imageNamed:@"random-mini"];
}

- (NSAttributedString *)headerTitle {
    return [[NSAttributedString alloc] initWithString:MWLocalizedString(@"explore-random-article-heading", nil) attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderTitleColor]}];
}

- (NSAttributedString *)headerSubTitle {
    return [[NSAttributedString alloc] initWithString:MWSiteLocalizedString(self.siteURL, @"onboarding-wikipedia", nil) attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderSubTitleColor]}];
}

- (WMFFeedDisplayType)displayType {
    return WMFFeedDisplayTypePageWithPreview;
}

- (nullable NSString *)footerText {
    return MWLocalizedString(@"explore-another-random", nil);
}

- (WMFFeedDetailType)detailType {
    return WMFFeedDetailTypePageWithRandomButton;
}

- (WMFFeedMoreType)moreType {
    return WMFFeedMoreTypePageWithRandomButton;
}

- (NSString *)analyticsContentType {
    return @"Random";
}

@end

@implementation WMFFeaturedArticleContentGroup (WMFContentManaging)
- (UIImage *)headerIcon {
    return [UIImage imageNamed:@"featured-mini"];
}

- (UIColor *)headerIconTintColor {
    return [UIColor wmf_colorWithHex:0xE6B84F alpha:1.0];
}

- (UIColor *)headerIconBackgroundColor {
    return [UIColor wmf_colorWithHex:0xFCF5E4 alpha:1.0];
}

- (NSAttributedString *)headerTitle {
    return [[NSAttributedString alloc] initWithString:MWLocalizedString(@"explore-featured-article-heading", nil) attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderTitleColor]}];
}

- (NSAttributedString *)headerSubTitle {
    return [[NSAttributedString alloc] initWithString:[[NSDateFormatter wmf_dayNameMonthNameDayOfMonthNumberDateFormatter] stringFromDate:self.date] attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderSubTitleColor]}];
}

- (WMFFeedDisplayType)displayType {
    return WMFFeedDisplayTypePageWithPreview;
}

@end

@implementation WMFTopReadContentGroup (WMFContentManaging)

- (UIImage *)headerIcon {
    return [UIImage imageNamed:@"trending-mini"];
}

- (NSAttributedString *)headerTitle {
    // fall back to language code if it can't be localized
    NSString *language = [[NSLocale currentLocale] wmf_localizedLanguageNameForCode:self.siteURL.wmf_language];

    NSString *heading = nil;

    //crash protection if language is nil
    if (language) {
        heading =
            [MWLocalizedString(@"explore-most-read-heading", nil) stringByReplacingOccurrencesOfString:@"$1"
                                                                                            withString:language];
    } else {
        heading = MWLocalizedString(@"explore-most-read-generic-heading", nil);
    }

    NSDictionary *attributes = @{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderTitleColor]};
    return [[NSAttributedString alloc] initWithString:heading attributes:attributes];
}

- (NSAttributedString *)headerSubTitle {
    return [[NSAttributedString alloc]
        initWithString:[self localDateDisplayString]
            attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderTitleColor]}];
}

- (UIColor *)headerIconTintColor {
    return [UIColor wmf_blueTintColor];
}

- (UIColor *)headerIconBackgroundColor {
    return [UIColor wmf_lightBlueTintColor];
}

- (WMFFeedHeaderActionType)headerActionType {
    return WMFFeedHeaderActionTypeOpenMore;
}

- (NSUInteger)maxNumberOfCells {
    return 5;
}

- (nullable NSString *)footerText {
    return
        [MWLocalizedString(@"explore-most-read-footer-for-date", nil) stringByReplacingOccurrencesOfString:@"$1"
                                                                                                withString:[self localDateShortDisplayString]];
}

- (WMFFeedMoreType)moreType {
    return WMFFeedMoreTypePageList;
}

- (nullable NSString *)moreTitle {
    return [self titleForDate:self.mostReadDate];
}

- (NSString *)analyticsContentType {
    return @"Most Read";
}

/**
 *  String to display to the user for the receiver's date.
 *
 *  "Most read" articles are computed for UTC dates. UTC time zone is used because converting to the user's time zone
 *  might accidentally change the "day" the app displays based on the the offset between UTC & the device's default time
 *  zone.  For example: 02/12/2016 01:26 UTC converted to EST is 02/11/2016 20:26, one day off!
 *
 *  @return A string formatted with the current locale, in the UTC time zone.
 */
- (NSString *)localDateDisplayString {
    return [[NSDateFormatter wmf_utcDayNameMonthNameDayOfMonthNumberDateFormatter] stringFromDate:self.mostReadDate];
}

- (NSString *)localDateShortDisplayString {
    return [[NSDateFormatter wmf_utcShortDayNameShortMonthNameDayOfMonthNumberDateFormatter] stringFromDate:self.mostReadDate];
}

- (NSString *)titleForDate:(NSDate *)date {
    return
        [MWLocalizedString(@"explore-most-read-more-list-title-for-date", nil) stringByReplacingOccurrencesOfString:@"$1"
                                                                                                         withString:
                                                                                                             [[NSDateFormatter wmf_utcShortDayNameShortMonthNameDayOfMonthNumberDateFormatter] stringFromDate:date]];
}

@end

NS_ASSUME_NONNULL_END
