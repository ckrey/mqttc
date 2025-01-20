//
//  MQTTv5ExtendedAuth.m
//  MQTTClient
//
//  Created by Christoph Krey on 20.06.18.
//  Copyright ©2018-2025 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MQTTTestHelpers.h"

@interface MQTTv5ExtendedAuth : MQTTTestHelpers
@property (nonatomic) int sent;
@property (nonatomic) int received;
@property (nonatomic) int processed;

@end

@implementation MQTTv5ExtendedAuth

- (void)test_extended_auth_fail {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
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

- (void)test_extended_auth_baddata {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
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

- (void)test_extended_auth {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
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

- (void)test_extended_re_auth {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
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
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    self.session.authMethod = @"method";
    self.session.authData = [@"data" dataUsingEncoding:NSUTF8StringEncoding];
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}

@end
