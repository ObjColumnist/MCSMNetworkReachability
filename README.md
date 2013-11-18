# MCSMNetworkReachability

`MCSMNetworkReachability` is a class that is built upon the GCD `SCNetworkReachabilityRef` APIs, that makes it quick and easy to query and monitor the Network Reachability of your iOS or OS X device.

You can query and monitor if a remote Host Name or Address is reachable, or just that you have a Local WiFi or Internet Connection, using one of the designated initalizers:

```objc
- (instancetype)initWithHostName:(NSString *)hostName;

- (instancetype)initWithAddress:(const struct sockaddr_in *)hostAddress;

- (instancetype)initForInternetConnection;

- (instancetype)initForLocalWiFi;
```

Once you have initalized a Network Reachabilty object, you simply need to check the 2 properties:

```objc
@property (nonatomic,assign,readonly) MCSMNetworkReachabilityStatus networkReachabilityStatus;

@property (nonatomic,assign,getter = isConnectionRequired,readonly) BOOL connectionRequired;
```

The `networkReachabilityStatus` are defined as:

```objc
typedef enum MCSMNetworkReachabilityStatus : NSUInteger{
	MCSMNetworkReachabilityStatusUnknown, 
	MCSMNetworkReachabilityStatusNotReachable,
	MCSMNetworkReachabilityStatusReachableViaWiFi,
	MCSMNetworkReachabilityStatusReachableViaWWAN
} MCSMNetworkReachabilityStatus;
```

If you wish to monitor reachability changes simply set the `statusHander`:

```objc
networkReachability.statusHandler = ^(MCSMNetworkReachabilityStatus networkReachabilityStatus, BOOL connectionRequired){
	//Handle Reachability Change
}
```

## Requirements

- Automatic Reference Counting (ARC)
- SystemConfiguration.framework 