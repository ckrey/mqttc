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
@property (nonatomic) BOOL ungraceful;
@property (nonatomic) int sent;
@property (nonatomic) int received;
@property (nonatomic) int processed;

@end

@implementation MQTTv5SessionExpiry

- (void)test_sEI_none {
    if ([self.parameters[@"protocollevel"] integerValue] == MQTTProtocolVersion50) {
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
}

- (void)test_sEI_zero {
    if ([self.parameters[@"protocollevel"] integerValue] == MQTTProtocolVersion50) {
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
}

- (void)test_sEI_max {
    if ([self.parameters[@"protocollevel"] integerValue] == MQTTProtocolVersion50) {
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
}

- (void)test_sEI_max_reconnect {
    if ([self.parameters[@"protocollevel"] integerValue] == MQTTProtocolVersion50) {
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
}

- (void)test_sEI_zero_reconnect {
    if ([self.parameters[@"protocollevel"] integerValue] == MQTTProtocolVersion50) {
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
}

- (void)test_sEI_none_reconnect {
    if ([self.parameters[@"protocollevel"] integerValue] == MQTTProtocolVersion50) {
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
}

- (void)test_sEI_max_disconnect_zero_reconnect {
    if ([self.parameters[@"protocollevel"] integerValue] == MQTTProtocolVersion50) {
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
}

- (void)test_sEI_max_disconnect_small_reconnect {
    if ([self.parameters[@"protocollevel"] integerValue] == MQTTProtocolVersion50) {
        self.session = [self newSession];
        self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
        self.session.sessionExpiryInterval = @42949672956U;
        [self connect];
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
        [self shutdownWithReturnCode:MQTTSuccess
               sessionExpiryInterval:@3U
                        reasonString:nil
                      userProperties:nil];

        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:5]];

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
}

- (void)test_sEI_zero_disconnect_large_reconnect {
    if ([self.parameters[@"protocollevel"] integerValue] == MQTTProtocolVersion50) {
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
}

- (void)test_sEI_none_disconnect_large_reconnect {
    if ([self.parameters[@"protocollevel"] integerValue] == MQTTProtocolVersion50) {
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
}


- (void)test_sEI_small_disconnect_larger_reconnect {
    if ([self.parameters[@"protocollevel"] integerValue] == MQTTProtocolVersion50) {
        self.session = [self newSession];
        self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
        self.session.sessionExpiryInterval = @3U;
        [self connect];
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
        [self shutdownWithReturnCode:MQTTSuccess
               sessionExpiryInterval:@30U
                        reasonString:nil
                      userProperties:nil];

        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:5]];

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
}


- (void)test_sEI_max_reconnect_clean {
    if ([self.parameters[@"protocollevel"] integerValue] == MQTTProtocolVersion50) {
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
