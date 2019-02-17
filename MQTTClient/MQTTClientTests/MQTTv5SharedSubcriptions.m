//
//  MQTTv5SharedSubcriptions.m
//  MQTTClient
//
//  Created by Christoph Krey on 16.02.19.
//  Copyright © 2019 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MQTTLog.h"
#import "MQTTTestHelpers.h"

@interface MQTTv5SharedSubcriptions : MQTTTestHelpers

@end

@implementation MQTTv5SharedSubcriptions

- (void)test_sS_available {
    if ([self.parameters[@"protocollevel"] integerValue] != MQTTProtocolVersion50) {
        return;
    }
    self.session = [self newSession];
    self.session.clientId = [NSString stringWithFormat:@"%s", __FUNCTION__];
    self.session.sessionExpiryInterval = nil;
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);

    if (!self.session.sharedSubscriptionAvailable ||
        self.session.sharedSubscriptionAvailable.boolValue) {
        // test Shared Subcriptions
    } else {
        // test Shared Subscriptions are rejected
    }

    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}

@end
