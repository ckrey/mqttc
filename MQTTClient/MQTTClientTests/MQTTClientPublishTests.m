//
//  MQTTClientPublishTests.m
//  MQTTClient
//
//  Created by Christoph Krey on 05.02.14.
//  Copyright © 2014-2020 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "MQTTTestHelpers.h"

@interface MQTTClientPublishTests : MQTTTestHelpers
@property (nonatomic) NSInteger qos;
@property (nonatomic) BOOL blockQos2;
@property (strong, nonatomic) NSMutableDictionary *received;
@property (strong, nonatomic) NSMutableDictionary *published;
@property (strong, nonatomic) NSMutableDictionary *deliveredCallback;
@property (strong, nonatomic) NSMutableDictionary *delivered;

@end

@implementation MQTTClientPublishTests

- (void)setUp {
    [super setUp];
    MQTTStrict.strict = FALSE;
    [MQTTLog setLogLevel:DDLogLevelVerbose];
}

- (void)tearDown {
    [super tearDown];
}


- (void)testPublish_r0_q0_noPayload {
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self connect];
    [self testPublish:nil
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:0];
    [self shutdown];
}

- (void)testPublish_r0_q0_zeroLengthPayload {
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self connect];
    [self testPublish:[[NSData alloc] init]
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:0];
    [self shutdown];
}

- (void)testPublish_r1_q0_zeroLengthPayload {
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self connect];
    [self testPublish:[@"data" dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:TRUE
              atLevel:0];
    [self testPublish:[[NSData alloc] init]
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:TRUE
              atLevel:0];
    [self testPublish:[[NSData alloc] init]
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:TRUE
              atLevel:0];
    [self shutdown];
}

- (void)testPublish_r0_q0 {
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self connect];
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:0];
    [self shutdown];
}

- (void)testPublish_Dollar {
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self connect];
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"$%@/%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:0];
    [self shutdown];
}

/*
 * [MQTT-1.5.3-3]
 * A UTF-8 encoded sequence 0xEF 0xBB 0xBF is always to be interpreted to mean
 * U+FEFF ("ZERO WIDTH NO-BREAK SPACE") wherever it appears in a string and
 * MUST NOT be skipped over or stripped off by a packet receiver.
 */
- (void)testPublish_r0_q0_0xFEFF_MQTT_1_5_3_3 {
    // unichar feff = 0xFEFF;
    // [self connect];
    // [self testPublishCloseExpected:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
    //                        onTopic:[NSString stringWithFormat:@"%@<%C>/%s", TOPIC, feff, __FUNCTION__]
    //                         retain:NO
    //                        atLevel:0];
    // [self shutdown];
    DDLogInfo(@"Can't test[MQTT-1.5.3-3]");
}

/*
 * [MQTT-1.5.3-1]
 * The character data in a UTF-8 encoded string MUST be well-formed UTF-8 as defined by the
 * Unicode specification [Unicode] and restated in RFC 3629 [RFC3629]. In particular this data MUST NOT
 * include encodings of code points between U+D800 and U+DFFF. If a Server or Client receives a Control
 * Packet containing ill-formed UTF-8 it MUST close the Network Connection.
 */
- (void)testPublish_r0_q0_0xD800_MQTT_1_5_3_1 {
    NSString *stringWithD800 = [NSString stringWithFormat:@"%@/%C/%s", TOPIC, 0xD800, __FUNCTION__];
    DDLogVerbose(@"stringWithD800(%lu) %@", (unsigned long)stringWithD800.length, stringWithD800.description);
    
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self connect];
    [self testPublishCloseExpected:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                           onTopic:stringWithD800
                            retain:NO
                           atLevel:MQTTQosLevelExactlyOnce];
    [self shutdown];
}

/*
 * [MQTT-1.5.3-1]
 * The character data in a UTF-8 encoded string MUST be well-formed UTF-8 as defined by the
 * Unicode specification [Unicode] and restated in RFC 3629 [RFC3629]. In particular this data MUST NOT
 * include encodings of code points between U+D800 and U+DFFF. If a Server or Client receives a Control
 * Packet containing ill-formed UTF-8 it MUST close the Network Connection.
 */
- (void)testPublish_r0_q0_0x9c_MQTT_1_5_3_1 {
    // NSData *data = [NSData dataWithBytes:"MQTTClient/abc\x9c\x9dxyz" length:19];
    // NSString *stringWith9c = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
    // DDLogVerbose(@"stringWith9c(%lu) %@", (unsigned long)stringWith9c.length, stringWith9c.description);
    // [self connect];
    // [self testPublishCloseExpected:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
    //                        onTopic:stringWith9c
    //                         retain:TRUE
    //                        atLevel:MQTTQosLevelAtMostOnce];
    // [self shutdown];
    DDLogInfo(@"Can't test[MQTT-1.5.3-1]");
}

/*
 * [MQTT-1.5.3-2]
 * A UTF-8 encoded string MUST NOT include an encoding of the null character U+0000.
 * If a receiver (Server or Client) receives a Control Packet containing U+0000 it MUST close the Network Connection.
 */
- (void)testPublish_r0_q0_0x0000_MQTT_1_5_3_2 {
    NSString *stringWithNull = [NSString stringWithFormat:@"%@/%C/%s", TOPIC, 0, __FUNCTION__];
    DDLogVerbose(@"stringWithNull(%lu) %@",
                 (unsigned long)stringWithNull.length,
                 stringWithNull.description);
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self connect];
    [self testPublishCloseExpected:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                           onTopic:stringWithNull
                            retain:NO
                           atLevel:MQTTQosLevelAtMostOnce];
    [self shutdown];
}

- (void)testPublish_illegal_topic_9c_strict {
    NSData *data = [NSData dataWithBytes:"MQTTClient/abc\x9c\x9dxyz" length:19];
    NSString *stringWith9c = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self publish_illegal_topic_strict:stringWith9c];
}

- (void)testPublish_illegal_topic_Null_strict {
    NSString *stringWithNull = [NSString stringWithFormat:@"%@/%C/%s", TOPIC, 0, __FUNCTION__];
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self publish_illegal_topic_strict:stringWithNull];
}

- (void)testPublish_illegal_topic_FEFF_strict {
    NSString *stringWithFEFF = [NSString stringWithFormat:@"%@<%C>/%s", TOPIC, 0xfeff, __FUNCTION__];
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self publish_illegal_topic_strict:stringWithFEFF];
}

- (void)testPublish_illegal_topic_D800_strict {
    NSString *stringWithD800 = [NSString stringWithFormat:@"%@/%C/%s", TOPIC, 0xD800, __FUNCTION__];
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self publish_illegal_topic_strict:stringWithD800];
}

- (void)publish_illegal_topic_strict:(NSString *)topic {
    MQTTStrict.strict = TRUE;

    [self connect];
    @try {
        [self.session publishDataV5:[[NSData alloc] init]
                            onTopic:topic
                             retain:NO
                                qos:0
             payloadFormatIndicator:nil
              messageExpiryInterval:nil
                         topicAlias:nil
                      responseTopic:nil
                    correlationData:nil
                     userProperties:nil
                        contentType:nil
                     publishHandler:nil];
        XCTFail(@"Should not get here but throw exception before");
    } @catch (NSException *exception) {
        DDLogInfo(@"Exception correctly raised: %@", exception);
    } @finally {
        [self shutdown];
    }
}

- (void)testPublish_r0_q1 {
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self connect];
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:1];
    [self shutdown];
}

- (void)testPublish_a_lot_of_q0 {
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self connect];

    NSInteger publishedMessages = 0;
    __block NSInteger deliveredMessages = 0;
    for (int i = 0; i < ALOT; i++) {
        NSData *data = [[NSString stringWithFormat:@"%@/%s/%d", TOPIC, __FUNCTION__, i] dataUsingEncoding:NSUTF8StringEncoding];
        NSString *topic = [NSString stringWithFormat:@"%@/%s/%d", TOPIC, __FUNCTION__, i];
        self.sentMessageMid = [self.session publishDataV5:data
                                                  onTopic:topic
                                                   retain:false
                                                      qos:MQTTQosLevelAtMostOnce
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
            deliveredMessages++;
        }];
        DDLogInfo(@"testing publish %d/%d", i, self.sentMessageMid);
        publishedMessages++;
    }
    self.timedout = false;
    self.event = -1;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:self.timeoutValue];

    while ((publishedMessages != self.deliveredMessages ||
           publishedMessages != deliveredMessages) &&
           !self.timedout &&
           self.event == -1) {
        DDLogInfo(@"[MQTTClientPublishTests] waiting for %lu/%lu/%lu",
                  (unsigned long)deliveredMessages,
                  (unsigned long)self.deliveredMessages,
                  (unsigned long)publishedMessages);
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self];

    XCTAssertFalse(self.timedout, @"Timeout after %f seconds", self.timeoutValue);
    XCTAssert(self.event == -1, @"Event %ld happened", (long)self.event);
    [self shutdown];
}

- (void)testPublish_a_lot_of_q1 {
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self connect];

    self.published = [[NSMutableDictionary alloc] init];
    self.delivered = [[NSMutableDictionary alloc] init];
    self.deliveredCallback = [[NSMutableDictionary alloc] init];

    for (int i = 0; i < ALOT; i++) {
        NSData *data = [[NSString stringWithFormat:@"%@/%s/%d", TOPIC, __FUNCTION__, i] dataUsingEncoding:NSUTF8StringEncoding];
        NSString *topic = [NSString stringWithFormat:@"%@/%s/%d", TOPIC, __FUNCTION__, i];
        self.sentMessageMid = [self.session publishDataV5:data
                                                  onTopic:topic
                                                   retain:false
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
            [self.delivered setObject:@"DELIVERED" forKey:@(msgID)];
        }];
        
        DDLogInfo(@"testing publish %d/%d", i, self.sentMessageMid);
        [self.published setObject:@"PUBLISHED" forKey:@(self.sentMessageMid)];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    }
    
    self.timedout = false;
    self.event = -1;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:self.timeoutValue];
    
    while ((self.published.count != self.delivered.count ||
           self.published.count != self.deliveredCallback.count) &&
           !self.timedout &&
           self.event == -1) {
        DDLogInfo(@"[MQTTClientPublishTests] waiting for %lu/%lu/%lu",
                  (unsigned long)self.delivered.count,
                  (unsigned long)self.deliveredCallback.count,
                  (unsigned long)self.published.count);
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    XCTAssertFalse(self.timedout, @"Timeout after %f seconds", self.timeoutValue);
    XCTAssert(self.event == -1, @"Event %ld happened", (long)self.event);
    [self shutdown];
}

- (void)testPublish_a_lot_of_q2 {
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self connect];

    self.published = [[NSMutableDictionary alloc] init];
    self.delivered = [[NSMutableDictionary alloc] init];
    self.deliveredCallback = [[NSMutableDictionary alloc] init];

    for (int i = 0; i < ALOT; i++) {
        NSData *data = [[NSString stringWithFormat:@"%@/%s/%d", TOPIC, __FUNCTION__, i] dataUsingEncoding:NSUTF8StringEncoding];
        NSString *topic = [NSString stringWithFormat:@"%@/%s/%d", TOPIC, __FUNCTION__, i];
        self.sentMessageMid = [self.session publishDataV5:data
                                                  onTopic:topic
                                                   retain:false
                                                      qos:MQTTQosLevelExactlyOnce
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
            [self.delivered setObject:@"DELIVERED" forKey:@(msgID)];
        }];
        
        DDLogInfo(@"testing publish %d/%d", i, self.sentMessageMid);
        [self.published setObject:@"PUBLISHED" forKey:@(self.sentMessageMid)];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    }
    
    self.timedout = false;
    self.event = -1;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:self.timeoutValue];
    
    while ((self.published.count != self.delivered.count ||
           self.published.count != self.deliveredCallback.count) &&
           !self.timedout &&
           self.event == -1) {
        DDLogInfo(@"[MQTTClientPublishTests] waiting for %lu/%lu/%lu",
                  (unsigned long)self.delivered.count,
                  (unsigned long)self.deliveredCallback.count,
                  (unsigned long)self.published.count);
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    XCTAssertFalse(self.timedout, @"Timeout after %f seconds", self.timeoutValue);
    XCTAssert(self.event == -1, @"Event %ld happened", (long)self.event);
    [self shutdown];
}

/*
 * [MQTT-3.3.1-11]
 * A zero byte retained message MUST NOT be stored as a retained message on the Server.
 */
- (void)testPublish_r1_MQTT_3_3_1_11 {
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self connect];
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:YES
              atLevel:MQTTQosLevelAtLeastOnce];
    [self testPublish:[@"" dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:YES
              atLevel:MQTTQosLevelAtLeastOnce];
    [self testPublish:[[NSData alloc] init]
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:YES
              atLevel:MQTTQosLevelAtLeastOnce];
    [self shutdown];
}

- (void)testPublish_r0_q2 {
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self connect];
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:2];
    [self shutdown];
}

- (void)testPublish_r0_q3 {

    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self connect];
    [self testPublishCloseExpected:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                           onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
                            retain:NO
                           atLevel:3];
    [self shutdown];
}

- (void)testPublish_r0_q3_strict {
    MQTTStrict.strict = TRUE;
    
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self connect];
    @try {
        [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                  onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
                   retain:NO
                  atLevel:3];
        XCTFail(@"Should not get here but throw exception before");
    } @catch (NSException *exception) {
        //;
    } @finally {
        [self shutdown];
    }
}

- (void)testPublish_r1_q2 {
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self connect];
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:YES
              atLevel:2];
    [self testPublish:[[NSData alloc] init]
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:YES
              atLevel:2];
    [self shutdown];
}

- (void)testPublish_r1_q2_long_topic {
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self connect];

    NSString *topic = @"gg";
    while (topic.length <= 32768) {
        DDLogVerbose(@"LongPublishTopic (%lu)", topic.length);
        [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                  onTopic:[NSString stringWithFormat:@"%@/%ld/%@", TOPIC, topic.length, topic]
                   retain:YES
                  atLevel:2];
        [self testPublish:[[NSData alloc] init]
                  onTopic:[NSString stringWithFormat:@"%@/%ld/%@", TOPIC, topic.length, topic]
                   retain:YES
                  atLevel:2];
        topic = [topic stringByAppendingString:topic];
    }

    [self shutdown];
}

- (void)testPublish_r1_q2_long_topic_alt {
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self connect];

    NSString *topic = @"/gg";
    while (topic.length <= 32768 && [topic componentsSeparatedByString:@"/"].count < 199) {
        DDLogVerbose(@"LongPublishTopic (%lu)", topic.length);
        [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                  onTopic:[NSString stringWithFormat:@"%@/%ld%@", TOPIC, topic.length, topic]
                   retain:YES
                  atLevel:2];
        [self testPublish:[[NSData alloc] init]
                  onTopic:[NSString stringWithFormat:@"%@/%ld%@", TOPIC, topic.length, topic]
                   retain:YES
                  atLevel:2];
        topic = [topic stringByAppendingString:topic];
    }

    [self shutdown];
}

- (void)testPublish_r1_q2_long_payload {
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self connect];

    NSString *payload = @"gg";
    while (strlen([payload substringFromIndex:1].UTF8String) <= 1000000) {
        DDLogVerbose(@"LongPublishPayload (%lu)", strlen([[payload substringFromIndex:1] UTF8String]));
        [self testPublish:[payload dataUsingEncoding:NSUTF8StringEncoding]
                  onTopic:[NSString stringWithFormat:@"%@", TOPIC]
                   retain:YES
                  atLevel:2];
        [self testPublish:[[NSData alloc] init]
                  onTopic:[NSString stringWithFormat:@"%@", TOPIC]
                   retain:YES
                  atLevel:2];
        payload = [payload stringByAppendingString:payload];
    }
    [self shutdown];
}

/*
 * [MQTT-3.3.2-1]
 * The Topic Name MUST be present as the first field in the PUBLISH Packet Variable header.
 * It MUST be a UTF-8 encoded string.
 */
- (void)testPublishNoUTF8_MQTT_3_3_2_1 {
    DDLogInfo(@"Can't test[MQTT-3.3.2-1]");
}

/*
 * [MQTT-3.3.2-2]
 *
 * The Topic Name in the PUBLISH Packet MUST NOT contain wildcard characters.
 */
- (void)testPublishWithPlus_MQTT_3_3_2_2 {
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self connect];

    NSString *topic = [NSString stringWithFormat:@"%@/+%s", TOPIC, __FUNCTION__];
    DDLogVerbose(@"publishing to topic:%@", topic);
    
    [self testPublishCloseExpected:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                           onTopic:topic
                            retain:YES
                           atLevel:2];
    [self shutdown];
}

/*
 * [MQTT-3.3.2-2]
 *
 * The Topic Name in the PUBLISH Packet MUST NOT contain wildcard characters.
 */
- (void)testPublishWithHash_MQTT_3_3_2_2 {
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self connect];
    NSString *topic = [NSString stringWithFormat:@"%@/#%s", TOPIC, __FUNCTION__];
    DDLogVerbose(@"publishing to topic:%@", topic);
    
    [self testPublishCloseExpected:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                           onTopic:topic
                            retain:YES
                           atLevel:2];
    [self shutdown];
}

/*
 * [MQTT-4.7.3-1]
 *
 * All Topic Names and Topic Filters MUST be at least one character long.
 */
- (void)testPublishEmptyTopicQ0_MQTT_4_7_3_1 {
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self connect];
    [self testPublishCloseExpected:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                           onTopic:@""
                            retain:YES
                           atLevel:0];
    [self shutdown];
}

- (void)testPublishEmptyTopicQ1_MQTT_4_7_3_1 {
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self connect];
    [self testPublishCloseExpected:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                           onTopic:@""
                            retain:YES
                           atLevel:1];
    [self shutdown];
}

- (void)testPublishEmptyTopicQ2_MQTT_4_7_3_1 {
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self connect];
    [self testPublishCloseExpected:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                           onTopic:@""
                            retain:YES
                           atLevel:2];
    [self shutdown];
}

- (void)testPublish_q1 {
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self connect];
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelAtLeastOnce];
    [self shutdown];
}

- (void)testPublish_q1_x2 {
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self connect];
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/1%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelAtLeastOnce];
    
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/2%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelAtLeastOnce];
    [self shutdown];

    self.session = [self newSession];
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self connect];
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/3%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelAtLeastOnce];
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/4%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelAtLeastOnce];
    [self shutdown];
}

- (void)testPublish_q2 {
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self connect];
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/1%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelExactlyOnce];
    [self shutdown];
}

- (void)testPublish_q2_x2 {
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self connect];
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/1%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelExactlyOnce];
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/2%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelExactlyOnce];
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/3%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelExactlyOnce];
    [self shutdown];

    //self.session = [self newSession];
    //self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self connect];
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/4%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelExactlyOnce];
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/5%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelExactlyOnce];
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/6%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelExactlyOnce];
    [self shutdown];
}

/**
 [MQTT-3.3.1-1]
 The DUP flag MUST be set to 1 by the Client or Server when it attempts to re- deliver a PUBLISH Packet.
 */
- (void)testPublish_q2_dup_MQTT_3_3_1_1 {
    if ([self.parameters[@"protocollevel"] integerValue] == MQTTProtocolVersion50) {
        return;
    }
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self connect];
    self.timeoutValue = 90;
    self.blockQos2 = true;
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/1%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelExactlyOnce];
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/2%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelExactlyOnce];
    self.blockQos2 = true;
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/3%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelExactlyOnce];
    [self shutdown];
}



/*
 * helpers
 */

- (void)testPublishCloseExpected:(NSData *)data
                         onTopic:(NSString *)topic
                          retain:(BOOL)retain
                         atLevel:(UInt8)qos {
    [self testPublishCore:data onTopic:topic retain:retain atLevel:qos];

    self.timedout = false;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:self.timeoutValue];

    while (!self.timedout && self.event == -1) {
        DDLogVerbose(@"[MQTTClientPublishTests] waiting for event %ld", (long)self.event);
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self];

    DDLogVerbose(@"testPublishCloseExpected event:%ld", (long)self.event);
    XCTAssert(
              (self.event == MQTTSessionEventConnectionClosedByBroker) ||
              (self.event == MQTTSessionEventConnectionError) ||
              (self.event == MQTTSessionEventConnectionClosed) ||
              (self.event == MQTTSessionEventProtocolError),
              @"No MQTTSessionEventConnectionClosedByBroker or MQTTSessionEventConnectionError or MQTTSessionEventConnectionClosed or MQTTSessionEventProtocolError happened %ld", (long)self.event);
}

- (void)testPublish:(NSData *)data
            onTopic:(NSString *)topic
             retain:(BOOL)retain
            atLevel:(UInt8)qos {
    [self testPublishCore:data onTopic:topic retain:retain atLevel:qos];
    switch (qos % 4) {
        case 0:
            XCTAssert(self.event == -1, @"Event %ld happened", (long)self.event);
            XCTAssertFalse(self.timedout, @"Timeout after %f seconds", self.timeoutValue);
            break;
        case 1:
            XCTAssert(self.event == -1, @"Event %ld happened", (long)self.event);
            XCTAssertFalse(self.timedout, @"Timeout after %f seconds", self.timeoutValue);
            XCTAssert(self.deliveredMessageMid == self.sentMessageMid, @"sentMid(%ld) != mid(%ld)",
                      (long)self.sentMessageMid, (long)self.deliveredMessageMid);
            break;
        case 2:
            XCTAssert(self.event == -1, @"Event %ld happened", (long)self.event);
            XCTAssertFalse(self.timedout, @"Timeout after %f seconds", self.timeoutValue);
            XCTAssert(self.deliveredMessageMid == self.sentMessageMid, @"sentMid(%ld) != mid(%ld)",
                      (long)self.sentMessageMid, (long)self.deliveredMessageMid);
            break;
        case 3:
        default:
            XCTAssert(self.event == (long)MQTTSessionEventConnectionClosed, @"no close received");
            break;
    }
}

- (void)testPublishCore:(NSData *)data
                onTopic:(NSString *)topic
                 retain:(BOOL)retain
                atLevel:(UInt8)qos {
    self.deliveredMessageMid = -1;
    self.timedout = false;
    self.event = -1;
    self.sentMessageMid = [self.session publishDataV5:data
                                              onTopic:topic
                                               retain:retain
                                                  qos:qos
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
        //
    }];

    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:self.timeoutValue];
    
    while (self.deliveredMessageMid != self.sentMessageMid && !self.timedout && self.event == -1) {
        DDLogVerbose(@"[MQTTClientPublishTests] waiting for %d", self.sentMessageMid);
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (BOOL)ignoreReceived:(MQTTSession *)session
                  type:(MQTTCommandType)type
                   qos:(MQTTQosLevel)qos
              retained:(BOOL)retained
                 duped:(BOOL)duped
                   mid:(UInt16)mid
                data:(NSData *)data {
    DDLogVerbose(@"ignoreReceived:%d qos:%d retained:%d duped:%d mid:%d data:%@", type, qos, retained, duped, mid, data);
    if (self.blockQos2 && type == MQTTPubrec) {
        self.blockQos2 = false;
        return true;
    }
    return false;
}

- (void)connect {
    [super connect];
    self.qos = -1;
}
- (void)shutdown {
    [super shutdownWithReturnCode:MQTTSuccess
            sessionExpiryInterval:nil
                     reasonString:nil
                   userProperties:nil];
}

- (void)messageDeliveredV5:(MQTTSession *)session
                     msgID:(UInt16)msgID
                     topic:(NSString *)topic
                      data:(NSData *)data
                       qos:(MQTTQosLevel)qos
                retainFlag:(BOOL)retainFlag
    payloadFormatIndicator:(NSNumber *)payloadFormatIndicator
     messageExpiryInterval:(NSNumber *)messageExpiryInterval
                topicAlias:(NSNumber *)topicAlias
             responseTopic:(NSString *)responseTopic
           correlationData:(NSData *)correlationData
            userProperties:(NSArray<NSDictionary<NSString *,NSString *> *> *)userProperties
               contentType:(NSString *)contentType {
    DDLogInfo(@"messageDelivered %d", msgID);
    
    if (self.deliveredCallback) {
        [self.deliveredCallback setObject:@"DELIVERED" forKey:@(msgID)];
    }
    [super messageDeliveredV5:session
                        msgID:msgID
                        topic:topic
                         data:data
                          qos:qos
                   retainFlag:retainFlag
       payloadFormatIndicator:payloadFormatIndicator
        messageExpiryInterval:messageExpiryInterval
                   topicAlias:topicAlias
                responseTopic:responseTopic
              correlationData:correlationData
               userProperties:userProperties
                  contentType:contentType];
}

- (void)newMessageV5:(MQTTSession *)session
                data:(NSData *)data
             onTopic:(NSString *)topic
                 qos:(MQTTQosLevel)qos
            retained:(BOOL)retained
                 mid:(unsigned int)mid
payloadFormatIndicator:(NSNumber *)payloadFormatIndicator
messageExpiryInterval:(NSNumber *)messageExpiryInterval
          topicAlias:(NSNumber *)topicAlias
       responseTopic:(NSString *)responseTopic
     correlationData:(NSData *)correlationData
      userProperties:(NSArray<NSDictionary<NSString *,NSString *> *> *)userProperties
         contentType:(NSString *)contentType
subscriptionIdentifiers:(NSArray<NSNumber *> *)subscriptionIdentifiers {
    DDLogInfo(@"newMessage %d", mid);
    
    if (self.received) {
        [self.received setObject:@"RECEIVED" forKey:@(mid)];
    }
    [super newMessageV5:session
                   data:data
                onTopic:topic
                    qos:qos
               retained:retained
                    mid:mid
 payloadFormatIndicator:payloadFormatIndicator
  messageExpiryInterval:messageExpiryInterval
             topicAlias:topicAlias
          responseTopic:responseTopic
        correlationData:correlationData
         userProperties:userProperties
            contentType:contentType
subscriptionIdentifiers:subscriptionIdentifiers];
}


@end
