//
//  MQTTv5SessionExpiry.m
//  MQTTClientTests
//
//  Created by Christoph Krey on 13.06.18.
//  Copyright © 2018 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MQTTLog.h"
#import "MQTTTestHelpers.h"


@interface MQTTv5SessionExpiry : MQTTTestHelpers
@property (nonatomic) int sent;
@property (nonatomic) int received;
@property (nonatomic) int processed;

@end

@implementation MQTTv5SessionExpiry

- (void)test_sEI_none {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    self.session = [self newSession];
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    self.session.sessionExpiryInterval = nil;
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}

- (void)test_sEI_zero {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    self.session = [self newSession];
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    self.session.sessionExpiryInterval = @0U;
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}

- (void)test_sEI_max {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    self.session = [self newSession];
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    self.session.sessionExpiryInterval = @42949672956U;
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}

- (void)test_sEI_max_reconnect {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    self.session = [self newSession];
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    self.session.sessionExpiryInterval = @42949672956U;
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];

    self.session = [self newSession];
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    self.session.cleanSessionFlag = false;
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    XCTAssertEqual(self.sessionPresent, true, @"no session present");

    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}

- (void)test_sEI_zero_reconnect {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    self.session = [self newSession];
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    self.session.sessionExpiryInterval = 0U;
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];

    self.session = [self newSession];
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    self.session.cleanSessionFlag = false;
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    XCTAssertEqual(self.sessionPresent, false, @"session still present");

    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}

- (void)test_sEI_none_reconnect {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    self.session = [self newSession];
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    self.session.sessionExpiryInterval = nil;
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];

    self.session = [self newSession];
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    self.session.cleanSessionFlag = false;
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    XCTAssertEqual(self.sessionPresent, false, @"session still present");

    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}

- (void)test_sEI_max_disconnect_zero_reconnect {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    self.session = [self newSession];
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    self.session.sessionExpiryInterval = @42949672956U;
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:@0U
                    reasonString:nil
                  userProperties:nil];

    self.session = [self newSession];
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    self.session.cleanSessionFlag = false;
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    XCTAssertEqual(self.sessionPresent, false, @"session still present");

    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}

- (void)test_sEI_max_disconnect_small_reconnect {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    self.session = [self newSession];
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    self.session.sessionExpiryInterval = @42949672956U;
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:@3U
                    reasonString:nil
                  userProperties:nil];

    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:10]];

    self.session = [self newSession];
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    self.session.cleanSessionFlag = false;
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    XCTAssertEqual(self.sessionPresent, false, @"session still present");

    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}

- (void)test_sEI_zero_disconnect_large_reconnect {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    self.session = [self newSession];
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    self.session.sessionExpiryInterval = @0U;
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:@30U
                    reasonString:nil
                  userProperties:nil];

    self.session = [self newSession];
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    self.session.cleanSessionFlag = false;
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    XCTAssertEqual(self.sessionPresent, false, @"session still present");

    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}

- (void)test_sEI_none_disconnect_large_reconnect {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    self.session = [self newSession];
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    self.session.sessionExpiryInterval = nil;
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:@30U
                    reasonString:nil
                  userProperties:nil];

    self.session = [self newSession];
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    self.session.cleanSessionFlag = false;
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    XCTAssertEqual(self.sessionPresent, false, @"session still present");

    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}


- (void)test_sEI_small_disconnect_larger_reconnect {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    self.session = [self newSession];
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    self.session.sessionExpiryInterval = @3U;
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:@30U
                    reasonString:nil
                  userProperties:nil];

    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:10]];

    self.session = [self newSession];
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    self.session.cleanSessionFlag = false;
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    XCTAssertEqual(self.sessionPresent, true, @"session not present");

    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}


- (void)test_sEI_max_reconnect_clean {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    self.session = [self newSession];
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    self.session.sessionExpiryInterval = @42949672956U;
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];

    self.session = [self newSession];
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    self.session.cleanSessionFlag = true;
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    XCTAssertEqual(self.sessionPresent, false, @"session still present");

    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}

@end
