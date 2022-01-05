//
// MQTTDecoder.h
// MQTTClient.framework
// 
// Copyright © 2013-2022, Christoph Krey. All rights reserved.
//
// based on
//
// Copyright (c) 2011, 2013, 2lemetry LLC
// 
// All rights reserved. This program and the accompanying materials
// are made available under the terms of the Eclipse Public License v1.0
// which accompanies this distribution, and is available at
// http://www.eclipse.org/legal/epl-v10.html
// 
// Contributors:
//    Kyle Roche - initial API and implementation and/or initial documentation
// 

#import <Foundation/Foundation.h>
#import <mqttc/MQTTMessage.h>

typedef NS_ENUM(unsigned int, MQTTDecoderEvent) {
    MQTTDecoderEventProtocolError,
    MQTTDecoderEventConnectionClosed,
    MQTTDecoderEventConnectionError
};

@class MQTTDecoder;

@protocol MQTTDecoderDelegate <NSObject>

- (void)decoder:(MQTTDecoder *)sender didReceiveMessage:(NSData *)data;
- (void)decoder:(MQTTDecoder *)sender handleEvent:(MQTTDecoderEvent)eventCode error:(NSError *)error;

@end


@interface MQTTDecoder : NSObject
//@property (strong, nonatomic)    NSRunLoop*      runLoop;
//@property (strong, nonatomic)    NSString*       runLoopMode;

@property (weak, nonatomic ) id<MQTTDecoderDelegate> delegate;

- (void)open;
- (void)close;
- (void)decodeMessage:(NSData *)data;
@end


