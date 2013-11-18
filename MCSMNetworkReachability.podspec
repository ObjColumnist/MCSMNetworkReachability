Pod::Spec.new do |s|
  s.name     = 'MCSMNetworkReachability'
  s.version  = '1.0'
  s.summary  = 'Network Reachability for iOS and OS X.'
  s.homepage = 'https://github.com/ObjColumnist/MCSMNetworkReachability'
  s.author   = 'Spencer MacDonald'
  s.source   = { :git => 'https://github.com/ObjColumnist/MCSMNetworkReachability.git'}
  s.license  = 'Modified BSD License'
  s.description = 'MCSMNetworkReachability is a class that is built upon the GCD SCNetworkReachabilityRef APIs, that makes it quick and easy to query and monitor the Network Reachability of your iOS or OS X device.'
  
  s.source_files = '*.{h,m}'
  s.requires_arc = true 
  s.frameworka = 'Foundation','SystemConfiguration'
end