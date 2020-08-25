//
//  MultiThreadingTests.m
//  MQTTClient
//
//  Created by Christoph Krey on 08.07.14.
//  Copyright © 2014-2020 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "MQTTTestHelpers.h"

@interface OneTest : NSObject <MQTTSessionDelegate>
@property (strong, nonatomic) MQTTSession *session;
@property (nonatomic) NSInteger event;
@property (strong, nonatomic) NSError *error;
@property (strong, nonatomic) NSDictionary *parameters;
@end

@implementation OneTest

- (id)setup:(MQTTTestHelpers *)helpers {
    self.parameters = helpers.parameters;
    self.session = [helpers newSession];
    self.session.delegate = self;
    return self;
}

- (BOOL)runSync {
    DDLogVerbose(@"%@ connecting", self.session.clientId);
    __block NSNumber *result = nil;
    
    [self.session connectWithConnectHandler:^(NSError *error) {
        if (!error) {
            [self.session subscribeToTopicV5:@"#"
                                     atLevel:MQTTQosLevelAtLeastOnce
                                     noLocal:NO
                           retainAsPublished:NO
                              retainHandling:MQTTSendRetained
                      subscriptionIdentifier:0
                              userProperties:nil
                            subscribeHandler:^(NSError *error, NSString *reasonString, NSArray<NSDictionary<NSString *,NSString *> *> *userProperties, NSArray<NSNumber *> *reasonCodes) {
                if (!error) {
                    [self.session publishDataV5:[@"data" dataUsingEncoding:NSUTF8StringEncoding]
                                        onTopic:TOPIC
                                         retain:NO
                                            qos:MQTTQosLevelExactlyOnce
                         payloadFormatIndicator:nil
                          messageExpiryInterval:nil
                                     topicAlias:nil
                                  responseTopic:nil
                                correlationData:nil
                                 userProperties:nil
                                    contentType:nil
                                 publishHandler:
                     ^(NSError *error,
                       NSString *reasonString,
                       NSArray<NSDictionary<NSString *,NSString *> *> *userProperties,
                       NSNumber *reasonCode,
                       UInt16 msgID) {
                        [self.session closeWithReturnCode:0
                                    sessionExpiryInterval:nil
                                             reasonString:nil
                                           userProperties:nil
                                        disconnectHandler:nil];
                        if (!error) {
                            result = @(TRUE);
                        } else {
                            result = @(FALSE);
                        }
                    }
                     ];
                    
                } else {
                    [self.session closeWithReturnCode:0
                                sessionExpiryInterval:nil
                                         reasonString:nil
                                       userProperties:nil
                                    disconnectHandler:nil];
                    result = @(FALSE);
                }
            }];
        } else {
            result = @(FALSE);
        }
    }];
    
    NSDate *start = [NSDate date];
    while (!result) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        if ([NSDate date].timeIntervalSince1970 > start.timeIntervalSince1970 + 10) {
            result = @(FALSE);
        }
    }
    return result.boolValue;
}

- (void)start {
    self.event = -1;
    [self.session connectWithConnectHandler:nil];
    DDLogVerbose(@"%@ connecting", self.session.clientId);
}

- (void)sub {
    self.event = -1;
    [self.session subscribeToTopicV5:@"MQTTClient/#"
                             atLevel:MQTTQosLevelAtLeastOnce
                             noLocal:NO
                   retainAsPublished:NO
                      retainHandling:MQTTSendRetained
              subscriptionIdentifier:0
                      userProperties:nil
                    subscribeHandler:nil];
}

- (void)pub {
    self.event = -1;
    [self.session publishDataV5:[@"data" dataUsingEncoding:NSUTF8StringEncoding]
                        onTopic:TOPIC
                         retain:NO
                            qos:MQTTQosLevelExactlyOnce
         payloadFormatIndicator:nil
          messageExpiryInterval:nil
                     topicAlias:nil
                  responseTopic:nil
                correlationData:nil
                 userProperties:nil
                    contentType:nil
                 publishHandler:nil];
}

- (void)close {
    self.event = -1;
    [self.session closeWithReturnCode:MQTTSuccess
                sessionExpiryInterval:nil
                         reasonString:nil
                       userProperties:nil
                    disconnectHandler:nil];
}

- (void)stop {
    self.session.delegate = nil;
    self.session = nil;
}

- (void)subAckReceivedV5:(MQTTSession *)session msgID:(UInt16)msgID reasonString:(NSString *)reasonString userProperties:(NSArray<NSDictionary<NSString *,NSString *> *> *)userProperties reasonCodes:(NSArray<NSNumber *> *)reasonCodes {
    self.event = 999;
}

- (void)messageDeliveredV5:(MQTTSession *)session msgID:(UInt16)msgID topic:(NSString *)topic data:(NSData *)data qos:(MQTTQosLevel)qos retainFlag:(BOOL)retainFlag payloadFormatIndicator:(NSNumber *)payloadFormatIndicator messageExpiryInterval:(NSNumber *)messageExpiryInterval topicAlias:(NSNumber *)topicAlias responseTopic:(NSString *)responseTopic correlationData:(NSData *)correlationData userProperties:(NSArray<NSDictionary<NSString *,NSString *> *> *)userProperties contentType:(NSString *)contentType {
    self.event = 999;
}

- (void)newMessageV5:(MQTTSession *)session data:(NSData *)data onTopic:(NSString *)topic qos:(MQTTQosLevel)qos retained:(BOOL)retained mid:(unsigned int)mid payloadFormatIndicator:(NSNumber *)payloadFormatIndicator messageExpiryInterval:(NSNumber *)messageExpiryInterval topicAlias:(NSNumber *)topicAlias responseTopic:(NSString *)responseTopic correlationData:(NSData *)correlationData userProperties:(NSArray<NSDictionary<NSString *,NSString *> *> *)userProperties contentType:(NSString *)contentType subscriptionIdentifiers:(NSArray<NSNumber *> *)subscriptionIdentifiers {
    //DDLogVerbose(@"newMessage:%@ onTopic:%@ qos:%d retained:%d mid:%d", data, topic, qos, retained, mid);
}

- (void)handleEvent:(MQTTSession *)session event:(MQTTSessionEvent)eventCode error:(NSError *)error {
    //DDLogVerbose(@"handleEvent:%ld error:%@", eventCode, error);
    self.event = eventCode;
    self.error = error;
}

@end

@interface MQTTTestMultiThreading : MQTTTestHelpers

@end

@implementation MQTTTestMultiThreading

- (void)setUp {
    [super setUp];
    [MQTTLog setLogLevel:DDLogLevelInfo];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testAsync {
    [self runAsync];
}

- (void)testSync {
    [self runSync];
}

- (void)testMultiConnect {
    NSMutableArray *connections = [[NSMutableArray alloc] initWithCapacity:MULTI];
    
    for (int i = 0; i < MULTI; i++) {
        OneTest *oneTest = [[OneTest alloc] init];
        [connections addObject:oneTest];
    }
    
    for (OneTest *oneTest in connections) {
        [oneTest setup:self];
    }
    
    for (OneTest *oneTest in connections) {
        [oneTest start];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    
    for (OneTest *oneTest in connections) {
        XCTAssertEqual(oneTest.event, MQTTSessionEventConnected, @"%@ Not Connected %ld %@", oneTest.session.clientId, (long)oneTest.event, oneTest.error);
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    
    for (OneTest *oneTest in connections) {
        [oneTest sub];
    }
    
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:10]];
    
    for (OneTest *oneTest in connections) {
        [oneTest pub];
    }
    
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:10]];
    
    for (OneTest *oneTest in connections) {
        [oneTest close];
    }
    
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:10]];
    
    for (OneTest *oneTest in connections) {
        [oneTest stop];
    }
}

- (void)testAsyncThreads {
    NSMutableArray *threads = [[NSMutableArray alloc] initWithCapacity:MULTI];
    
    for (int i = 0; i < MULTI; i++) {
        NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(runAsync) object:nil];
        [threads addObject:thread];
    }
    
    for (NSThread *thread in threads) {
        [thread start];
    }
    
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:10]];
    
    for (NSThread *thread in threads) {
        [thread cancel];
    }
}

- (void)testSyncThreads {
    NSMutableArray *threads = [[NSMutableArray alloc] initWithCapacity:MULTI];
    
    for (int i = 0; i < MULTI; i++) {
        NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(runSync) object:nil];
        [threads addObject:thread];
    }
    
    for (NSThread *thread in threads) {
        [thread start];
    }
    
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:10]];
    
    for (NSThread *thread in threads) {
        [thread cancel];
    }
}

- (void)runAsync {
    OneTest *test = [[OneTest alloc] init];
    [test setup:self];
    [test start];
    
    while (test.event == -1) {
        //DDLogVerbose(@"waiting for connection");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    
    XCTAssertEqual(test.event, MQTTSessionEventConnected, @"%@ Not Connected %ld %@", test.session.clientId, (long)test.event, test.error);
    
    if (test.session.status == MQTTSessionStatusConnected) {
        
        [test sub];
        
        while (test.event == -1) {
            //DDLogVerbose(@"%@ waiting for suback", test.session.clientId);
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        
        [test pub];
        
        while (test.event == -1) {
            //DDLogVerbose(@"%@ waiting for puback", test.session.clientId);
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        
        [test close];
        
        while (test.event == -1) {
            //DDLogVerbose(@"%@ waiting for close", test.session.clientId);
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
    }
    
    [test stop];
}

- (void)runSync {
    OneTest *test = [[OneTest alloc] init];
    [test setup:self];
    
    if (![test runSync]) {
        XCTFail(@"%@ Not Connected %ld %@", test.session.clientId, (long)test.event, test.error);
    }
}


@end
