//
//  MQTTv5Tests.m
//  MQTTClientTests
//
//  Created by Christoph Krey on 13.01.14.
//  Copyright © 2014-2020 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "MQTTLog.h"
#import "MQTTTestHelpers.h"

@interface MQTTv5Tests : MQTTTestHelpers
@end

@implementation MQTTv5Tests

- (void)test_complete_v5 {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    self.session.sessionExpiryInterval = @60U;
    self.session.requestProblemInformation = @1U;
    self.session.requestResponseInformation = @1U;
    self.session.receiveMaximum = @5U;
    self.session.topicAliasMaximum = @10U;
    self.session.userProperties = @[@{@"u1":@"v1"}, @{@"u2": @"v2"}];
    self.session.maximumPacketSize = @8192U;
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}

- (void)test_v5_mPS_longMessage_q0 {
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self v5_mPS_longMessage:MQTTQosLevelAtMostOnce];
}

- (void)test_v5_mPS_longMessage_q1 {
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self v5_mPS_longMessage:MQTTQosLevelAtLeastOnce];
}

- (void)test_v5_mPS_longMessage_q2 {
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self v5_mPS_longMessage:MQTTQosLevelExactlyOnce];
}

- (void)v5_mPS_longMessage:(MQTTQosLevel)qos {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }

    self.session.requestProblemInformation = @1U;
    self.session.maximumPacketSize = @128U;
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    if (self.session.maximumQoS && self.session.maximumQoS.integerValue < qos) {
        return;
    }

    __block BOOL done;

    self.newMessages = 0;
    self.retainedMessages = 0;

    done = false;
    [self.session publishDataV5:[[NSData alloc] init]
                        onTopic:TOPIC
                         retain:true
                            qos:qos
         payloadFormatIndicator:nil
          messageExpiryInterval:nil
                     topicAlias:nil
                  responseTopic:nil
                correlationData:nil
                 userProperties:nil
                    contentType:nil
                 publishHandler:^(NSError * _Nullable error, NSString * _Nullable reasonString, NSArray<NSDictionary<NSString *,NSString *> *> * _Nullable userProperties, NSNumber * _Nullable reasonCode) {
                     done = true;
                 }];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.timedout = FALSE;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:[self.parameters[@"timeout"] intValue]];

    while (!done && !self.timedout && self.session.status == MQTTSessionStatusConnected) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }

    done = false;
    [self.session subscribeToTopicV5:TOPIC
                             atLevel:qos
                             noLocal:NO
                   retainAsPublished:NO
                      retainHandling:MQTTDontSendRetained
              subscriptionIdentifier:0
                      userProperties:nil
                    subscribeHandler:^(NSError * _Nullable error, NSString * _Nullable reasonString, NSArray<NSDictionary<NSString *,NSString *> *> * _Nullable userProperties, NSArray<NSNumber *> * _Nullable reasonCodes) {
                        done = true;
                    }];

    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.timedout = FALSE;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:[self.parameters[@"timeout"] intValue]];

    while (!done && !self.timedout && self.session.status == MQTTSessionStatusConnected) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }

    done = false;
    [self.session publishDataV5:[@".123456789.123456789.123456789.123456789.123456789.123456789.123456789.123456789.123456789.123456789.123456789.123456789.123456789.123456789.123456789" dataUsingEncoding:NSUTF8StringEncoding]
                        onTopic:TOPIC
                         retain:false
                            qos:qos
         payloadFormatIndicator:nil
          messageExpiryInterval:nil
                     topicAlias:nil
                  responseTopic:nil
                correlationData:nil
                 userProperties:nil
                    contentType:nil
                 publishHandler:^(NSError * _Nullable error, NSString * _Nullable reasonString, NSArray<NSDictionary<NSString *,NSString *> *> * _Nullable userProperties, NSNumber * _Nullable reasonCode) {
                     done = true;
                 }];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.timedout = FALSE;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:[self.parameters[@"timeout"] intValue]];

    while (!done && !self.timedout && self.session.status == MQTTSessionStatusConnected) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }

    done = false;
    [self.session publishDataV5:[@".123456789" dataUsingEncoding:NSUTF8StringEncoding]
                        onTopic:TOPIC
                         retain:false
                            qos:qos
         payloadFormatIndicator:nil
          messageExpiryInterval:nil
                     topicAlias:nil
                  responseTopic:nil
                correlationData:nil
                 userProperties:nil
                    contentType:nil
                 publishHandler:^(NSError * _Nullable error, NSString * _Nullable reasonString, NSArray<NSDictionary<NSString *,NSString *> *> * _Nullable userProperties, NSNumber * _Nullable reasonCode) {
                     done = true;
                 }];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.timedout = FALSE;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:[self.parameters[@"timeout"] intValue]];

    while (!done && !self.timedout && self.session.status == MQTTSessionStatusConnected) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }

    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.timedout = FALSE;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:3];

    while (!self.timedout && self.session.status == MQTTSessionStatusConnected) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }

    XCTAssertEqual(self.newMessages, 1, @"Did not receive 1 message but %ld messages",
                   (long)self.newMessages);

    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}

- (void)test_v5_mPS_userProperties_q0 {
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self v5_mPS_userProperties:MQTTQosLevelAtMostOnce];
}

- (void)test_v5_mPS_userProperties_q1 {
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self v5_mPS_userProperties:MQTTQosLevelAtLeastOnce];
}

- (void)test_v5_mPS_userProperties_q2 {
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self v5_mPS_userProperties:MQTTQosLevelExactlyOnce];
}

- (void)v5_mPS_userProperties:(MQTTQosLevel)qos {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    self.session.requestProblemInformation = @1U;
    self.session.maximumPacketSize = @128U;
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    if (self.session.maximumQoS && self.session.maximumQoS.integerValue < qos) {
        return;
    }

    __block BOOL done;

    self.newMessages = 0;
    self.retainedMessages = 0;

    done = false;
    [self.session publishDataV5:[[NSData alloc] init]
                        onTopic:TOPIC
                         retain:true
                            qos:qos
         payloadFormatIndicator:nil
          messageExpiryInterval:nil
                     topicAlias:nil
                  responseTopic:nil
                correlationData:nil
                 userProperties:nil
                    contentType:nil
                 publishHandler:^(NSError * _Nullable error, NSString * _Nullable reasonString, NSArray<NSDictionary<NSString *,NSString *> *> * _Nullable userProperties, NSNumber * _Nullable reasonCode) {
                     done = true;
                 }];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.timedout = FALSE;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:[self.parameters[@"timeout"] intValue]];

    while (!done && !self.timedout && self.session.status == MQTTSessionStatusConnected) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }

    done = false;
    [self.session subscribeToTopicV5:TOPIC
                             atLevel:qos
                             noLocal:NO
                   retainAsPublished:NO
                      retainHandling:MQTTDontSendRetained
              subscriptionIdentifier:0
                      userProperties:nil
                    subscribeHandler:^(NSError * _Nullable error, NSString * _Nullable reasonString, NSArray<NSDictionary<NSString *,NSString *> *> * _Nullable userProperties, NSArray<NSNumber *> * _Nullable reasonCodes) {
                        done = true;
                    }];

    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.timedout = FALSE;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:[self.parameters[@"timeout"] intValue]];

    while (!done && !self.timedout && self.session.status == MQTTSessionStatusConnected) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }


    done = false;
    [self.session publishDataV5:[[NSData alloc] init]
                        onTopic:TOPIC
                         retain:false
                            qos:qos
         payloadFormatIndicator:nil
          messageExpiryInterval:nil
                     topicAlias:nil
                  responseTopic:nil
                correlationData:nil
                 userProperties:@[@{@"userProperty1": @"userPropertyValue1"},
                                  @{@"userProperty2": @"userPropertyValue2"},
                                  @{@"userProperty3": @"userPropertyValue3"},
                                  @{@"userProperty4": @"userPropertyValue4"}
                                  ]
                    contentType:nil
                 publishHandler:^(NSError * _Nullable error, NSString * _Nullable reasonString, NSArray<NSDictionary<NSString *,NSString *> *> * _Nullable userProperties, NSNumber * _Nullable reasonCode) {
                     done = true;
                 }];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.timedout = FALSE;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:[self.parameters[@"timeout"] intValue]];

    while (!done && !self.timedout && self.session.status == MQTTSessionStatusConnected) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }

    done = false;
    [self.session publishDataV5:[@".123456789" dataUsingEncoding:NSUTF8StringEncoding]
                        onTopic:TOPIC
                         retain:false
                            qos:qos
         payloadFormatIndicator:nil
          messageExpiryInterval:nil
                     topicAlias:nil
                  responseTopic:nil
                correlationData:nil
                 userProperties:nil
                    contentType:nil
                 publishHandler:^(NSError * _Nullable error, NSString * _Nullable reasonString, NSArray<NSDictionary<NSString *,NSString *> *> * _Nullable userProperties, NSNumber * _Nullable reasonCode) {
                     done = true;
                 }];

    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.timedout = FALSE;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:[self.parameters[@"timeout"] intValue]];

    while (!done && !self.timedout && self.session.status == MQTTSessionStatusConnected) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }


    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.timedout = FALSE;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:3];

    while (!self.timedout && self.session.status == MQTTSessionStatusConnected) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }

    XCTAssertEqual(self.newMessages, 1, @"Did not receive 1 message but %ld messages",
                   (long)self.newMessages);

    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}

- (void)test_v5_willDelayInterval_30 {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    self.session.sessionExpiryInterval = @10U;
    self.session.will = [[MQTTWill alloc] initWithTopic:TOPIC
                                                   data:[@"will" dataUsingEncoding:NSUTF8StringEncoding]
                                             retainFlag:false
                                                    qos:(MQTTQosLevel)MQTTQosLevelAtMostOnce
                                      willDelayInterval:@30
                                 payloadFormatIndicator:nil
                                  messageExpiryInterval:nil
                                            contentType:nil
                                          responseTopic:nil
                                        correlationData:nil
                                         userProperties:nil];
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    [self shutdownWithReturnCode:MQTTDisconnectWithWillMessage
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}

- (void)test_v5_willPayloadIndicator {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    self.session.sessionExpiryInterval = @10U;
    self.session.will = [[MQTTWill alloc] initWithTopic:TOPIC
                                                   data:[@"will" dataUsingEncoding:NSUTF8StringEncoding]
                                             retainFlag:false
                                                    qos:(MQTTQosLevel)MQTTQosLevelAtMostOnce
                                      willDelayInterval:nil
                                 payloadFormatIndicator:@0
                                  messageExpiryInterval:nil
                                            contentType:nil
                                          responseTopic:nil
                                        correlationData:nil
                                         userProperties:nil];
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    [self shutdownWithReturnCode:MQTTDisconnectWithWillMessage
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}

- (void)test_v5_willContentType {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    self.session.sessionExpiryInterval = @10U;
    self.session.will = [[MQTTWill alloc] initWithTopic:TOPIC
                                                   data:[@"will" dataUsingEncoding:NSUTF8StringEncoding]
                                             retainFlag:false
                                                    qos:(MQTTQosLevel)MQTTQosLevelAtMostOnce
                                      willDelayInterval:nil
                                 payloadFormatIndicator:nil
                                  messageExpiryInterval:nil
                                            contentType:@"Content-Type"
                                          responseTopic:nil
                                        correlationData:nil
                                         userProperties:nil];
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    [self shutdownWithReturnCode:MQTTDisconnectWithWillMessage
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}

- (void)test_v5_willResponseTopic {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    self.session.sessionExpiryInterval = @10U;
    self.session.will = [[MQTTWill alloc] initWithTopic:TOPIC
                                                   data:[@"will" dataUsingEncoding:NSUTF8StringEncoding]
                                             retainFlag:false
                                                    qos:(MQTTQosLevel)MQTTQosLevelAtMostOnce
                                      willDelayInterval:nil
                                 payloadFormatIndicator:nil
                                  messageExpiryInterval:nil
                                            contentType:nil
                                          responseTopic:@"Respose Topic"
                                        correlationData:[@"Correlation Data" dataUsingEncoding:NSUTF8StringEncoding]
                                         userProperties:nil];
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    [self shutdownWithReturnCode:MQTTDisconnectWithWillMessage
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}

- (void)test_v5_willUserProperties {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    self.session.sessionExpiryInterval = @10U;
    self.session.will = [[MQTTWill alloc] initWithTopic:TOPIC
                                                   data:[@"will" dataUsingEncoding:NSUTF8StringEncoding]
                                             retainFlag:false
                                                    qos:(MQTTQosLevel)MQTTQosLevelAtMostOnce
                                      willDelayInterval:nil
                                 payloadFormatIndicator:nil
                                  messageExpiryInterval:nil
                                            contentType:nil
                                          responseTopic:nil
                                        correlationData:nil
                                         userProperties:@[@{@"Prop1": @"Value1"}]];
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    [self shutdownWithReturnCode:MQTTDisconnectWithWillMessage
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}


- (void)test_v5_willDelayInterval_30_hard {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    self.session.sessionExpiryInterval = @10U;
    self.session.will = [[MQTTWill alloc] initWithTopic:TOPIC
                                                   data:[@"will" dataUsingEncoding:NSUTF8StringEncoding]
                                             retainFlag:false
                                                    qos:(MQTTQosLevel)MQTTQosLevelAtMostOnce
                                      willDelayInterval:@30
                                 payloadFormatIndicator:nil
                                  messageExpiryInterval:nil
                                            contentType:nil
                                          responseTopic:nil
                                        correlationData:nil
                                         userProperties:nil];
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
}

- (void)test_v5_willDelayInterval_0 {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    self.session.sessionExpiryInterval = @5U;
    self.session.will = [[MQTTWill alloc] initWithTopic:TOPIC
                                                   data:[@"will" dataUsingEncoding:NSUTF8StringEncoding]
                                             retainFlag:false
                                                    qos:(MQTTQosLevel)MQTTQosLevelAtMostOnce
                                      willDelayInterval:@0
                                 payloadFormatIndicator:nil
                                  messageExpiryInterval:nil
                                            contentType:nil
                                          responseTopic:nil
                                        correlationData:nil
                                         userProperties:nil];
    
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    [self shutdownWithReturnCode:MQTTDisconnectWithWillMessage
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}

- (void)test_v5_willDelayInterval_None {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    self.session.will = [[MQTTWill alloc] initWithTopic:TOPIC
                                                   data:[@"will" dataUsingEncoding:NSUTF8StringEncoding]
                                             retainFlag:false
                                                    qos:(MQTTQosLevel)MQTTQosLevelAtMostOnce
                                      willDelayInterval:nil
                                 payloadFormatIndicator:nil
                                  messageExpiryInterval:nil
                                            contentType:nil
                                          responseTopic:nil
                                        correlationData:nil
                                         userProperties:nil];
    
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    [self shutdownWithReturnCode:MQTTDisconnectWithWillMessage
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}

- (void)test_maximumQos_available {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);

    DDLogInfo(@"Server Maximum QoS: %@", self.session.maximumQoS);
    MQTTQosLevel qos = MQTTQosLevelExactlyOnce;
    if (self.session.maximumQoS) {
        qos = self.session.maximumQoS.integerValue;
    }
    XCTAssertEqual(qos, MQTTQosLevelExactlyOnce, @"No MQTTQosLevelExactlyOnce %d", qos);

    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}

- (void)test_retain_available {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);

    DDLogInfo(@"Server Retain Available: %@", self.session.retainAvailable);
    BOOL retain = TRUE;
    if (self.session.retainAvailable) {
        retain = self.session.retainAvailable.boolValue;
    }
    XCTAssertEqual(retain, TRUE, @"No retainAvailable %d", retain);

    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}

- (void)test_wildcardAvailable_available {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);

    DDLogInfo(@"Server Wildcard Subcription Available: %@", self.session.wildcardSubscriptionAvailable);
    BOOL wildcard = TRUE;
    if (self.session.wildcardSubscriptionAvailable) {
        wildcard = self.session.wildcardSubscriptionAvailable.boolValue;
    }
    XCTAssertEqual(wildcard, TRUE, @"No wildcardSubscriptionAvailable %d", wildcard);

    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}

@end
