#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CPLEngineReport : NSObject

@property (nonatomic, assign) BOOL isAvailable;
@property (nonatomic, copy, nullable) NSString *statusDescription;
@property (nonatomic, copy, nullable) NSString *blockedReason;
@property (nonatomic, copy, nullable) NSString *rawDescription;
@property (nonatomic, assign) BOOL hasChangesToProcess;
@property (nonatomic, assign) BOOL isBlockedByLowPowerMode;
@property (nonatomic, assign) BOOL hasThermalPressure;
@property (nonatomic, assign) BOOL isConnectedToNetwork;
@property (nonatomic, assign) NSInteger pendingCountEstimate;
@property (nonatomic, copy, nullable) NSString *diagnosticLog;

@end

@interface CPLEngineProbe : NSObject

+ (CPLEngineReport *)probeStatus;
+ (BOOL)nudgeSync;

@end

NS_ASSUME_NONNULL_END
