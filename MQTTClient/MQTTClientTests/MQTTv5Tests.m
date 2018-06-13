//
//  MQTTv5Tests.m
//  MQTTClientTests
//
//  Created by Christoph Krey on 13.01.14.
//  Copyright © 2014-2018 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "MQTTLog.h"
#import "MQTTTestHelpers.h"
#import "MQTTCFSocketTransport.h"

@interface MQTTv5Tests : MQTTTestHelpers
@property (nonatomic) BOOL ungraceful;
@property (nonatomic) int sent;
@property (nonatomic) int received;
@property (nonatomic) int processed;

@end

@implementation MQTTv5Tests

- (void)test_complete_v5 {
    if ([self.parameters[@"protocollevel"] integerValue] == MQTTProtocolVersion50) {
        self.session.authHandler = authHandler;
        self.session.sessionExpiryInterval = @60U;
        self.session.authMethod = @"method1";
        self.session.authData = [@"client1" dataUsingEncoding:NSUTF8StringEncoding];
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
}

- (void)test_extended_auth_fail {
    if ([self.parameters[@"protocollevel"] integerValue] == MQTTProtocolVersion50) {
        self.session.authHandler = authHandler;
        self.session.authMethod = @"methodX";
        self.session.authData = [@"clientX" dataUsingEncoding:NSUTF8StringEncoding];
        [self connect];
        XCTAssertEqual(self.event, MQTTSessionEventConnectionClosedByBroker, @"Not Disconnected %ld %@", (long)self.event, self.error);
        [self shutdownWithReturnCode:MQTTSuccess
               sessionExpiryInterval:nil
                        reasonString:nil
                      userProperties:nil];
    }
}

- (void)test_extended_auth_baddata {
    if ([self.parameters[@"protocollevel"] integerValue] == MQTTProtocolVersion50) {
        self.session.authHandler = authHandler;
        self.session.authMethod = @"method1";
        self.session.authData = [@"baddata" dataUsingEncoding:NSUTF8StringEncoding];
        [self connect];
        XCTAssertEqual(self.event, MQTTSessionEventConnectionRefused, @"Not Refused %ld %@", (long)self.event, self.error);
        XCTAssertEqual(self.error.code, MQTTNotAuthorized, @"reason code other than not authorized");
        [self shutdownWithReturnCode:MQTTSuccess
               sessionExpiryInterval:nil
                        reasonString:nil
                      userProperties:nil];
    }
}

- (void)test_extended_auth {
    if ([self.parameters[@"protocollevel"] integerValue] == MQTTProtocolVersion50) {
        self.session.authHandler = authHandler;
        self.session.authMethod = @"method1";
        self.session.authData = [@"client1" dataUsingEncoding:NSUTF8StringEncoding];
        [self connect];
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
        [self shutdownWithReturnCode:MQTTSuccess
               sessionExpiryInterval:nil
                        reasonString:nil
                      userProperties:nil];
    }
}

- (void)test_extended_re_auth {
    if ([self.parameters[@"protocollevel"] integerValue] == MQTTProtocolVersion50) {
        self.session.authHandler = authHandler;
        self.session.authMethod = @"method1";
        self.session.authData = [@"client1" dataUsingEncoding:NSUTF8StringEncoding];
        [self connect];
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);

        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:3]];
        MQTTMessage *authMessage = [MQTTMessage authMessage:MQTTProtocolVersion50
                                                 returnCode:MQTTReAuthenticate
                                                 authMethod:@"method1"
                                                   authData:[@"client1" dataUsingEncoding:NSUTF8StringEncoding]
                                               reasonString:@"re-authentication test"
                                             userProperties:@[@{@"test-suite":@"mqttc"},
                                                              @{@"request":@"re-authenticate"}]];
        [self.session encode:authMessage];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:3]];

        [self shutdownWithReturnCode:MQTTSuccess
               sessionExpiryInterval:nil
                        reasonString:nil
                      userProperties:nil];
    }
}

MQTTAuthHandler authHandler =  ^(MQTTSession * _Nonnull session,
                                 NSNumber * _Nonnull reasonCode,
                                 NSString * _Nullable authMethod,
                                 NSData * _Nullable authData,
                                 NSString * _Nullable reasonString,
                                 NSArray <NSDictionary <NSString *, NSString *> *> * _Nullable userProperties) {
    DDLogVerbose(@"[authHandler] rC=%@ aM=%@ aD=%@ rS=%@ uP=%@",
                 reasonCode,
                 authMethod,
                 authData,
                 reasonString,
                 userProperties);

    if (reasonCode.unsignedIntValue == MQTTContinueAuthentication) {
        MQTTMessage *authMessage = [MQTTMessage authMessage:MQTTProtocolVersion50
                                                 returnCode:MQTTContinueAuthentication
                                                 authMethod:@"method1"
                                                   authData:[@"client2" dataUsingEncoding:NSUTF8StringEncoding]
                                               reasonString:nil
                                             userProperties:nil];
        (void)[session encode:authMessage];
    }

};

- (void)test_authMethod_v5 {
    if ([self.parameters[@"protocollevel"] integerValue] == MQTTProtocolVersion50) {
        self.session.authMethod = @"method";
        self.session.authData = [@"data" dataUsingEncoding:NSUTF8StringEncoding];
        [self connect];
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
        [self shutdownWithReturnCode:MQTTSuccess
               sessionExpiryInterval:nil
                        reasonString:nil
                      userProperties:nil];
    }
}

- (void)test_v5_sessionExpiryInterval_5 {
    if ([self.parameters[@"protocollevel"] integerValue] == MQTTProtocolVersion50) {
        self.session.sessionExpiryInterval = @5U;
        [self connect];
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
        [self shutdownWithReturnCode:MQTTSuccess
               sessionExpiryInterval:nil
                        reasonString:nil
                      userProperties:nil];
    }
}

- (void)test_v5_sessionExpiryInterval_0 {
    if ([self.parameters[@"protocollevel"] integerValue] == MQTTProtocolVersion50) {
        self.session.sessionExpiryInterval = @0U;
        [self connect];
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
        [self shutdownWithReturnCode:MQTTSuccess
               sessionExpiryInterval:nil
                        reasonString:nil
                      userProperties:nil];
    }
}

- (void)test_v5_sessionExpiryInterval_none {
    if ([self.parameters[@"protocollevel"] integerValue] == MQTTProtocolVersion50) {
        [self connect];
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
        [self shutdownWithReturnCode:MQTTSuccess
               sessionExpiryInterval:nil
                        reasonString:nil
                      userProperties:nil];
    }
}

- (void)test_v5_willDelayInterval_5 {
    if ([self.parameters[@"protocollevel"] integerValue] == MQTTProtocolVersion50) {
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
}

- (void)test_v5_willDelayInterval_0 {
    if ([self.parameters[@"protocollevel"] integerValue] == MQTTProtocolVersion50) {
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
}

- (void)test_v5_willDelayInterval_None {
    if ([self.parameters[@"protocollevel"] integerValue] == MQTTProtocolVersion50) {
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
}

#pragma mark helpers

- (void)no_cleansession:(MQTTQosLevel)qos {
    DDLogVerbose(@"Cleaning topic");

    MQTTSession *sendingSession = [self newSession];
    sendingSession.clientId = @"MQTTClient-pub";

    __block BOOL done;
    done = false;
    [sendingSession connectWithConnectHandler:^(NSError *error) {
        done = true;
    }];

    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.timedout = FALSE;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:[self.parameters[@"timeout"] intValue]];

    while (!done && !self.timedout) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }

    done = false;
    [sendingSession publishDataV5:[[NSData alloc] init]
                          onTopic:TOPIC
                           retain:TRUE
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

    while (!done && !self.timedout) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }

    DDLogVerbose(@"Clearing old subs");
    self.session = [self newSession];
    self.session.clientId = @"MQTTClient-sub";
    [self connect];
    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];

    DDLogVerbose(@"Subscribing to topic");
    self.session = [self newSession];
    self.session.clientId = @"MQTTClient-sub";
    self.session.cleanSessionFlag = FALSE;

    [self connect];

    done = false;
    [self.session subscribeToTopicV5:TOPIC
                             atLevel:qos
                             noLocal:NO
                   retainAsPublished:NO
                      retainHandling:MQTTSendRetained
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

    while (!done && !self.timedout) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }

    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];

    for (int i = 1; i < BULK; i++) {
        DDLogVerbose(@"publishing to topic %d", i);
        NSString *payload = [NSString stringWithFormat:@"payload %d", i];
        done = false;
        [sendingSession publishDataV5:[payload dataUsingEncoding:NSUTF8StringEncoding]
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

        while (!done && !self.timedout) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
    }
    done = false;
    [sendingSession closeWithReturnCode:MQTTSuccess
                  sessionExpiryInterval:nil
                           reasonString:nil
                         userProperties:nil
                      disconnectHandler:^(NSError * _Nullable error) {
                          done = true;
                      }];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.timedout = FALSE;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:[self.parameters[@"timeout"] intValue]];

    while (!done && !self.timedout) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }

    DDLogVerbose(@"receiving from topic");
    self.session = [self newSession];
    self.session.clientId = @"MQTTClient-sub";
    self.session.cleanSessionFlag = FALSE;

    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"No MQTTSessionEventConnected %@", self.error);

    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.timedout = FALSE;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:[self.parameters[@"timeout"] intValue]];

    while (!self.timedout) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }

    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}

- (void)cleansession:(MQTTQosLevel)qos {
    DDLogVerbose(@"Cleaning topic");
    MQTTSession *sendingSession = [self newSession];
    sendingSession.clientId = @"MQTTClient-pub";

    __block BOOL done;
    done = false;
    [sendingSession connectWithConnectHandler:^(NSError * _Nullable error) {
        done = true;
        if (error) {
            XCTFail(@"no connection for pub");
        }
    }];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.timedout = FALSE;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:[self.parameters[@"timeout"] intValue]];

    while (!done && !self.timedout) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }

    [sendingSession publishDataV5:[[NSData alloc] init]
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

    while (!done && !self.timedout) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }

    DDLogVerbose(@"Clearing old subs");
    self.session = [self newSession];
    self.session.clientId = @"MQTTClient-sub";
    [self connect];
    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];

    DDLogVerbose(@"Subscribing to topic");
    self.session = [self newSession];
    self.session.clientId = @"MQTTClient-sub";
    [self connect];

    done = false;
    [self.session subscribeToTopicV5:TOPIC
                             atLevel:qos
                             noLocal:NO
                   retainAsPublished:NO
                      retainHandling:MQTTSendRetained
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

    while (!done && !self.timedout) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }

    for (int i = 1; i < BULK; i++) {
        DDLogVerbose(@"publishing to topic %d", i);
        NSString *payload = [NSString stringWithFormat:@"payload %d", i];
        done = false;
        [sendingSession publishDataV5:[payload dataUsingEncoding:NSUTF8StringEncoding]
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

        while (!done && !self.timedout) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }


    }
    done = false;
    [sendingSession closeWithReturnCode:MQTTSuccess
                  sessionExpiryInterval:nil
                           reasonString:nil
                         userProperties:nil
                      disconnectHandler:^(NSError * _Nullable error) {
                          done = true;
                      }];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.timedout = FALSE;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:[self.parameters[@"timeout"] intValue]];

    while (!done && !self.timedout) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }


    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.timedout = FALSE;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:[self.parameters[@"timeout"] intValue]];

    while (!self.timedout) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }

    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}

- (BOOL)newMessageWithFeedbackV5:(MQTTSession *)session
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
    DDLogVerbose(@"newMessageWithFeedback(%lu):%@ onTopic:%@ qos:%d retained:%d mid:%d",
                 (unsigned long)self.processed, data, topic, qos, retained, mid);
    if (self.processed > self.received - 10) {
        if (!retained && [topic isEqualToString:TOPIC]) {
            self.received++;
        }
        return true;
    } else {
        return false;
    }
}

- (void)connect {
    self.session.delegate = self;
    self.event = -1;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.timedout = FALSE;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:[self.parameters[@"timeout"] intValue]];
    
    [self.session connectWithConnectHandler:nil];
    
    while (!self.timedout && self.event == -1) {
        DDLogVerbose(@"waiting for connection");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
}

- (void)shutdownWithReturnCode:(MQTTReturnCode)returnCode
         sessionExpiryInterval:(NSNumber *)sessionExpiryInterval
                  reasonString:(NSString *)reasonString
                userProperties:(NSArray <NSDictionary <NSString *, NSString *> *> *)userProperties {
    if (!self.ungraceful) {
        self.event = -1;

        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        self.timedout = FALSE;
        [self performSelector:@selector(timedout:)
                   withObject:nil
                   afterDelay:[self.parameters[@"timeout"] intValue]];

        [self.session closeWithReturnCode:returnCode
                    sessionExpiryInterval:sessionExpiryInterval
                             reasonString:reasonString
                           userProperties:userProperties
                        disconnectHandler:nil];

        while (self.event == -1 && !self.timedout) {
            DDLogVerbose(@"waiting for disconnect");
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }

        XCTAssert(!self.timedout, @"timeout");
        [NSObject cancelPreviousPerformRequestsWithTarget:self];

        self.session.delegate = nil;
        self.session = nil;
    }
}

@end
