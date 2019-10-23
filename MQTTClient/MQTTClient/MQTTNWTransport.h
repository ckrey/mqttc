//
//  MQTTNWTransport.h
//  MQTTClient
//
//  Created by Christoph Krey on 01.10.19.
//  Copyright © 2019 Christoph Krey. All rights reserved.
//

#import "MQTTTransport.h"
#import <Network/Network.h>

NS_ASSUME_NONNULL_BEGIN

@interface MQTTNWTransport : MQTTTransport <NSURLSessionDelegate, NSURLSessionStreamDelegate>
/** host an NSString containing the hostName or IP address of the host to connect to
 * defaults to @"localhost"
*/
@property (strong, nonatomic) NSString *host;

/** port an unsigned 32 bit integer containing the IP port number to connect to
 * defaults to 80
 */
@property (nonatomic) UInt32 port;

/** tls a boolean indicating whether the transport should be using security
 * defaults to NO
 */
@property (nonatomic) BOOL tls;

/** tls a boolean indicating whether the transport should be using websocket protocol
 * defaults to NO
 */
@property (nonatomic) BOOL ws;

@end

NS_ASSUME_NONNULL_END
