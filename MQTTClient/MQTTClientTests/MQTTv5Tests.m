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
@end

@implementation MQTTv5Tests

- (void)test_complete_v5 {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
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

- (void)test_v5_mPS {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    self.session.requestProblemInformation = @1U;
    self.session.maximumPacketSize = @128U;
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);

    __block BOOL done;

    self.newMessages = 0;
    self.retainedMessages = 0;
    done = false;
    [self.session subscribeToTopicV5:TOPIC
                             atLevel:MQTTQosLevelAtLeastOnce
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

    while (!done && !self.timedout) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }


    done = false;
    [self.session publishDataV5:[[NSData alloc] init]
                          onTopic:TOPIC
                           retain:false
                              qos:MQTTQosLevelAtLeastOnce
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

    while (!done && !self.timedout) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }

    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.timedout = FALSE;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:3];

    while (!self.timedout) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }

    XCTAssertEqual(self.newMessages, 1, @"Did not receive 1 message but %ld messages",
                   (long)self.newMessages);

    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}

- (void)test_v5_sessionExpiryInterval_5 {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    self.session.sessionExpiryInterval = @5U;
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}

- (void)test_v5_sessionExpiryInterval_0 {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    self.session.sessionExpiryInterval = @0U;
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}

- (void)test_v5_sessionExpiryInterval_none {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}

- (void)test_v5_willDelayInterval_5 {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
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

- (void)test_v5_willDelayInterval_0 {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
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

@end
