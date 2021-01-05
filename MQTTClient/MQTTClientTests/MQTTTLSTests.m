//
//  MQTTTLSTests.m
//  MQTTClient
//
//  Created by Christoph Krey on 04.01.21.
//  Copyright © 2021 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MQTTTestHelpers.h"
#import "mqttc/MQTTNWTransport.h"

@interface MQTTTLSTests : MQTTTestHelpers
@property (nonatomic) BOOL connecting;
@property (nonatomic) BOOL disconnecting;
@end

@implementation MQTTTLSTests

- (void)setUp {
    [super setUp];
    [MQTTLog setLogLevel:DDLogLevelVerbose];
    self.connecting = false;
    self.disconnecting = false;
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_mosquitto_1883 {
    [self test_mosquitto_any:@"test.mosquitto.org" port:1883 tls:false allowUntrustedCertificates:false];
}

- (void)test_mosquitto_8883 {
    [self test_mosquitto_any:@"test.mosquitto.org" port:8883 tls:true allowUntrustedCertificates:false];
}

- (void)test_mosquitto_8883_allowUntrusted {
    [self test_mosquitto_any:@"test.mosquitto.org" port:8883 tls:true allowUntrustedCertificates:true];
}

- (void)test_mosquitto_8889 {
    [self test_mosquitto_any:@"test.mosquitto.org" port:8889 tls:true allowUntrustedCertificates:false];
}

- (void)test_mosquitto_any:(NSString *)host
                      port:(UInt16)port
                       tls:(BOOL)tls
allowUntrustedCertificates:(BOOL)allowUntrustedCertificates {
    MQTTNWTransport *nwTransport = [[MQTTNWTransport alloc] init];
    nwTransport.host = host;
    nwTransport.port = port;
    nwTransport.tls = tls;
    nwTransport.allowUntrustedCertificates = allowUntrustedCertificates;

    self.session = [[MQTTSession alloc] init];
    self.session.transport = nwTransport;
    self.session.protocolLevel = MQTTProtocolVersion50;

    self.session.delegate = self;

    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.timedout = FALSE;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:10];

    [self.session connectWithConnectHandler:^(NSError *error) {
        if (error) {
            DDLogError(@"connectWithConnectHandler %@", error);
        } else {
        }
        self.connecting = true;
    }];

    while (!self.timedout && !self.connecting) {
        DDLogVerbose(@"waiting for connection");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }

    [NSObject cancelPreviousPerformRequestsWithTarget:self];

    XCTAssert(!self.timedout, @"timeout");
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);

    self.timedout = FALSE;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:10];

    [self.session closeWithReturnCode:MQTTSuccess
                sessionExpiryInterval:nil
                         reasonString:nil
                       userProperties:nil
                    disconnectHandler:^(NSError *error) {
        if (error) {
            DDLogError(@"closeWithReturnCode %@", error);
        } else {
        }
        self.disconnecting = true;
    }];

    while (!self.timedout && !self.disconnecting) {
        DDLogVerbose(@"waiting for disconnect");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }

    XCTAssert(!self.timedout, @"timeout");
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

@end
