//
//  MQTTSessionTests.m
//  MQTTClient
//
//  Created by Josip Cavar on 30/10/2017.
//  Copyright ©2017-2020 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MQTTLog.h"
#import "MQTTSession.h"
#import "MQTTNWTransport.h"

@interface MQTTSessionTests : XCTestCase

@end

@implementation MQTTSessionTests

- (void)setUp {
    [super setUp];
    [MQTTLog setLogLevel:DDLogLevelInfo];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testMQTTSessionDestroyedWhenDeallocated {
    __weak MQTTSession *weakSession = nil;
    @autoreleasepool {
        MQTTSession *session = [[MQTTSession alloc] init];
        weakSession = session;
        session.transport = [[MQTTNWTransport alloc] init];
        [session connectWithConnectHandler:nil];
    }
    XCTAssertNil(weakSession);
}

@end
