//
// MQTTCFSocketDecoder.h
// MQTTClient.framework
// 
// Copyright © 2013-2019, Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MQTTCFSocketDecoderState) {
    MQTTCFSocketDecoderStateInitializing,
    MQTTCFSocketDecoderStateReady,
    MQTTCFSocketDecoderStateError
};

@class MQTTCFSocketDecoder;

@protocol MQTTCFSocketDecoderDelegate <NSObject>
- (void)decoder:(MQTTCFSocketDecoder *)sender didReceiveMessage:(NSData *)data;
- (void)decoderDidOpen:(MQTTCFSocketDecoder *)sender;
- (void)decoder:(MQTTCFSocketDecoder *)sender didFailWithError:(NSError *)error;
- (void)decoderdidClose:(MQTTCFSocketDecoder *)sender;

@end

API_DEPRECATED("No longer supported; please adopt MQTTNWTransport", ios(8.0, 13.0), tvos(8.0, 13.0), macos(10.1, 10.15)) @interface MQTTCFSocketDecoder : NSObject <NSStreamDelegate>
@property (nonatomic) MQTTCFSocketDecoderState state;
@property (strong, nonatomic) NSError *error;
@property (strong, nonatomic) NSInputStream *stream;
@property (strong, nonatomic) NSRunLoop *runLoop;
@property (strong, nonatomic) NSString *runLoopMode;
@property (weak, nonatomic ) id<MQTTCFSocketDecoderDelegate> delegate;

- (void)open;
- (void)close;

@end


