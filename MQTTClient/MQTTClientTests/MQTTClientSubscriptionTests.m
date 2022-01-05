//
//  MQTTClientSubscriptionTests.m
//  MQTTClient
//
//  Created by Christoph Krey on 14.01.14.
//  Copyright © 2014-2022 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "MQTTTestHelpers.h"

@interface MQTTClientSubscriptionTests : MQTTTestHelpers
@end

@implementation MQTTClientSubscriptionTests

- (void)setUp {
    [super setUp];
    [MQTTLog setLogLevel:DDLogLevelVerbose];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testSubscribe_with_wrong_flags_MQTT_3_8_1_1 {
    MQTTStrict.strict = TRUE;
    DDLogVerbose(@"can't test [MQTT-3.8.1-1]");
}

- (void)testUnsubscribe_with_wrong_flags_MQTT_3_10_1_1 {
    DDLogVerbose(@"can't test [MQTT-3.10.1-1]");
}

- (void)testSubscribeWMultipleTopics_None_MQTT_3_8_3_3 {
    [self connect];
    [self testMultiSubscribeCloseExpected:@{}];
    [self shutdown];
}

- (void)testSubscribeWMultipleTopics_None_strict {
    MQTTStrict.strict = TRUE;
    [self connect];
    @try {
        [self testMultiSubscribeCloseExpected:@{}];
        XCTFail(@"Should never get here, exception expected");
    } @catch (NSException *exception) {
        //;
    } @finally {
        //
    }
}

- (void)testSubscribeWMultipleTopics_One {
    [self connect];
    [self testMultiSubscribeSubackExpected:@{@"MQTTClient": @(2)}];
    [self shutdown];
}

- (void)testSubscribeWMultipleTopics_more {
    [self connect];
    [self testMultiSubscribeSubackExpected:@{@"MQTTClient": @(0), @"MQTTClient/abc": @(0), @"MQTTClient/#": @(1)}];
    [self shutdown];
}

- (void)testSubscribeWMultipleTopics_16_to_256 {
    [self connect];
    for (int TOPICS = 16; TOPICS <= 256; TOPICS += 16) {
        NSMutableDictionary *topics = [[NSMutableDictionary alloc] initWithCapacity:TOPICS];
        for (int i = 0; i < TOPICS; i++) {
            topics[[NSString stringWithFormat:@"MQTTClient/a/lot/%d", i]] = @(1);
        }
        DDLogVerbose(@"testing %d subscriptions", TOPICS);
        if (![self testMultiSubscribeSubackExpected:topics]) {
            break;
        }
    }
    [self shutdown];
}

- (void)testSubscribeQoS0 {
    [self connect];
    [self testSubscribeSubackExpected:@"MQTTClient/#" atLevel:0];
    [self shutdown];
}

- (void)testSubscribeQoS1 {
    [self connect];
    [self testSubscribeSubackExpected:@"MQTTClient/#" atLevel:1];
    [self shutdown];
}

- (void)testSubscribeQoS2 {
    [self connect];
    [self testSubscribeSubackExpected:@"MQTTClient/#" atLevel:2];
    [self shutdown];
}

- (void)testSubscribeTopicPlain {
    [self connect];
    [self testSubscribeSubackExpected:@"MQTTClient" atLevel:0];
    [self shutdown];
}

- (void)testSubscribeTopicHash {
    [self connect];
    [self testSubscribeSubackExpected:@"MQTTClient/#" atLevel:0];

    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.timedout = FALSE;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:self.timeoutValue];
    while (!self.timedout) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    [self shutdown];
}

- (void)testSubscribeTopicHashnotalone_MQTT_4_7_1_2 {
    [self connect];
    NSString *topic = @"#MQTTClient";
    DDLogVerbose(@"subscribing to topic %@", topic);
    [self testSubscribeCloseExpected:topic atLevel:0];
    [self shutdown];
}

- (void)testSubscribeTopicEmpty_MQTT_4_7_3_1 {
    [self connect];
    [self testSubscribeCloseExpected:@"" atLevel:0];
    [self shutdown];
}

- (void)testSubscribeTopicHashnotlast_MQTT_4_7_1_2 {
    [self connect];
    [self testSubscribeCloseExpected:@"MQTTClient/#/def" atLevel:0];
    [self shutdown];
}

- (void)testSubscribeTopicHashnotlast_strict {
    MQTTStrict.strict = TRUE;
    [self connect];
    @try {
        [self testSubscribeCloseExpected:@"MQTTClient/#/def" atLevel:0];
        XCTFail(@"Should never get here, exception expected");
    } @catch (NSException *exception) {
        //;
    } @finally {
        //
    }
}

- (void)testSubscribeTopicPlus {
    [self connect];
    [self testSubscribeSubackExpected:@"+" atLevel:0];
    [self shutdown];
}

- (void)testSubscribeTopicSlash {
    [self connect];
    [self testSubscribeSubackExpected:@"/" atLevel:0];
    [self shutdown];
}

- (void)testSubscribeTopicPlusnotalone_MQTT_4_7_1_3 {
    [self connect];
    NSString *topic = @"MQTTClient+";
    DDLogVerbose(@"subscribing to topic %@", topic);
    [self testSubscribeCloseExpected:topic atLevel:0];
    [self shutdown];
}

- (void)testSubscribeTopicNone_MQTT_3_8_3_3 {
    [self connect];
    [self testSubscribeCloseExpected:nil atLevel:0];
    [self shutdown];
}

- (void)testSubscribeWildcardSYS_MQTT_4_7_2_1 {
    [self connect];
    [self testSubscribeSubackExpected:@"+/#" atLevel:0];
    
    self.timedout = false;
    self.SYSreceived = 0;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:self.timeoutValue];
    
    while (self.SYSreceived == 0 && !self.timedout) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    XCTAssert(self.SYSreceived == 0, @"The Server MUST NOT match Topic Filters starting with a wildcard character (# or +) with Topic Names beginning with a $ character [MQTT-4.7.2-1].");
    
    [self shutdown];
}

- (void)testSubscribeTopic_0x00_in_topic {
    [self connect];
    NSString *topic = @"a\0b";
    [self testSubscribeCloseExpected:topic atLevel:0];
    [self shutdown];
}

- (void)testSubscribeLong_MQTT_4_7_3_3 {
    [self connect];
    
    NSString *topic = @"aa";
    for (UInt32 i = 2; i <= 64; i *= 2) {
        topic = [topic stringByAppendingString:topic];
    }
    DDLogVerbose(@"LongSubscribe (%lu)", strlen([[topic substringFromIndex:1] UTF8String]));
    [self testSubscribeSubackExpected:[topic substringFromIndex:1] atLevel:0];
    
    topic = @"bb";
    for (UInt32 i = 2; i <= 1024; i *= 2) {
        topic = [topic stringByAppendingString:topic];
    }
    DDLogVerbose(@"LongSubscribe (%lu)", strlen([[topic substringFromIndex:1] UTF8String]));
    [self testSubscribeSubackExpected:[topic substringFromIndex:1] atLevel:0];
    
    topic = @"cc";
    for (UInt32 i = 2; i <= 10000; i *= 2) {
        topic = [topic stringByAppendingString:topic];
    }
    DDLogVerbose(@"LongSubscribe (%lu)", strlen([[topic substringFromIndex:1] UTF8String]));
    [self testSubscribeSubackExpected:[topic substringFromIndex:1] atLevel:0];
    
    topic = @"dd";
    for (UInt32 i = 2; i < 32768; i *= 2) {
        topic = [topic stringByAppendingString:topic];
    }
    DDLogVerbose(@"LongSubscribe (%lu)", strlen([[topic substringFromIndex:1] UTF8String]));
    [self testSubscribeSubackExpected:[topic substringFromIndex:1] atLevel:0];
    
    topic = @"ee";
    for (UInt32 i = 2; i <= 32768; i *= 2) {
        topic = [topic stringByAppendingString:topic];
    }
    DDLogVerbose(@"LongSubscribe (%lu)", strlen([[topic substringFromIndex:15] UTF8String]));
    [self testSubscribeSubackExpected:[topic substringFromIndex:15] atLevel:0];
    
    topic = @"ff";
    for (UInt32 i = 2; i <= 32768; i *= 2) {
        topic = [topic stringByAppendingString:topic];
    }
    DDLogVerbose(@"LongSubscribe (%lu)", strlen([[topic substringFromIndex:2] UTF8String]));
    [self testSubscribeSubackExpected:[topic substringFromIndex:2] atLevel:0];
    
    topic = @"gg";
    for (UInt32 i = 2; i <= 32768; i *= 2) {
        topic = [topic stringByAppendingString:topic];
    }
    DDLogVerbose(@"LongSubscribe (%lu)", strlen([[topic substringFromIndex:1] UTF8String]));
    [self testSubscribeSubackExpected:[topic substringFromIndex:1] atLevel:0];
    
    [self shutdown];
}


- (void)testSubscribeSameTopicDifferentQoS_MQTT_3_8_4_3 {
    [self connect];
    [self testSubscribeSubackExpected:TOPIC atLevel:0];
    [self testSubscribeSubackExpected:TOPIC atLevel:1];
    [self testSubscribeSubackExpected:TOPIC atLevel:2];
    [self testSubscribeSubackExpected:TOPIC atLevel:1];
    [self testSubscribeSubackExpected:TOPIC atLevel:0];
    [self shutdown];
}

/*
 * [MQTT-3.3.5-1]
 * The Server MUST deliver the message to the Client respecting the maximum QoS of all the matching subscriptions.
 */
- (void)test_delivery_max_QoS_MQTT_3_3_5_1 {
    [self connect];
    [self testSubscribeSubackExpected:[NSString stringWithFormat:@"%@/#", TOPIC] atLevel:MQTTQosLevelAtMostOnce];
    [self testSubscribeSubackExpected:[NSString stringWithFormat:@"%@/2", TOPIC] atLevel:MQTTQosLevelExactlyOnce];
    [self.session publishDataV5:[@"Should be delivered with qos 1" dataUsingEncoding:NSUTF8StringEncoding]
                        onTopic:[NSString stringWithFormat:@"%@/2", TOPIC]
                         retain:NO
                            qos:MQTTQosLevelAtLeastOnce
         payloadFormatIndicator:nil
          messageExpiryInterval:nil
                     topicAlias:nil
                  responseTopic:nil
                correlationData:nil
                 userProperties:nil
                    contentType:nil
                 publishHandler:nil];
    [self shutdown];
}

- (void)test_very_long {
    [self connect];
    [self testSubscribeSubackExpected:TOPIC atLevel:MQTTQosLevelAtMostOnce];
    NSMutableData *data = [[@"a" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:FALSE] mutableCopy]; // 1
    [data appendData:data]; // 2
    [data appendData:data]; // 4
    [data appendData:data]; // 8
    [data appendData:data]; // 16
    [data appendData:data]; // 32
    [data appendData:data]; // 64
    [data appendData:data]; // 128
    [data appendData:data]; // 256
    [data appendData:data]; // 512
    [data appendData:data]; // 1k
    [data appendData:data]; // 2k
    [data appendData:data]; // 4k
    [data appendData:data]; // 8k
    [data appendData:data]; // 16k
    [data appendData:data]; // 32k
    [data appendData:data]; // 64k
    [data appendData:data]; // 128k
    [data appendData:data]; // 256k
    [data appendData:data]; // 512k
    [data appendData:data]; // 1MB
    [data appendData:data]; // 2MB
    [data appendData:data]; // 4MB

    [self.session publishDataV5:data
                        onTopic:TOPIC
                         retain:NO
                            qos:MQTTQosLevelAtLeastOnce
         payloadFormatIndicator:nil
          messageExpiryInterval:nil
                     topicAlias:nil
                  responseTopic:nil
                correlationData:nil
                 userProperties:nil
                    contentType:nil
                 publishHandler:
     ^(NSError * _Nullable error,
       NSString * _Nullable reasonString,
       NSArray<NSDictionary<NSString *,NSString *> *> * _Nullable userProperties,
       NSNumber * _Nullable reasonCode,
       UInt16 msgID) {
        DDLogInfo(@"publishHandler %@ %@ %@ %@ %u",error, reasonString, userProperties, reasonCode, msgID);
    }
     ];

    self.timedout = FALSE;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:self.timeoutValue];
    while (self.newMessages != 1 && !self.timedout) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }

    [self shutdown];
}

/*
 * [MQTT-3.10.4-1]
 * The Topic Filters (whether they contain wildcards or not) supplied in an UNSUBSCRIBE
 * packet MUST be compared character-by-character with the current set of Topic Filters
 * held by the Server for the Client. If any filter matches exactly then its owning Subscription
 * is deleted, otherwise no additional processing occurs.
 */
- (void)test_unsubscribe_byte_by_byte_MQTT_3_10_4_1 {
    [self connect];
    [self testSubscribeSubackExpected:TOPIC atLevel:MQTTQosLevelAtMostOnce];
    [self testUnsubscribeTopic:TOPIC];
    [self shutdown];
}

/*
 * [MQTT-3.10.4-2]
 * If a Server deletes a Subscription It MUST stop adding any new messages for delivery to the Client.
 */
- (void)test_stop_delivering_after_unsubscribe_MQTT_3_10_4_2 {
    [self connect];
    [self testSubscribeSubackExpected:TOPIC atLevel:MQTTQosLevelAtMostOnce];
    [self.session publishDataV5:[@"Should be delivered" dataUsingEncoding:NSUTF8StringEncoding]
                        onTopic:TOPIC
                         retain:NO
                            qos:MQTTQosLevelAtLeastOnce
         payloadFormatIndicator:nil
          messageExpiryInterval:nil
                     topicAlias:nil
                  responseTopic:nil
                correlationData:nil
                 userProperties:nil
                    contentType:nil
                 publishHandler:nil];
    
    [self testUnsubscribeTopic:TOPIC];
    
    [self.session publishDataV5:[@"Should not be delivered" dataUsingEncoding:NSUTF8StringEncoding]
                        onTopic:TOPIC
                         retain:NO
                            qos:MQTTQosLevelAtLeastOnce
         payloadFormatIndicator:nil
          messageExpiryInterval:nil
                     topicAlias:nil
                  responseTopic:nil
                correlationData:nil
                 userProperties:nil
                    contentType:nil
                 publishHandler:nil];
    
    [self shutdown];
}

/*
 * [MQTT-3.10.4-3]
 * If a Server deletes a Subscription It MUST complete the delivery of any QoS 1 or
 * QoS 2 messages which it has started to send to the Client.
 */
- (void)test_complete_delivering_qos12_after_unsubscribe_MQTT_3_10_4_3 {
    [self connect];
    [self testSubscribeSubackExpected:TOPIC atLevel:MQTTQosLevelExactlyOnce];
    [self.session publishDataV5:[@"Should be delivered" dataUsingEncoding:NSUTF8StringEncoding]
                        onTopic:TOPIC
                         retain:false
                            qos:MQTTQosLevelAtLeastOnce
         payloadFormatIndicator:nil
          messageExpiryInterval:nil
                     topicAlias:nil
                  responseTopic:nil
                correlationData:nil
                 userProperties:nil
                    contentType:nil
                 publishHandler:nil];
    
    [self testUnsubscribeTopic:TOPIC];
    [self.session publishDataV5:[@"Should not be delivered" dataUsingEncoding:NSUTF8StringEncoding]
                        onTopic:TOPIC
                         retain:false
                            qos:MQTTQosLevelAtLeastOnce
         payloadFormatIndicator:nil
          messageExpiryInterval:nil
                     topicAlias:nil
                  responseTopic:nil
                correlationData:nil
                 userProperties:nil
                    contentType:nil
                 publishHandler:nil];
    [self shutdown];
}


- (void)testUnsubscribeTopicPlain {
    [self connect];
    [self testUnsubscribeTopic:@"abc"];
    [self shutdown];
}

- (void)testUnubscribeTopicHash {
    [self connect];
    [self testUnsubscribeTopic:@"#"];
    [self shutdown];
}

- (void)testUnsubscribeTopicHashnotalone_MQTT_4_7_1_2 {
    [self connect];
    [self testUnsubscribeTopicCloseExpected:@"#abc"];
    [self shutdown];
}

- (void)testUnsubscribeTopicHashnotalone_strict {
    MQTTStrict.strict = TRUE;
    [self connect];
    @try {
        [self testUnsubscribeTopicCloseExpected:@"#abc"];
        XCTFail(@"Should never get here, exception expected");
    } @catch (NSException *exception) {
        //;
    } @finally {
        //
    }
}

- (void)testUnsubscribeTopicPlus {
    [self connect];
    [self testUnsubscribeTopic:@"+"];
    [self shutdown];
}

- (void)testUnsubscribeTopicEmpty_MQTT_4_7_3_1 {
    [self connect];
    [self testUnsubscribeTopicCloseExpected:@""];
    [self shutdown];
}

- (void)testUnsubscribeTopicHashnotlast_MQTT_4_7_1_2 {
    [self connect];
    [self testUnsubscribeTopicCloseExpected:@"MQTTClient/#/def"];
    [self shutdown];
}

- (void)testUnsubscribeTopicNone_MQTT_3_10_3_2 {
    [self connect];
    [self testUnsubscribeTopicCloseExpected:nil];
    [self shutdown];
}

- (void)testUnsubscribeTopicZero_MQTT_4_7_3_1 {
    [self connect];
    [self testUnsubscribeTopicCloseExpected:@"a\0b"];
    [self shutdown];
}

- (void)testMultiUnsubscribe_None_MQTT_3_10_3_2 {
    [self connect];
    [self testMultiUnsubscribeTopicCloseExpected:@[]];
    [self shutdown];
}

- (void)testMultiUnsubscribe_One {
    [self connect];
    [self testMultiUnsubscribeTopic:@[@"abc"]];
    [self shutdown];
}

- (void)testMultiUnsubscribe_more {
    [self connect];
    [self testMultiUnsubscribeTopic:@[@"abc", @"ab/+/ef", @"+", @"#", @"abc/df", @"a/b/c/#"]];
    [self shutdown];
}

/*
 * helpers
 */

- (void)testSubscribeSubackExpected:(NSString *)topic atLevel:(UInt8)qos {
    [self testSubscribe:topic atLevel:qos];
    XCTAssertFalse(self.timedout, @"No SUBACK received within %f seconds [MQTT-3.8.4-1]", self.timeoutValue);
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    XCTAssert(self.event == -1, @"Event %ld happened", (long)self.event);
    XCTAssertEqual(self.subMid, self.sentSubMid, @"msgID(%d) in SUBACK does not match msgID(%d) in SUBSCRIBE [MQTT-3.8.4-2]", self.subMid, self.sentSubMid);
    for (NSNumber *qos in self.qoss) {
        XCTAssertNotEqual([qos intValue], 0x80, @"Returncode in SUBACK is 0x80");
        XCTAssert([qos intValue] == 0x00 || [qos intValue] == 0x01 || [qos intValue] == 0x02, @"Returncode in SUBACK invalid [MQTT-3.9.3-2]");
    }
}

- (BOOL)testMultiSubscribeSubackExpected:(NSDictionary *)topics {
    [self testMultiSubscribe:topics];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];

    if (self.timedout || self.event != -1 || self.subMid != self.sentSubMid) {
        XCTAssertFalse(self.timedout, @"No SUBACK received within %f seconds [MQTT-3.8.4-1]", self.timeoutValue);
        XCTAssert(self.event == -1, @"Event %ld happened", (long)self.event);
        XCTAssertEqual(self.subMid, self.sentSubMid, @"msgID(%d) in SUBACK does not match msgID(%d) in SUBSCRIBE [MQTT-3.8.4-2]", self.subMid, self.sentSubMid);
        return FALSE;
    }

    for (NSNumber *qos in self.qoss) {
        if ([qos intValue] == 0x00 || [qos intValue] == 0x01 || [qos intValue] == 0x02) {
        } else {
            XCTAssert([qos intValue] == 0x00 || [qos intValue] == 0x01 || [qos intValue] == 0x02,
                      @"Returncode %d in SUBACK invalid [MQTT-3.9.3-2]", [qos intValue]);
            return FALSE;
        }
    }
    return TRUE;
}

- (void)testSubscribeCloseExpected:(NSString *)topic atLevel:(UInt8)qos {
    [self testSubscribe:topic atLevel:qos];
    XCTAssertFalse(self.timedout, @"No close within %f seconds", self.timeoutValue);
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if (self.event == MQTTSessionEventConnectionClosedByBroker ||
        self.event == MQTTSessionEventConnectionClosed ||
        self.event == MQTTSessionEventProtocolError) {
        XCTAssert(self.subMid == 0, @"SUBACK received");
        XCTAssert(self.event == MQTTSessionEventConnectionClosedByBroker ||
                  self.event == MQTTSessionEventConnectionClosed ||
                  self.event == MQTTSessionEventProtocolError,
                  @"Event %ld happened", (long)self.event);
    } else {
        XCTAssertEqual(self.subMid, self.sentSubMid, @"msgID(%d) in SUBACK does not match msgID(%d) in SUBSCRIBE [MQTT-3.8.4-2]", self.subMid, self.sentSubMid);
        for (NSNumber *qos in self.qoss) {
            XCTAssertEqual([qos intValue], 0x80, @"Returncode in SUBACK is not 0x80");
        }
    }
}

- (void)testMultiSubscribeCloseExpected:(NSDictionary *)topics {
    [self testMultiSubscribe:topics];
    XCTAssertFalse(self.timedout, @"No close within %f seconds", self.timeoutValue);
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if (self.event == MQTTSessionEventConnectionClosedByBroker ||
        self.event == MQTTSessionEventConnectionClosed ||
        self.event == MQTTSessionEventProtocolError) {
        XCTAssert(self.subMid == 0, @"SUBACK received");
        XCTAssert(self.event == MQTTSessionEventConnectionClosedByBroker ||
                  self.event == MQTTSessionEventConnectionClosed ||
                  self.event == MQTTSessionEventProtocolError,
                  @"Event %ld happened", (long)self.event);
    } else {
        XCTAssertEqual(self.subMid, self.sentSubMid, @"msgID(%d) in SUBACK does not match msgID(%d) in SUBSCRIBE [MQTT-3.8.4-2]", self.subMid, self.sentSubMid);
        for (NSNumber *qos in self.qoss) {
            XCTAssertEqual([qos intValue], 0x80, @"Returncode in SUBACK is not 0x80");
        }
    }
}

- (void)testSubscribeFailureExpected:(NSString *)topic atLevel:(UInt8)qos {
    [self testSubscribe:topic atLevel:qos];
    XCTAssertFalse(self.timedout, @"No SUBACK received within %f seconds [MQTT-3.8.4-1]", self.timeoutValue);
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    XCTAssert(self.event == -1, @"Event %ld happened", (long)self.event);
    XCTAssertEqual(self.subMid, self.sentSubMid, @"msgID(%d) in SUBACK does not match msgID(%d) in SUBSCRIBE [MQTT-3.8.4-2]", self.subMid, self.sentSubMid);
    for (NSNumber *qos in self.qoss) {
        XCTAssertEqual([qos intValue], 0x80, @"Returncode in SUBACK is not 0x80");
    }
}

- (void)testSubscribe:(NSString *)topic atLevel:(UInt8)qos {
    self.subMid = 0;
    self.qoss = nil;
    self.event = -1;
    self.timedout = false;
    self.sentSubMid = [self.session subscribeToTopicV5:topic
                                               atLevel:qos
                                               noLocal:false
                                     retainAsPublished:false
                                        retainHandling:MQTTSendRetained
                                subscriptionIdentifier:0
                                        userProperties:nil
                                      subscribeHandler:nil];
    DDLogVerbose(@"sent mid(SUBSCRIBE): %d", self.sentSubMid);
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:self.timeoutValue];
    
    while (self.subMid == 0 && !self.qoss && !self.timedout && self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
}

- (void)testMultiSubscribe:(NSDictionary *)topics {
    self.subMid = 0;
    self.qoss = nil;
    self.event = -1;
    self.timedout = false;
    self.sentSubMid = [self.session subscribeToTopicsV5:topics
                                 subscriptionIdentifier:0
                                         userProperties:nil
                                       subscribeHandler:nil];
    
    DDLogVerbose(@"sent mid(SUBSCRIBE multi): %d", self.sentSubMid);
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:self.timeoutValue];
    
    while (self.subMid == 0 && !self.timedout && self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
}

- (void)testUnsubscribeTopic:(NSString *)topic {
    self.unsubMid = 0;
    self.event = -1;
    self.timedout = false;
    self.sentUnsubMid = [self.session unsubscribeTopicsV5:@[topic]
                                           userProperties:nil
                                       unsubscribeHandler:nil];
    DDLogVerbose(@"sent mid(UNSUBSCRIBE): %d", self.sentUnsubMid);
    
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:self.timeoutValue];
    
    while (self.unsubMid == 0 && !self.timedout && self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    XCTAssertFalse(self.timedout, @"No UNSUBACK received [MQTT-3.10.3-5] within %f seconds", self.timeoutValue);
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    XCTAssertEqual(self.unsubMid, self.sentUnsubMid, @"msgID(%d) in UNSUBACK does not match msgID(%d) in UNSUBSCRIBE [MQTT-3.10.3-4]", self.unsubMid, self.sentUnsubMid);
}

- (void)testUnsubscribeTopicCloseExpected:(NSString *)topic {
    self.unsubMid = 0;
    self.event = -1;
    self.timedout = false;
    NSMutableArray <NSString *> *topics = [[NSMutableArray alloc] init];
    if (topic) {
        [topics addObject:topic];
    }
    self.sentUnsubMid = [self.session unsubscribeTopicsV5:topics
                                           userProperties:nil
                                       unsubscribeHandler:nil];
    DDLogVerbose(@"sent mid(UNSUBSCRIBE): %d", self.sentUnsubMid);
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:self.timeoutValue];
    
    while (self.unsubMid == 0 && !self.timedout && self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    XCTAssertFalse(self.timedout, @"No close within %f seconds",self.timeoutValue);
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    XCTAssert(self.event == MQTTSessionEventConnectionClosedByBroker ||
              self.event == MQTTSessionEventConnectionClosed ||
              self.event == MQTTSessionEventProtocolError,
              @"Event %ld happened", (long)self.event);
}

- (void)testMultiUnsubscribeTopic:(NSArray *)topics {
    self.unsubMid = 0;
    self.event = -1;
    self.timedout = false;
    self.sentUnsubMid = [self.session unsubscribeTopicsV5:topics
                                           userProperties:nil
                                       unsubscribeHandler:nil];
    DDLogVerbose(@"sent mid(UNSUBSCRIBE multi): %d", self.sentUnsubMid);
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:self.timeoutValue];
    
    while (self.unsubMid == 0 && !self.timedout && self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    XCTAssertFalse(self.timedout, @"No UNSUBACK received [MQTT-3.10.3-5] within %f seconds", self.timeoutValue);
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    XCTAssertEqual(self.unsubMid, self.sentUnsubMid, @"msgID(%d) in UNSUBACK does not match msgID(%d) in UNSUBSCRIBE [MQTT-3.10.3-4]", self.unsubMid, self.sentUnsubMid);
}

- (void)testMultiUnsubscribeTopicCloseExpected:(NSArray *)topics {
    self.unsubMid = 0;
    self.event = -1;
    self.timedout = false;
    self.sentUnsubMid = [self.session unsubscribeTopicsV5:topics
                                           userProperties:nil
                                       unsubscribeHandler:nil];
    DDLogVerbose(@"sent mid(UNSUBSCRIBE multi): %d", self.sentUnsubMid);
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:self.timeoutValue];
    
    while (self.unsubMid == 0 && !self.timedout && self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    XCTAssertFalse(self.timedout, @"No close within %f seconds",self.timeoutValue);
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    XCTAssert(self.event == MQTTSessionEventConnectionClosedByBroker ||
              self.event == MQTTSessionEventConnectionClosed ||
              self.event == MQTTSessionEventProtocolError,
              @"Event %ld happened", (long)self.event);
}

- (void)connect {
    self.session = [self newSession];
    self.session.delegate = self;
    self.event = -1;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.timedout = FALSE;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:self.timeoutValue];
    
    [self.session connectWithConnectHandler:nil];
    
    while (self.event == -1 && !self.timedout) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    
    XCTAssert(!self.timedout, @"timedout");
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)shutdown {
    self.event = -1;
    
    
    self.timedout = false;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:self.timeoutValue];
    
    [self.session closeWithReturnCode:MQTTSuccess
                sessionExpiryInterval:nil
                         reasonString:nil
                       userProperties:nil
                    disconnectHandler:nil];
    
    while (self.event == -1 && !self.timedout) {
        DDLogVerbose(@"waiting for disconnect");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    
    XCTAssert(!self.timedout, @"timedout");
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    self.session.delegate = nil;
    self.session = nil;
}




@end
