#import "CPLEngineProbe.h"
#import <dlfcn.h>
#import <objc/runtime.h>
#import <objc/message.h>

@implementation CPLEngineReport
@end

@implementation CPLEngineProbe

+ (void)ensureFrameworkLoaded {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dlopen("/System/Library/PrivateFrameworks/CloudPhotoLibrary.framework/CloudPhotoLibrary", RTLD_NOW);
    });
}

+ (id)cplStatusInstance {
    Class cplStatusClass = NSClassFromString(@"CPLStatus");
    if (!cplStatusClass) {
        return nil;
    }

    id instance = nil;
    NSArray<NSString *> *classSelectors = @[@"defaultStatus", @"sharedStatus", @"statusForDefaultStore"];
    for (NSString *selName in classSelectors) {
        SEL sel = NSSelectorFromString(selName);
        if ([cplStatusClass respondsToSelector:sel]) {
            @try {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                instance = [cplStatusClass performSelector:sel];
#pragma clang diagnostic pop
                if (instance) break;
            } @catch (NSException *e) {
                // Ignore exception and try next selector
            }
        }
    }

    if (!instance) {
        @try {
            instance = [[cplStatusClass alloc] init];
        } @catch (NSException *e) {
            instance = nil;
        }
    }

    return instance;
}

+ (CPLEngineReport *)probeStatus {
    [self ensureFrameworkLoaded];

    CPLEngineReport *report = [[CPLEngineReport alloc] init];
    report.isAvailable = NO;
    report.pendingCountEstimate = 0;
    report.hasChangesToProcess = NO;
    report.isBlockedByLowPowerMode = NO;
    report.hasThermalPressure = NO;
    report.isConnectedToNetwork = YES;

    Class cplStatusClass = NSClassFromString(@"CPLStatus");
    if (!cplStatusClass) {
        report.diagnosticLog = @"CloudPhotoLibrary private framework is not accessible.";
        return report;
    }

    report.isAvailable = YES;

    id status = [self cplStatusInstance];
    if (!status) {
        report.diagnosticLog = @"CPLStatus runtime class found, but instance could not be initialized.";
        return report;
    }

    @try {
        // Safe probe for statusDescription
        SEL descSel = NSSelectorFromString(@"statusDescription");
        if ([status respondsToSelector:descSel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            id result = [status performSelector:descSel];
#pragma clang diagnostic pop
            if ([result isKindOfClass:[NSString class]]) {
                report.statusDescription = (NSString *)result;
            }
        }

        // Safe probe for blockedReason
        SEL blockSel = NSSelectorFromString(@"blockedReason");
        if ([status respondsToSelector:blockSel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            id result = [status performSelector:blockSel];
#pragma clang diagnostic pop
            if ([result isKindOfClass:[NSString class]]) {
                report.blockedReason = (NSString *)result;
            }
        }

        // Safe probe for hasChangesToProcess (BOOL)
        SEL changesSel = NSSelectorFromString(@"hasChangesToProcess");
        if ([status respondsToSelector:changesSel]) {
            BOOL (*msgSendBool)(id, SEL) = (BOOL (*)(id, SEL))objc_msgSend;
            report.hasChangesToProcess = msgSendBool(status, changesSel);
        }

        // Safe probe for isBlockedByLowPowerMode (BOOL)
        SEL lpmSel = NSSelectorFromString(@"isBlockedByLowPowerMode");
        if ([status respondsToSelector:lpmSel]) {
            BOOL (*msgSendBool)(id, SEL) = (BOOL (*)(id, SEL))objc_msgSend;
            report.isBlockedByLowPowerMode = msgSendBool(status, lpmSel);
        }

        // Safe probe for hasThermalPressure (BOOL)
        SEL thermalSel = NSSelectorFromString(@"hasThermalPressure");
        if ([status respondsToSelector:thermalSel]) {
            BOOL (*msgSendBool)(id, SEL) = (BOOL (*)(id, SEL))objc_msgSend;
            report.hasThermalPressure = msgSendBool(status, thermalSel);
        }

        // Safe probe for isConnectedToNetwork (BOOL)
        SEL netSel = NSSelectorFromString(@"isConnectedToNetwork");
        if ([status respondsToSelector:netSel]) {
            BOOL (*msgSendBool)(id, SEL) = (BOOL (*)(id, SEL))objc_msgSend;
            report.isConnectedToNetwork = msgSendBool(status, netSel);
        }

        // Raw description for debugging
        report.rawDescription = [status description];

        // Parse pending count estimate from statusDescription if present (e.g. "Uploading 4,812 items")
        if (report.statusDescription.length > 0) {
            NSError *regexErr = nil;
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"([0-9]+(?:,[0-9]+)*)"
                                                                                   options:0
                                                                                     error:&regexErr];
            NSTextCheckingResult *match = [regex firstMatchInString:report.statusDescription
                                                            options:0
                                                              range:NSMakeRange(0, report.statusDescription.length)];
            if (match && match.range.location != NSNotFound) {
                NSString *numStr = [report.statusDescription substringWithRange:match.range];
                NSString *cleaned = [numStr stringByReplacingOccurrencesOfString:@"," withString:@""];
                report.pendingCountEstimate = [cleaned integerValue];
            }
        }

        // Format diagnostic log
        if (report.statusDescription.length > 0) {
            report.diagnosticLog = [NSString stringWithFormat:@"System CPL: %@", report.statusDescription];
        } else if (report.hasChangesToProcess) {
            report.diagnosticLog = @"CloudPhotoLibrary has local changes pending daemon processing.";
        } else {
            report.diagnosticLog = @"CloudPhotoLibrary daemon connected and reporting nominal.";
        }

    } @catch (NSException *exception) {
        report.diagnosticLog = [NSString stringWithFormat:@"Safely handled private API exception: %@", exception.reason];
    }

    return report;
}

+ (BOOL)nudgeSync {
    [self ensureFrameworkLoaded];

    id status = [self cplStatusInstance];
    if (!status) {
        return NO;
    }

    BOOL nudged = NO;
    @try {
        NSArray<NSString *> *refreshSelectors = @[@"refetchFromDisk", @"refresh"];
        for (NSString *selName in refreshSelectors) {
            SEL sel = NSSelectorFromString(selName);
            if ([status respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [status performSelector:sel];
#pragma clang diagnostic pop
                nudged = YES;
            }
        }

        NSArray<NSString *> *syncSelectors = @[@"requestSync", @"requestImmediateSync", @"resume", @"checkInitialDownloadComplete"];
        for (NSString *selName in syncSelectors) {
            SEL sel = NSSelectorFromString(selName);
            if ([status respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [status performSelector:sel];
#pragma clang diagnostic pop
                nudged = YES;
                break;
            }
        }
    } @catch (NSException *exception) {
        // Exception caught safely without crash
        nudged = NO;
    }

    return nudged;
}

@end
