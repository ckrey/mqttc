//
//  MQTTACLTests.m
//  MQTTClient
//
//  Created by Christoph Krey on 03.02.15.
//  Copyright © 2015-2019 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "MQTTLog.h"
#import "MQTTStrict.h"
#import "MQTTTestHelpers.h"

@interface MQTTACLTests : MQTTTestHelpers
@end

@implementation MQTTACLTests

/*
 * [MQTT-3.1.2-19]
 * If the User Name Flag is set to 1, a user name MUST be present in the payload.
 * [MQTT-3.1.2-21]
 * If the Password Flag is set to 1, a password MUST be present in the payload.
 */
- (void)test_connect_user_pwd_MQTT_3_1_2_19_MQTT_3_1_2_21 {
    self.session.userName = @"user";
    self.session.password = @"password";
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    [self shutdown];
}

/*
 * [MQTT-3.1.2-19]
 * If the User Name Flag is set to 1, a user name MUST be present in the payload.
 * [MQTT-3.1.2-20]
 * If the Password Flag is set to 0, a password MUST NOT be present in the payload.
 */
- (void)test_connect_user_no_pwd_MQTT_3_1_2_19_MQTT_3_1_2_20 {
    self.session.userName = @"user w/o password";
    self.session.password = nil;
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    [self shutdown];
}

/*
 * [MQTT-3.1.2-18]
 * If the User Name Flag is set to 0, a user name MUST NOT be present in the payload.
 * [MQTT-3.1.2-20]
 * If the Password Flag is set to 0, a password MUST NOT be present in the payload.
 */
- (void)test_connect_no_user_no_pwd_MQTT_3_1_2_18_MQTT_3_1_2_20 {
    self.session.userName = nil;
    self.session.password = nil;
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    [self shutdown];
}

/*
 * [MQTT-3.1.2-22]
 * If the User Name Flag is set to 0, the Password Flag MUST be set to 0.
 */

- (void)test_connect_no_user_but_pwd_MQTT_3_1_2_22 {
    if (self.session.protocolLevel != MQTTProtocolVersion50) {
        self.session.userName = nil;
        self.session.password = @"password w/o user";
        [self connect];
        XCTAssert(self.event == MQTTSessionEventConnectionClosedByBroker ||
                  self.event == MQTTSessionEventProtocolError,
                  @"Not Rejected %ld %@", (long)self.event, self.error);
        [self shutdown];
    }
}

/*
 * [MQTT-3.1.2-22]
 * If the User Name Flag is set to 0, the Password Flag MUST be set to 0.
 */

- (void)test_connect_no_user_but_pwd_strict {
    MQTTStrict.strict = TRUE;
    
    self.session = [self newSession];
    if (self.session.protocolLevel != MQTTProtocolVersion50) {
        self.session.userName = nil;
        @try {
            self.session.password = @"password w/o user";
            [self.session connectWithConnectHandler:nil];
            XCTFail(@"Should not get here but throw exception before");
        } @catch (NSException *exception) {
            //;
        } @finally {
            //
        }
    }
}

/*
 * [MQTT-3.1.2-22]
 * If the User Name Flag is set to 0, the Password Flag MUST be set to 0.
 */

- (void)test_connect_long_user_strict {
    MQTTStrict.strict = TRUE;
    self.session = [self newSession];
    self.session.userName = @"long user";
    self.session.password = @"password";
    
    while ([self.session.userName dataUsingEncoding:NSUTF8StringEncoding].length <= 65535L) {
        DDLogVerbose(@"userName length %lu",
                     (unsigned long)[self.session.userName dataUsingEncoding:NSUTF8StringEncoding].length);
        self.session.userName = [self.session.userName stringByAppendingString:self.session.userName];
    }
    
    @try {
        [self.session connectWithConnectHandler:nil];
        XCTFail(@"Should not get here but throw exception before");
    } @catch (NSException *exception) {
        //;
    } @finally {
        //
    }
}

- (void)test_connect_user_nonUTF8_strict {
    MQTTStrict.strict = TRUE;
    
    self.session = [self newSession];
    self.session.userName = @"user";
    
    @try {
        //NSData *data = [NSData dataWithBytes:"MQTTClient/abc\x9c\x9dxyz" length:19];
        //NSString *stringWith9c = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
        //self.session.userName = stringWith9c;
        NSString *stringWithD800 = [NSString stringWithFormat:@"%@/%C/%s", TOPIC, 0xD800, __FUNCTION__];
        self.session.userName = stringWithD800;
        //NSString *stringWithFEFF = [NSString stringWithFormat:@"%@<%C>/%s", TOPIC, 0xfeff, __FUNCTION__];
        //self.session.userName = stringWithFEFF;
        //NSString *stringWithNull = [NSString stringWithFormat:@"%@/%C/%s", TOPIC, 0, __FUNCTION__];
        //self.session.userName = stringWithNull;
        [self.session connectWithConnectHandler:nil];
        XCTFail(@"Should not get here but throw exception before");
    } @catch (NSException *exception) {
        //;
    } @finally {
        //
    }
}

- (void)connect {
    self.session.delegate = self;
    self.event = -1;
    self.timedout = FALSE;
    
    [self.session connectWithConnectHandler:nil];
    
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:[self.parameters[@"timeout"] intValue]];
    
    
    while (!self.timedout && self.event == -1) {
        DDLogVerbose(@"waiting for connection");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
}

- (void)shutdown {
    self.event = -1;
    
    self.timedout = FALSE;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:[self.parameters[@"timeout"] intValue]];
    
    [self.session closeWithReturnCode:MQTTSuccess
                sessionExpiryInterval:nil
                         reasonString:nil
                       userProperties:nil
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

@end
