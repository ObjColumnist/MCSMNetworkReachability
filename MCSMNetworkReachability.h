//
//  MCSMNetworkReachabilityListener.h
//  MCSMSystemConfiguration
//
//  Created by Spencer MacDonald on 12/10/2011.
//  Copyright 2011 Square Bracket Software. All rights reserved.
//

@import Foundation;
@import SystemConfiguration;
#import <netinet/in.h>

typedef enum MCSMNetworkReachabilityStatus : NSUInteger{
    MCSMNetworkReachabilityStatusUnknown, 
	MCSMNetworkReachabilityStatusNotReachable,
	MCSMNetworkReachabilityStatusReachableViaWiFi,
	MCSMNetworkReachabilityStatusReachableViaWWAN
} MCSMNetworkReachabilityStatus;

typedef void (^MCSMNetworkReachabilityStatusHandler)(MCSMNetworkReachabilityStatus networkReachabilityStatus, BOOL connectionRequired);

@interface MCSMNetworkReachability : NSObject

@property (nonatomic,copy) MCSMNetworkReachabilityStatusHandler statusHandler;

@property (nonatomic,copy) NSString *hostName;

@property (nonatomic,assign) const struct sockaddr_in *hostAddress;

@property (nonatomic,assign,readonly) MCSMNetworkReachabilityStatus networkReachabilityStatus;

@property (nonatomic,assign,getter = isConnectionRequired,readonly) BOOL connectionRequired;


+ (instancetype)networkReachabilityWithHostName:(NSString *)hostName;

+ (instancetype)networkReachabilityWithAddress:(const struct sockaddr_in *)hostAddress;

+ (instancetype)networkReachabilityForInternetConnection;

+ (instancetype)networkReachabilityForLocalWiFi;


- (instancetype)initWithHostName:(NSString *)hostName;

- (instancetype)initWithAddress:(const struct sockaddr_in *)hostAddress;

- (instancetype)initForInternetConnection;

- (instancetype)initForLocalWiFi;

@end
