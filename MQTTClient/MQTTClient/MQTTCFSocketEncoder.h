//
// MQTTCFSocketEncoder.h
// MQTTClient.framework
//
// Copyright © 2013-2019, Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MQTTCFSocketEncoderState) {
    MQTTCFSocketEncoderStateInitializing,
    MQTTCFSocketEncoderStateReady,
    MQTTCFSocketEncoderStateError
};

@class MQTTCFSocketEncoder;

@protocol MQTTCFSocketEncoderDelegate <NSObject>
- (void)encoderDidOpen:(MQTTCFSocketEncoder *)sender;
- (void)encoder:(MQTTCFSocketEncoder *)sender didFailWithError:(NSError *)error;
- (void)encoderdidClose:(MQTTCFSocketEncoder *)sender;

@end

API_DEPRECATED("No longer supported; please adopt MQTTNWTransport", ios(8.0, 13.0), tvos(8.0, 13.0), macos(10.1, 10.15)) @interface MQTTCFSocketEncoder : NSObject <NSStreamDelegate>
@property (nonatomic) MQTTCFSocketEncoderState state;
@property (strong, nonatomic) NSError *error;
@property (strong, nonatomic) NSOutputStream *stream;
@property (strong, nonatomic) NSRunLoop *runLoop;
@property (strong, nonatomic) NSString *runLoopMode;
@property (weak, nonatomic ) id<MQTTCFSocketEncoderDelegate> delegate;

- (void)open;
- (void)close;
- (BOOL)send:(NSData *)data;

@end

