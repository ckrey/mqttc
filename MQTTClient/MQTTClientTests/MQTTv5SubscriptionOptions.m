//
//  MQTTv5SubscriptionOptions.m
//  MQTTClient
//
//  Created by Christoph Krey on 23.07.18.
//  Copyright ©2018-2020 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MQTTLog.h"
#import "MQTTTestHelpers.h"

@interface MQTTv5SubscriptionOptions : MQTTTestHelpers

@end

@implementation MQTTv5SubscriptionOptions

- (void)setUp {
    [super setUp];
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    
    [MQTTLog setLogLevel:DDLogLevelVerbose];
    
    self.session = [self newSession];
    self.session.clientId = @"MQTTv5SOb";
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
    
    DDLogInfo(@"Publish 1");
    
    done = false;
    [self.session publishDataV5:[[NSData alloc] init]
                        onTopic:@"MQTTv5SO/empty"
                         retain:true
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
       UInt16 msgId) {
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
    
    DDLogInfo(@"Publish 2");
    done = false;
    [self.session publishDataV5:[@"full" dataUsingEncoding:NSUTF8StringEncoding]
                        onTopic:@"MQTTv5SO/full"
                         retain:true
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
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)test_local {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    [self test_any:FALSE retainAsPublished:FALSE retainHandling:MQTTSendRetained];
}

- (void)test_nolocal {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    [self test_any:TRUE retainAsPublished:FALSE retainHandling:MQTTSendRetained];
}

- (void)test_retainAsPublished {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    [self test_any:FALSE retainAsPublished:TRUE retainHandling:MQTTSendRetained];
}

- (void)test_sendRetainedIfNotYetSubscribed {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    [self test_any:FALSE retainAsPublished:FALSE retainHandling:MQTTSendRetainedIfNotYetSubscribed];
}

- (void)test_dontSendRetained {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    [self test_any:FALSE retainAsPublished:FALSE retainHandling:MQTTDontSendRetained];
}


- (void)test_any:(BOOL)nolocal
retainAsPublished:(BOOL)retainAsPublished
  retainHandling:(MQTTRetainHandling)retainHandling {
    self.session = [self newSession];
    self.session.clientId = @"MQTTv5SOb";
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
    
    DDLogInfo(@"Subscribing 1");
    done = false;
    [self.session subscribeToTopicV5:@"MQTTv5SO/+"
                             atLevel:MQTTQosLevelAtMostOnce
                             noLocal:nolocal
                   retainAsPublished:retainAsPublished
                      retainHandling:retainHandling
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
    
    DDLogInfo(@"Subscribing 2");
    done = false;
    [self.session subscribeToTopicV5:@"MQTTv5SO/+"
                             atLevel:MQTTQosLevelAtMostOnce
                             noLocal:nolocal
                   retainAsPublished:retainAsPublished
                      retainHandling:retainHandling
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
    
    DDLogInfo(@"Publishing");
    done = false;
    [self.session publishDataV5:[@"local" dataUsingEncoding:NSUTF8StringEncoding]
                        onTopic:@"MQTTv5SO/empty"
                         retain:true
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
    
    DDLogInfo(@"Waiting");
    
    NSInteger expectedNewMessages = 3;
    if (nolocal) {
        expectedNewMessages -= 1;
    }
    if (retainHandling == MQTTSendRetainedIfNotYetSubscribed) {
        expectedNewMessages -= 1;
    }
    if (retainHandling == MQTTDontSendRetained) {
        expectedNewMessages -= 2;
    }
    
    NSInteger expectedRetainedMessages = 2;
    if (retainAsPublished) {
        expectedRetainedMessages += 1;
    }
    if (retainHandling == MQTTSendRetainedIfNotYetSubscribed) {
        expectedRetainedMessages -= 1;
    }
    if (retainHandling == MQTTDontSendRetained) {
        expectedRetainedMessages -= 2;
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.timedout = FALSE;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:3];
    
    while (!self.timedout) {
        DDLogInfo(@"Waiting for newMessages %ld/%ld retainedMessages %ld/%ld",
                  self.newMessages, (long)expectedNewMessages,
                  self.retainedMessages, (long)expectedRetainedMessages);
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    
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
    
    XCTAssertEqual(self.newMessages, expectedNewMessages,
                   "Did not receive correct number of messages (%ld/%ld)",
                   (long)self.newMessages, (long)expectedNewMessages);
    
    XCTAssertEqual(self.retainedMessages, expectedRetainedMessages,
                   "Did not receive correct number of retained messages (%ld/%ld)",
                   (long)self.retainedMessages, (long)expectedRetainedMessages);
    
}

@end
