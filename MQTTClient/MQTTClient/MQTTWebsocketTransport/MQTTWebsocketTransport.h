//
//  MQTTWebsocketTransport.h
//  MQTTClient
//
//  Created by Christoph Krey on 06.12.15.
//  Copyright © 2015-2019 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MQTTTransport.h"
#import <SocketRocket/SRWebSocket.h>

/** MQTTCFSocketTransport
 * implements an MQTTTransport on top of Websockets (SocketRocket)
 */
API_DEPRECATED("No longer supported; please adopt MQTTNWTransport", ios(8.0, 13.0), tvos(8.0, 13.0), macos(10.1, 10.15)) @interface MQTTWebsocketTransport : MQTTTransport <MQTTTransport, SRWebSocketDelegate>

/** path an NSString indicating the path component of the websocket URL request
 * defaults to @"/html"
 */
@property (strong, nonatomic) NSString *path;

/** headers an NSDictionary containing header fields for the URL request
 * defaults to nil
 */
@property (strong, nonatomic) NSDictionary <NSString *, NSString *> *headers;



@end
