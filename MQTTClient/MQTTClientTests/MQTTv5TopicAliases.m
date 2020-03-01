//
//  MQTTv5TopicAliases.m
//  MQTTClient
//
//  Created by Christoph Krey on 24.07.18.
//  Copyright ©2018-2020 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MQTTLog.h"
#import "MQTTTestHelpers.h"

@interface MQTTv5TopicAliases : MQTTTestHelpers

@end

@implementation MQTTv5TopicAliases

- (void)setUp {
    [super setUp];
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }

    [MQTTLog setLogLevel:DDLogLevelVerbose];

    self.session = [self newSession];
    self.session.clientId = @"MQTTv5TA";
    self.session.topicAliasMaximum = @10;
    self.session.delegate = self;
    __block BOOL done;

    DDLogInfo(@"Connecting");
    done = false;
    [self.session connectWithConnectHandler:^(NSError * _Nullable error) {
        done = true;
        if (error) {
            XCTFail(@"no connection");
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

    DDLogInfo(@"Subscribing");
    done = false;
    [self.session subscribeToTopicV5:@"MQTTv5TA/#"
                             atLevel:MQTTQosLevelAtMostOnce
                             noLocal:FALSE
                   retainAsPublished:FALSE
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

    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)tearDown {
    __block BOOL done;

    DDLogInfo(@"Disconnecting");
    done = false;
    [self.session closeWithReturnCode:MQTTSuccess
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

    [super tearDown];
}

- (void)test_tA_available {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    DDLogInfo(@"Server Topic Alias Maximum: %ld", self.session.brokerTopicAliasMaximum.integerValue);
    if (self.session.brokerTopicAliasMaximum && self.session.brokerTopicAliasMaximum.integerValue > 0) {
    } else {
    }
}

- (void)test_receive {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    [self test_any:3 topics:13 sendTA:FALSE];
}

- (void)test_send {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }

    NSInteger topics = 0;
    if (self.session.brokerTopicAliasMaximum) {
        topics = self.session.brokerTopicAliasMaximum.integerValue;
    }
    [self test_any:3 topics:topics sendTA:TRUE];
}

- (void)test_any:(NSInteger)count topics:(NSInteger)topics sendTA:(BOOL)sendTA {
    __block BOOL done;
    NSInteger expectedNewMessages = count * topics;

    for (NSInteger t = 1; t <= topics; t++) {
        for (NSInteger c = 1; c <= count; c++) {
            DDLogInfo(@"Publishing %ld", (long)c);
            done = false;
            [self.session publishDataV5:[@"MQTTv5TA" dataUsingEncoding:NSUTF8StringEncoding]
                                onTopic:[NSString stringWithFormat:@"MQTTv5TA/%ld", (long)t]
                                 retain:false
                                    qos:MQTTQosLevelAtMostOnce
                 payloadFormatIndicator:nil
                  messageExpiryInterval:nil
                             topicAlias:sendTA ? [NSNumber numberWithInteger:t] : nil
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
    }
    DDLogInfo(@"Waiting");

    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.timedout = FALSE;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:3];

    while (!self.timedout) {
        DDLogInfo(@"Waiting for newMessages %ld/%ld",
                  self.newMessages, (long)expectedNewMessages);
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }

    [NSObject cancelPreviousPerformRequestsWithTarget:self];

    XCTAssertEqual(self.newMessages, expectedNewMessages,
                   "Did not receive correct number of messages (%ld/%ld)",
                   (long)self.newMessages, (long)expectedNewMessages);

}

@end
