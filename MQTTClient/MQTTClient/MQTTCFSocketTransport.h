//
//  MQTTCFSocketTransport.h
//  MQTTClient
//
//  Created by Christoph Krey on 06.12.15.
//  Copyright © 2015-2019 Christoph Krey. All rights reserved.
//

#import "MQTTTransport.h"
#import "MQTTCFSocketDecoder.h"
#import "MQTTCFSocketEncoder.h"

/** MQTTCFSocketTransport
 * implements an MQTTTransport on top of CFNetwork
 */
API_DEPRECATED("No longer supported; please adopt MQTTNWTransport", ios(8.0, 13.0), tvos(8.0, 13.0), macos(10.1, 10.15)) @interface MQTTCFSocketTransport : MQTTTransport <MQTTTransport, MQTTCFSocketDecoderDelegate, MQTTCFSocketEncoderDelegate>

/** Require for VoIP background service
 * defaults to NO
 */
@property (nonatomic) BOOL voip;


@end
