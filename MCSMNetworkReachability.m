//
//  MCSMNetworkReachabilityListener.m
//  MCSMSystemConfiguration
//
//  Created by Spencer MacDonald on 12/10/2011.
//  Copyright 2011 Square Bracket Software. All rights reserved.
//

#import "MCSMNetworkReachability.h"

#import <sys/socket.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>

@interface MCSMNetworkReachability ()

@property (nonatomic,assign,getter = isMonitoring,readwrite) BOOL monitoring;

@end

@implementation MCSMNetworkReachability{
    
    dispatch_queue_t _dispatchQueue;

    BOOL _isLocalWiFiNetworkReachabilityRef;
    SCNetworkReachabilityRef _networkReachabilityRef;
    void (^_statusHandler)(MCSMNetworkReachabilityStatus, BOOL);
}

static void MCSMReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags networkReachabilityFlags, void *info){

    @autoreleasepool {
        
        MCSMNetworkReachability *networkReachabilityListener = (__bridge MCSMNetworkReachability *)info;

        if(networkReachabilityListener.statusHandler != NULL)
        {
            networkReachabilityListener.statusHandler([networkReachabilityListener networkReachabilityStatus],[networkReachabilityListener isConnectionRequired]);
        }
    }
}

+ (instancetype)networkReachabilityWithHostName:(NSString *)hostName{
    return [[[self class] alloc] initWithHostName:hostName];
}

+ (instancetype)networkReachabilityWithAddress:(const struct sockaddr_in *)hostAddress{
    return [[[self class] alloc] initWithAddress:hostAddress];
}

+ (instancetype)networkReachabilityForInternetConnection{
    return [[[self class] alloc] initForInternetConnection];
}

+ (instancetype)networkReachabilityForLocalWiFi{
    return [[[self class] alloc] initForLocalWiFi];
}

- (id)init{
    
    if((self = [super init])){
        NSString *dispatchQueueLabel = [NSString stringWithFormat:@"com.squarebracketsoftware.mcsmnetworkreachability.%p",self];
        _dispatchQueue = dispatch_queue_create([dispatchQueueLabel UTF8String], 0);
    }
	return self;
}

- (instancetype)initWithHostName:(NSString *)hostName{
    
    if((self = [self init])){
        
        SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, [hostName UTF8String]);
        
        if(reachability != NULL)
        {
            _networkReachabilityRef = reachability;
            _isLocalWiFiNetworkReachabilityRef = NO;
            _hostName = [hostName copy];
        }
    }
	return self;
}

- (instancetype)initWithAddress:(const struct sockaddr_in *)hostAddress{
    
    if((self = [self init])){
        
        SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)hostAddress);

        if(reachability != NULL)
        {
            _networkReachabilityRef = reachability;
            _isLocalWiFiNetworkReachabilityRef = NO;
            
            if(_hostAddress)
            {
                _hostAddress = CFRetain(hostAddress);
            }
        }
    }
    return self;
}

- (instancetype)initForInternetConnection{
    
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    return [self initWithAddress:&zeroAddress];
}

- (instancetype)initForLocalWiFi{
    
    struct sockaddr_in localWifiAddress;
    bzero(&localWifiAddress, sizeof(localWifiAddress));
    localWifiAddress.sin_len = sizeof(localWifiAddress);
    localWifiAddress.sin_family = AF_INET;
    // IN_LINKLOCALNETNUM is defined in <netinet/in.h> as 169.254.0.0
    localWifiAddress.sin_addr.s_addr = htonl(IN_LINKLOCALNETNUM);
    if((self = [self initWithAddress:&localWifiAddress])){
        _isLocalWiFiNetworkReachabilityRef = YES;
    }

    return self;
}

- (void)dealloc{
    
    [self stopMonitoring];
    
    _statusHandler = nil;
    
    _dispatchQueue = NULL;
    
    if(_networkReachabilityRef != NULL)
    {
        CFRelease(_networkReachabilityRef), _networkReachabilityRef = NULL;
    }
        
    if(_hostAddress != NULL)
    {
        CFRelease(_hostAddress), _hostAddress = NULL;
    }
}

- (void)setStatusHandler:(MCSMNetworkReachabilityStatusHandler)statusHandler{
    
    _statusHandler = [statusHandler copy];
    
    if(_statusHandler != NULL)
    {
        [self startMonitoring];
    }
    else
    {
        [self stopMonitoring];
    }
}

#pragma mark -
#pragma mark Network Reachability Status

- (MCSMNetworkReachabilityStatus)networkReachabilityStatus{
    
    MCSMNetworkReachabilityStatus networkReachabilityStatus = MCSMNetworkReachabilityStatusUnknown;
    
    if(_networkReachabilityRef != NULL)
    {
        networkReachabilityStatus = MCSMNetworkReachabilityStatusNotReachable;
        
        SCNetworkReachabilityFlags networkReachabilityFlags;
	
        if (SCNetworkReachabilityGetFlags(_networkReachabilityRef, &networkReachabilityFlags))
        {
            if(_isLocalWiFiNetworkReachabilityRef)
            {
                networkReachabilityStatus = [self localWiFiStatusForNetworkReachabilityFlags:networkReachabilityFlags];
            }
            else
            {
                networkReachabilityStatus = [self networkStatusForNetworkReachabilityFlags:networkReachabilityFlags];
            }
        }
    }
    
    return networkReachabilityStatus;
}

- (BOOL)isConnectionRequired{
    
    SCNetworkReachabilityFlags networkReachabilityFlags;

    if (SCNetworkReachabilityGetFlags(_networkReachabilityRef, &networkReachabilityFlags))
    {
        return (networkReachabilityFlags & kSCNetworkReachabilityFlagsConnectionRequired);
    }

    return NO;
}

#pragma mark -
#pragma mark Monitoring

- (BOOL)startMonitoring{
    
    BOOL started = NO;
    
    if(!self.monitoring)
    {
        SCNetworkReachabilityContext context = {0, (__bridge void *)self, NULL, NULL, NULL};
        
        if(SCNetworkReachabilitySetCallback(_networkReachabilityRef, MCSMReachabilityCallback, &context))
        {
            if(SCNetworkReachabilitySetDispatchQueue(_networkReachabilityRef,_dispatchQueue))
            {
                started = YES;
            }
        }
        
        if(started)
        {
            self.monitoring = YES;
        }
    }
    
    return started;
}

- (BOOL)stopMonitoring{
    
    BOOL stopped = NO;
    
    if(self.monitoring)
    {
        if(_networkReachabilityRef != NULL)
        {
            if(SCNetworkReachabilitySetDispatchQueue(_networkReachabilityRef,NULL))
            {
                stopped = YES;
            }
        }
        
        if(stopped)
        {
            self.monitoring = NO;
        }
    }
    
    return stopped;
}

#pragma mark -
#pragma mark Network Flag Handling

- (MCSMNetworkReachabilityStatus)localWiFiStatusForNetworkReachabilityFlags:(SCNetworkReachabilityFlags)networkReachabilityFlags{
    
    MCSMNetworkReachabilityStatus networkReachabilityStatus = MCSMNetworkReachabilityStatusNotReachable;

    if((networkReachabilityFlags & kSCNetworkReachabilityFlagsReachable) && (networkReachabilityFlags & kSCNetworkReachabilityFlagsIsDirect))
    {
        networkReachabilityStatus = MCSMNetworkReachabilityStatusReachableViaWiFi;
    }

    return networkReachabilityStatus;
}

- (MCSMNetworkReachabilityStatus)networkStatusForNetworkReachabilityFlags:(SCNetworkReachabilityFlags)networkReachabilityFlags{
    
    if ((networkReachabilityFlags & kSCNetworkReachabilityFlagsReachable) == 0)
    {
        return MCSMNetworkReachabilityStatusNotReachable;
    }

    MCSMNetworkReachabilityStatus networkReachabilityStatus = MCSMNetworkReachabilityStatusNotReachable;

    if ((networkReachabilityFlags & kSCNetworkReachabilityFlagsConnectionRequired) == 0)
    {
        networkReachabilityStatus = MCSMNetworkReachabilityStatusReachableViaWiFi;
    }

    if ((((networkReachabilityFlags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
        (networkReachabilityFlags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0))
    {
            if ((networkReachabilityFlags & kSCNetworkReachabilityFlagsInterventionRequired) == 0)
            {
                networkReachabilityStatus = MCSMNetworkReachabilityStatusReachableViaWiFi;
            }
        }
#if (TARGET_OS_EMBEDDED || TARGET_OS_IPHONE)

    if ((networkReachabilityFlags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN)
    {
        networkReachabilityStatus = MCSMNetworkReachabilityStatusReachableViaWWAN;
    }

#endif
    return networkReachabilityStatus;
}

@end
