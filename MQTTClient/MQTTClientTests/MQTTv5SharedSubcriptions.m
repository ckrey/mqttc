//
//  MQTTv5SharedSubcriptions.m
//  MQTTClient
//
//  Created by Christoph Krey on 16.02.19.
//  Copyright © 2019 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MQTTLog.h"
#import "MQTTTestHelpers.h"

@interface MQTTv5SharedSubcriptions : MQTTTestHelpers

@end

@implementation MQTTv5SharedSubcriptions

- (void)test_sS_available {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    self.session = [self newSession];
    self.session.sessionExpiryInterval = nil;
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);

    if (!self.session.sharedSubscriptionAvailable ||
        self.session.sharedSubscriptionAvailable.boolValue) {
        [self testSubscribeSubackExpected:@"$share/shared1/MQTTClient" atLevel:MQTTQosLevelAtMostOnce];
    } else {
        [self testSubscribeFailureExpected:@"$share/shared1/MQTTClient" atLevel:MQTTQosLevelAtMostOnce];
    }

    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}

- (void)test_sS_empty_share {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    self.session = [self newSession];
    self.session.sessionExpiryInterval = nil;
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);

    if (!self.session.sharedSubscriptionAvailable ||
        self.session.sharedSubscriptionAvailable.boolValue) {
        [self testSubscribeCloseExpected:@"$share//MQTTClient" atLevel:MQTTQosLevelAtMostOnce];
    }

    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}

- (void)test_sS_invalid_share {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    self.session = [self newSession];
    self.session.sessionExpiryInterval = nil;
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);

    if (!self.session.sharedSubscriptionAvailable ||
        self.session.sharedSubscriptionAvailable.boolValue) {
        [self testSubscribeCloseExpected:@"$share/#/MQTTClient" atLevel:MQTTQosLevelAtMostOnce];
    }

    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}

- (void)test_sS_invalid_filter {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    self.session = [self newSession];
    self.session.sessionExpiryInterval = nil;
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);

    if (!self.session.sharedSubscriptionAvailable ||
        self.session.sharedSubscriptionAvailable.boolValue) {
        [self testSubscribeCloseExpected:@"$share/shared1/" atLevel:MQTTQosLevelAtMostOnce];
    }

    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}

/*
 * helpers
 */

- (void)testSubscribeSubackExpected:(NSString *)topic
                            atLevel:(UInt8)qos {
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

- (void)testSubscribeFailureExpected:(NSString *)topic
                             atLevel:(UInt8)qos {
    [self testSubscribe:topic atLevel:qos];
    XCTAssertFalse(self.timedout, @"No SUBACK received within %f seconds [MQTT-3.8.4-1]", self.timeoutValue);
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    XCTAssert(self.event == -1, @"Event %ld happened", (long)self.event);
    XCTAssertEqual(self.subMid, self.sentSubMid, @"msgID(%d) in SUBACK does not match msgID(%d) in SUBSCRIBE [MQTT-3.8.4-2]", self.subMid, self.sentSubMid);
    for (NSNumber *qos in self.qoss) {
        XCTAssertEqual([qos intValue], MQTTSharedSubscriptionNotSupported, @"Returncode in SUBACK is not MQTTSharedSubscriptionNotSupported but %x", [qos intValue]);
    }
}

- (void)testSubscribeCloseExpected:(NSString *)topic
                           atLevel:(UInt8)qos {
    [self testSubscribe:topic atLevel:qos];
    XCTAssertFalse(self.timedout, @"No SUBACK received within %f seconds [MQTT-3.8.4-1]", self.timeoutValue);
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    XCTAssertEqual(self.event, MQTTSessionEventConnectionClosedByBroker,
                   @"Event unequal MQTTSessionEventConnectionClosedByBroker %ld", (long)self.event);
}


- (void)testSubscribe:(NSString *)topic
              atLevel:(UInt8)qos {
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
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:self.timeoutValue];

    while (self.subMid == 0 && !self.qoss && !self.timedout && self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
}

- (void)testPublish:(NSData *)data
            onTopic:(NSString *)topic
             retain:(BOOL)retain
            atLevel:(UInt8)qos {
    [self testPublishCore:data onTopic:topic retain:retain atLevel:qos];
    switch (qos % 4) {
        case 0:
            XCTAssert(self.event == -1, @"Event %ld happened", (long)self.event);
            XCTAssert(self.timedout, @"Responses during %f seconds timeout", self.timeoutValue);
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
                                       publishHandler:^(NSError * _Nullable error, NSString * _Nullable reasonString, NSArray<NSDictionary<NSString *,NSString *> *> * _Nullable userProperties, NSNumber * _Nullable reasonCode) {
                                           //
                                       }];


    self.timedout = false;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:self.timeoutValue];

    while (self.deliveredMessageMid != self.sentMessageMid && !self.timedout && self.event == -1) {
        DDLogVerbose(@"[MQTTClientPublishTests] waiting for %d", self.sentMessageMid);
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

@end
