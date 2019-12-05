//
// MQTTSSLSecurityPolicyEncoder.h
// MQTTClient.framework
//
// Copyright © 2013-2019, Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MQTTSSLSecurityPolicy.h"
#import "MQTTCFSocketEncoder.h"

API_DEPRECATED("No longer supported; please adopt MQTTNWTransport", ios(8.0, 13.0), tvos(8.0, 13.0), macos(10.1, 10.15)) @interface MQTTSSLSecurityPolicyEncoder : MQTTCFSocketEncoder
@property(strong, nonatomic) MQTTSSLSecurityPolicy *securityPolicy;
@property(strong, nonatomic) NSString *securityDomain;

@end

