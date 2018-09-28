//
//  MQTTv5SubscriptionIdentifiers.m
//  MQTTClient
//
//  Created by Christoph Krey on 23.06.18.
//  Copyright © 2018 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MQTTLog.h"
#import "MQTTTestHelpers.h"

@interface MQTTv5SubscriptionIdentifiers : MQTTTestHelpers
@property (nonatomic) int sent;
@property (nonatomic) int received;
@property (nonatomic) int processed;

@end

@implementation MQTTv5SubscriptionIdentifiers

- (void)test_sI_available {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    self.session = [self newSession];
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    self.session.sessionExpiryInterval = nil;
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    
    if (self.session.subscriptionIdentifiersAvailable && self.session.subscriptionIdentifiersAvailable.boolValue) {
        [self testSubscribe:TOPIC atLevel:0 subscriptionIdentifier:0];
        [self testSubscribe:TOPIC atLevel:0 subscriptionIdentifier:1];
    } else {
        [self testSubscribe:TOPIC atLevel:0 subscriptionIdentifier:0];
        [self testSubscribeFailureExpected:TOPIC atLevel:0 subscriptionIdentifier:1];
    }
    
    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}

- (void)test_sI_Simple {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    self.session = [self newSession];
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    self.session.sessionExpiryInterval = nil;
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    
    if (self.session.subscriptionIdentifiersAvailable && self.session.subscriptionIdentifiersAvailable.boolValue) {
        [self testSubscribe:TOPIC atLevel:0 subscriptionIdentifier:1];
        self.subscriptionIdentifiers = nil;
        [self testPublish:[[NSString stringWithFormat:@"%s", __FUNCTION__]
                           dataUsingEncoding:NSUTF8StringEncoding
                           allowLossyConversion:TRUE]
                  onTopic:TOPIC
                   retain:FALSE
                  atLevel:MQTTQosLevelAtMostOnce];
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        self.timedout = false;
        [self performSelector:@selector(timedout:)
                   withObject:nil
                   afterDelay:self.timeoutValue];
        
        while (!self.timedout) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        
        if (self.subscriptionIdentifiers) {
            BOOL found = false;
            for (NSNumber *subscriptionIdentifier in self.subscriptionIdentifiers) {
                if (subscriptionIdentifier.unsignedIntValue == 1) {
                    found = true;
                }
            }
            XCTAssertTrue(found, @"Subscription Identifier 1 not found");
        } else {
            XCTFail(@"no Subscription Identifer returned");
        }
    }
    
    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}

- (void)test_sI_Change {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    self.session = [self newSession];
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    self.session.sessionExpiryInterval = nil;
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    
    if (self.session.subscriptionIdentifiersAvailable && self.session.subscriptionIdentifiersAvailable.boolValue) {
        [self testSubscribe:TOPIC atLevel:0 subscriptionIdentifier:1];
        [self testSubscribe:TOPIC atLevel:0 subscriptionIdentifier:2];
        self.subscriptionIdentifiers = nil;
        [self testPublish:[[NSString stringWithFormat:@"%s", __FUNCTION__]
                           dataUsingEncoding:NSUTF8StringEncoding
                           allowLossyConversion:TRUE]
                  onTopic:TOPIC
                   retain:FALSE
                  atLevel:MQTTQosLevelAtMostOnce];
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        self.timedout = false;
        [self performSelector:@selector(timedout:)
                   withObject:nil
                   afterDelay:self.timeoutValue];
        
        while (!self.timedout) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        
        if (self.subscriptionIdentifiers) {
            BOOL found = false;
            for (NSNumber *subscriptionIdentifier in self.subscriptionIdentifiers) {
                if (subscriptionIdentifier.unsignedIntValue == 2) {
                    found = true;
                }
            }
            XCTAssertTrue(found, @"Subscription Identifier 1 not found");
        } else {
            XCTFail(@"no Subscription Identifer returned");
        }
    }
    
    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}

- (void)test_sI_Unset {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    self.session = [self newSession];
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    self.session.sessionExpiryInterval = nil;
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    
    if (self.session.subscriptionIdentifiersAvailable && self.session.subscriptionIdentifiersAvailable.boolValue) {
        [self testSubscribe:TOPIC atLevel:0 subscriptionIdentifier:1];
        [self testSubscribe:TOPIC atLevel:0 subscriptionIdentifier:0];
        self.subscriptionIdentifiers = nil;
        [self testPublish:[[NSString stringWithFormat:@"%s", __FUNCTION__]
                           dataUsingEncoding:NSUTF8StringEncoding
                           allowLossyConversion:TRUE]
                  onTopic:TOPIC
                   retain:FALSE
                  atLevel:MQTTQosLevelAtMostOnce];
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        self.timedout = false;
        [self performSelector:@selector(timedout:)
                   withObject:nil
                   afterDelay:self.timeoutValue];
        
        while (!self.timedout) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        
        if (self.subscriptionIdentifiers) {
            XCTFail(@"Subscription Identifer returned");
        }
    }
    
    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}

- (void)test_sI_Multi {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    self.session = [self newSession];
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    self.session.sessionExpiryInterval = nil;
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    
    if (self.session.subscriptionIdentifiersAvailable && self.session.subscriptionIdentifiersAvailable.boolValue) {
        [self testSubscribe:TOPIC atLevel:0 subscriptionIdentifier:1];
        [self testSubscribe:[NSString stringWithFormat:@"%@/#", TOPIC]
                    atLevel:0
     subscriptionIdentifier:2];
        self.subscriptionIdentifiers = nil;
        [self testPublish:[[NSString stringWithFormat:@"%s", __FUNCTION__]
                           dataUsingEncoding:NSUTF8StringEncoding
                           allowLossyConversion:TRUE]
                  onTopic:TOPIC
                   retain:FALSE
                  atLevel:MQTTQosLevelAtMostOnce];
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        self.timedout = false;
        [self performSelector:@selector(timedout:)
                   withObject:nil
                   afterDelay:self.timeoutValue];
        
        while (!self.timedout) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        
        if (self.subscriptionIdentifiers) {
            BOOL found = false;
            for (NSNumber *subscriptionIdentifier in self.subscriptionIdentifiers) {
                if (subscriptionIdentifier.unsignedIntValue == 2) {
                    found = true;
                }
            }
            XCTAssertTrue(found, @"Subscription Identifier 1 not found");
        } else {
            XCTFail(@"no Subscription Identifer returned");
        }
    }
    
    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}


/*
 * helpers
 */

- (void)testSubscribeSubackExpected:(NSString *)topic atLevel:(UInt8)qos
             subscriptionIdentifier:(UInt32)subscriptionIdentifier {
    [self testSubscribe:topic atLevel:qos subscriptionIdentifier:subscriptionIdentifier];
    
    XCTAssertFalse(self.timedout, @"No SUBACK received within %f seconds [MQTT-3.8.4-1]", self.timeoutValue);
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    XCTAssert(self.event == -1, @"Event %ld happened", (long)self.event);
    XCTAssertEqual(self.subMid, self.sentSubMid, @"msgID(%d) in SUBACK does not match msgID(%d) in SUBSCRIBE [MQTT-3.8.4-2]", self.subMid, self.sentSubMid);
    for (NSNumber *qos in self.qoss) {
        XCTAssertNotEqual([qos intValue], 0x80, @"Returncode in SUBACK is 0x80");
        XCTAssert([qos intValue] == 0x00 || [qos intValue] == 0x01 || [qos intValue] == 0x02, @"Returncode in SUBACK invalid [MQTT-3.9.3-2]");
    }
}

- (void)testSubscribeFailureExpected:(NSString *)topic atLevel:(UInt8)qos
              subscriptionIdentifier:(UInt32)subscriptionIdentifier {
    [self testSubscribe:topic atLevel:qos subscriptionIdentifier:subscriptionIdentifier];
    XCTAssertFalse(self.timedout, @"No SUBACK received within %f seconds [MQTT-3.8.4-1]", self.timeoutValue);
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    XCTAssert(self.event == -1, @"Event %ld happened", (long)self.event);
    XCTAssertEqual(self.subMid, self.sentSubMid, @"msgID(%d) in SUBACK does not match msgID(%d) in SUBSCRIBE [MQTT-3.8.4-2]", self.subMid, self.sentSubMid);
    for (NSNumber *qos in self.qoss) {
        XCTAssertEqual([qos intValue], MQTTSubscriptionIdentifiersNotSupported, @"Returncode in SUBACK is not MQTTSubscriptionIdentifiersNotSupported but %x", [qos intValue]);
    }
}

- (void)testSubscribe:(NSString *)topic
              atLevel:(UInt8)qos
subscriptionIdentifier:(UInt32)subscriptionIdentifier {
    self.subMid = 0;
    self.qoss = nil;
    self.event = -1;
    self.timedout = false;
    self.sentSubMid = [self.session subscribeToTopicV5:topic
                                               atLevel:qos
                                               noLocal:false
                                     retainAsPublished:false
                                        retainHandling:MQTTSendRetained
                                subscriptionIdentifier:subscriptionIdentifier
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
