//
//  MQTTTestHelpers.h
//  MQTTClient
//
//  Created by Christoph Krey on 09.12.15.
//  Copyright © 2015-2019 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

#import "MQTTSessionManager.h"

#define TOPIC @"MQTTClient"
#define MULTI 15 // some test servers are limited in concurrent sessions
#define BULK 100 // some test servers are limited in queue size
#define ALOT 256 // some test servers are limited in queue size

@interface MQTTTestHelpers : XCTestCase <MQTTSessionDelegate, MQTTSessionManagerDelegate>
- (void)timedout:(id)object;

- (MQTTSession *)newSession;
- (id<MQTTTransport>)transport;
- (id<MQTTPersistence>)persistence;
- (NSArray *)clientCerts;
- (void)connect;
- (void)shutdownWithReturnCode:(MQTTReturnCode)returnCode
         sessionExpiryInterval:(NSNumber *)sessionExpiryInterval
                  reasonString:(NSString *)reasonString
                userProperties:(NSArray <NSDictionary <NSString *, NSString *> *> *)userProperties;


@property (strong, nonatomic) NSMutableDictionary *parameters;
@property (strong, nonatomic) MQTTSession *session;

@property (nonatomic) MQTTSessionEvent event;
@property (strong, nonatomic) NSError *error;

@property (strong, nonatomic) NSError *connectionError;
@property (nonatomic) BOOL connected;
@property (nonatomic) BOOL sessionPresent;

@property (nonatomic) UInt16 subMid;
@property (nonatomic) UInt16 unsubMid;
@property (nonatomic) UInt16 messageMid;
@property (nonatomic) NSArray<NSNumber *> *subscriptionIdentifiers;

@property (nonatomic) UInt16 sentSubMid;
@property (nonatomic) UInt16 sentUnsubMid;
@property (nonatomic) UInt16 sentMessageMid;
@property (nonatomic) UInt16 deliveredMessageMid;

@property (nonatomic) NSInteger SYSreceived;
@property (nonatomic) NSInteger newMessages;
@property (nonatomic) NSInteger retainedMessages;
@property (nonatomic) NSArray *qoss;

@property (nonatomic) BOOL timedout;
@property (strong, nonatomic) NSTimer *timer;
@property (nonatomic) NSTimeInterval timeoutValue;

@property (nonatomic) int type;

@end
