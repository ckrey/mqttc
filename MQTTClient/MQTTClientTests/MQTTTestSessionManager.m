//
//  MQTTMQTTTestSessionManager.m
//  MQTTClient
//
//  Created by Christoph Krey on 21.08.15.
//  Copyright © 2015-2022 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "MQTTTestHelpers.h"

@interface MQTTSessionManager (Tests)

- (void)connectWithHelpers:(MQTTTestHelpers *)helpers clean:(BOOL)clean;

@end

@implementation MQTTSessionManager (Tests)

- (void)connectWithHelpers:(MQTTTestHelpers *)helpers clean:(BOOL)clean {
    [self connectTo:helpers.parameters[@"host"]
               port:[helpers.parameters[@"port"] intValue]
                tls:[helpers.parameters[@"tls"] boolValue]
          keepalive:60
              clean:clean
               auth:NO
               user:nil
               pass:nil
               will:nil
       withClientId:nil
allowUntrustedCertificates:[helpers.parameters[@"allowUntrustedCertificates"] boolValue]
       certificates:[helpers clientCerts]
      protocolLevel:[helpers.parameters[@"protocollevel"] intValue]
            runLoop:[NSRunLoop currentRunLoop]];
}

@end

@interface MQTTTestSessionManager : MQTTTestHelpers <MQTTSessionManagerDelegate>
@property (nonatomic) int step;
@property (nonatomic) int sent;
@property (nonatomic) int received;
@property (nonatomic) int processed;

@end

@implementation MQTTTestSessionManager

/*
 * |#define                |MAC      |IOS      |IOS SIMULATOR  |TV       |TV SIMULATOR |WATCH   |WATCH SIMULATOR |
 * |-----------------------|---------|---------|---------------|---------|-------------|--------|----------------|
 * |TARGET_OS_MAC          |    1    |    1    |       1       |    1    |      1      |        |                |
 * |TARGET_OS_WIN32        |    0    |    0    |       0       |    0    |      0      |        |                |
 * |TARGET_OS_UNIX         |    0    |    0    |       0       |    0    |      0      |        |                |
 * |TARGET_OS_IPHONE       |    0    |    1    |       1       |    1    |      1      |        |                |
 * |TARGET_OS_IOS          |    0    |    1    |       1       |    0    |      0      |        |                |
 * |TARGET_OS_WATCH        |    0    |    0    |       0       |    0    |      0      |        |                |
 * |TARGET_OS_TV           |    0    |    0    |       0       |    1    |      1      |        |                |
 * |TARGET_OS_SIMULATOR    |    0    |    0    |       1       |    0    |      1      |        |                |
 * |TARGET_OS_EMBEDDED     |    0    |    1    |       0       |    1    |      0      |        |                |
 *
 * define TARGET_IPHONE_SIMULATOR         TARGET_OS_SIMULATOR deprecated
 * define TARGET_OS_NANO                  TARGET_OS_WATCH deprecated
 *
 * all #defines in TargetConditionals.h
 */

- (void)test_preprocessor {
#if TARGET_OS_MAC == 1
    DDLogVerbose(@"TARGET_OS_MAC==1");
#endif
#if TARGET_OS_MAC == 0
    DDLogVerbose(@"TARGET_OS_MAC==0");
#endif
    DDLogVerbose(@"TARGET_OS_MAC %d", TARGET_OS_MAC);
    DDLogVerbose(@"TARGET_OS_WIN32 %d", TARGET_OS_WIN32);
    DDLogVerbose(@"TARGET_OS_UNIX %d", TARGET_OS_UNIX);
    DDLogVerbose(@"TARGET_OS_IPHONE %d", TARGET_OS_IPHONE);
    DDLogVerbose(@"TARGET_OS_IOS %d", TARGET_OS_IOS);
    DDLogVerbose(@"TARGET_OS_WATCH %d", TARGET_OS_WATCH);
    DDLogVerbose(@"TARGET_OS_TV %d", TARGET_OS_TV);
    DDLogVerbose(@"TARGET_OS_SIMULATOR %d", TARGET_OS_SIMULATOR);
    DDLogVerbose(@"TARGET_OS_EMBEDDED %d", TARGET_OS_EMBEDDED);
}

- (void)testMQTTSessionManagerClean {
    [MQTTLog setLogLevel:DDLogLevelVerbose];
    [self testMQTTSessionManager:true];
}

- (void)testMQTTSessionManagerNoClean {
    [MQTTLog setLogLevel:DDLogLevelInfo];
    [self testMQTTSessionManager:false];
}

- (void)testMQTTSessionManager:(BOOL)clean {
    if (![self.parameters[@"websocket"] boolValue]) {
        self.step = -1;
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:[self.parameters[@"timeout"] intValue]
                                                          target:self
                                                        selector:@selector(stepper:)
                                                        userInfo:nil
                                                         repeats:true];
        
        self.received = 0;
        MQTTSessionManager *manager = [[MQTTSessionManager alloc] init];
        manager.delegate = self;
        
        [manager addObserver:self
                  forKeyPath:@"effectiveSubscriptions"
                     options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                     context:nil];
        manager.subscriptions = [@{TOPIC: @(0)} mutableCopy];
        [manager connectWithHelpers:self clean:clean];
        
        while (self.step == -1 && manager.state != MQTTSessionManagerStateConnected) {
            DDLogInfo(@"[testMQTTSessionManager] waiting for connect %d", manager.state);
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        XCTAssertEqual(manager.state, MQTTSessionManagerStateConnected);
        [manager sendData:[[NSData alloc] init] topic:TOPIC qos:MQTTQosLevelAtMostOnce retain:true];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        
        while (self.step <= 0) {
            DDLogInfo(@"[testMQTTSessionManager] received %lu/%lu on TOPIC", (unsigned long)self.received, (unsigned long)self.sent);
            [manager sendData:[[NSDate date].description dataUsingEncoding:NSUTF8StringEncoding]
                        topic:TOPIC qos:MQTTQosLevelAtMostOnce retain:FALSE];
            self.sent++;
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        
        manager.subscriptions = [@{TOPIC: @(0),@"$SYS/#": @(0)} mutableCopy];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        
        while (self.step == 1) {
            DDLogInfo(@"[testMQTTSessionManager] received %lu/%lu on TOPIC or $SYS/#", (unsigned long)self.received, (unsigned long)self.sent);
            [manager sendData:[[NSDate date].description dataUsingEncoding:NSUTF8StringEncoding]
                        topic:TOPIC qos:MQTTQosLevelAtMostOnce retain:FALSE];
            self.sent++;
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        
        manager.subscriptions = [@{@"$SYS/#": @(0)} mutableCopy];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        
        while (self.step <= 2) {
            DDLogInfo(@"[testMQTTSessionManager] received %lu/%lu on $SYS/#", (unsigned long)self.received, (unsigned long)self.sent);
            [manager sendData:[[NSDate date].description dataUsingEncoding:NSUTF8StringEncoding]
                        topic:TOPIC qos:MQTTQosLevelAtMostOnce retain:FALSE];
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        
        manager.subscriptions = [@{} mutableCopy];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        
        while (self.step <= 3) {
            DDLogInfo(@"[testMQTTSessionManager] received %lu/%lu on nothing", (unsigned long)self.received, (unsigned long)self.sent);
            [manager sendData:[[NSDate date].description dataUsingEncoding:NSUTF8StringEncoding]
                        topic:TOPIC qos:MQTTQosLevelAtMostOnce retain:FALSE];
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        
        [manager disconnect];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        
        while (self.step <= 4) {
            DDLogInfo(@"[testMQTTSessionManager] received %lu/%lu after disconnect", (unsigned long)self.received, (unsigned long)self.sent);
            [manager sendData:[[NSDate date].description dataUsingEncoding:NSUTF8StringEncoding]
                        topic:TOPIC qos:MQTTQosLevelAtMostOnce retain:FALSE];
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        XCTAssertEqual(self.received, self.sent);
        [manager removeObserver:self forKeyPath:@"effectiveSubscriptions"];
        [timer invalidate];
    }
}

- (void)testMQTTSessionManagerPersistent {
    [MQTTLog setLogLevel:DDLogLevelInfo];
    if (![self.parameters[@"websocket"] boolValue]) {

        self.step = -1;
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:[self.parameters[@"timeout"] intValue]
                                                          target:self
                                                        selector:@selector(stepper:)
                                                        userInfo:nil
                                                         repeats:true];
        
        self.received = 0;
        MQTTSessionManager *manager = [[MQTTSessionManager alloc] initWithPersistence:true
                                                                        maxWindowSize:2
                                                                          maxMessages:1024
                                                                              maxSize:64*1024*1024
                                                           maxConnectionRetryInterval:60
                                                                  connectInForeground:YES];
        manager.delegate = self;
        [manager addObserver:self
                  forKeyPath:@"effectiveSubscriptions"
                     options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                     context:nil];
        
        manager.subscriptions = [@{TOPIC: @(0)} mutableCopy];
        [manager connectWithHelpers:self clean:YES];
        while (self.step == -1 && manager.state != MQTTSessionManagerStateConnected) {
            DDLogInfo(@"[testMQTTSessionManagerPersistent] waiting for connect %d", manager.state);
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        XCTAssertEqual(manager.state, MQTTSessionManagerStateConnected);
        [manager sendData:[[NSData alloc] init] topic:TOPIC qos:MQTTQosLevelAtMostOnce retain:true];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        
        while (self.step <= 0) {
            DDLogInfo(@"received %lu/%lu on TOPIC", (unsigned long)self.received, (unsigned long)self.sent);
            [manager sendData:[@"data" dataUsingEncoding:NSUTF8StringEncoding] topic:TOPIC qos:MQTTQosLevelAtMostOnce retain:FALSE];
            self.sent++;
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
        }
        
        manager.subscriptions = [@{TOPIC: @(0),@"a": @(1),@"b": @(2),@"$SYS/#": @(0)} mutableCopy];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        
        while (self.step == 1) {
            DDLogInfo(@"[testMQTTSessionManagerPersistent] received %lu/%lu on TOPIC or $SYS/#", (unsigned long)self.received, (unsigned long)self.sent);
            [manager sendData:[@"data" dataUsingEncoding:NSUTF8StringEncoding] topic:TOPIC qos:MQTTQosLevelAtMostOnce retain:FALSE];
            self.sent++;
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
        }
        
        manager.subscriptions = [@{@"$SYS/#": @(0)} mutableCopy];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        
        while (self.step <= 2) {
            DDLogInfo(@"[testMQTTSessionManagerPersistent] received %lu/%lu on $SYS/#", (unsigned long)self.received, (unsigned long)self.sent);
            [manager sendData:[@"data" dataUsingEncoding:NSUTF8StringEncoding] topic:TOPIC qos:MQTTQosLevelAtMostOnce retain:FALSE];
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
        }
        
        manager.subscriptions = [@{} mutableCopy];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        
        while (self.step <= 3) {
            DDLogInfo(@"[testMQTTSessionManagerPersistent] received %lu/%lu on nothing", (unsigned long)self.received, (unsigned long)self.sent);
            [manager sendData:[@"data" dataUsingEncoding:NSUTF8StringEncoding] topic:TOPIC qos:MQTTQosLevelAtMostOnce retain:FALSE];
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
        }
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        
        [manager disconnect];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        
        while (self.step <= 4) {
            DDLogInfo(@"[testMQTTSessionManagerPersistent] received %lu/%lu after disconnect", (unsigned long)self.received, (unsigned long)self.sent);
            [manager sendData:[[NSDate date].description dataUsingEncoding:NSUTF8StringEncoding]
                        topic:TOPIC qos:MQTTQosLevelAtMostOnce retain:FALSE];
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
        }
        XCTAssertEqual(self.received, self.sent);
        [manager removeObserver:self forKeyPath:@"effectiveSubscriptions"];
        
        [timer invalidate];
    }
}

- (void)testSessionManagerShort {
    [MQTTLog setLogLevel:DDLogLevelInfo];
    if (![self.parameters[@"websocket"] boolValue]) {

        MQTTSessionManager *manager = [[MQTTSessionManager alloc] init];
        manager.delegate = self;
        [manager addObserver:self
                  forKeyPath:@"effectiveSubscriptions"
                     options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                     context:nil];
        
        // allow 5 sec for connect
        self.timedout = false;
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:5
                                                          target:self
                                                        selector:@selector(timedout:)
                                                        userInfo:nil
                                                         repeats:false];
        
        
        manager.subscriptions = @{TOPIC: @(MQTTQosLevelExactlyOnce)};
        [manager connectWithHelpers:self clean:YES];

        while (!self.timedout && manager.state != MQTTSessionManagerStateConnected) {
            DDLogInfo(@"waiting for connect %d", manager.state);
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
        }
        if (timer.valid) [timer invalidate];
        
        // allow 5 sec for sending and receiving
        self.timedout = false;
        timer = [NSTimer scheduledTimerWithTimeInterval:5
                                                 target:self
                                               selector:@selector(timedout:)
                                               userInfo:nil
                                                repeats:false];
        
        
        while (!self.timedout) {
            [manager sendData:[[NSDate date].description dataUsingEncoding:NSUTF8StringEncoding]
                        topic:TOPIC qos:MQTTQosLevelExactlyOnce retain:FALSE];
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        if (timer.valid) [timer invalidate];
        [manager sendData:[[NSData alloc] init] topic:TOPIC qos:MQTTQosLevelExactlyOnce retain:true];
        
        // allow 3 sec for disconnect
        self.timedout = false;
        timer = [NSTimer scheduledTimerWithTimeInterval:3
                                                 target:self
                                               selector:@selector(timedout:)
                                               userInfo:nil
                                                repeats:false];
        
        [manager disconnect];
        while (!self.timedout && manager.state != MQTTSessionStatusClosed) {
            DDLogInfo(@"waiting for disconnect %d", manager.state);
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
        }
        if (timer.valid) [timer invalidate];
        [manager removeObserver:self forKeyPath:@"effectiveSubscriptions"];
    }
}

- (void)testSessionManagerALotSubscriptions {
    [MQTTLog setLogLevel:DDLogLevelInfo];
    if (![self.parameters[@"websocket"] boolValue]) {

        MQTTSessionManager *manager = [[MQTTSessionManager alloc] init];
        manager.delegate = self;
        
        [manager addObserver:self
                  forKeyPath:@"effectiveSubscriptions"
                     options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                     context:nil];
        
        NSMutableDictionary *subscriptions = [@{TOPIC: @(0),
                                                @"a0": @(1),
                                                @"b0": @(2),
                                                @"a1": @(1),
                                                @"b1": @(2),
                                                @"a2": @(1),
                                                @"b2": @(2),
                                                @"a3": @(1),
                                                @"b3": @(2),
                                                @"a4": @(1),
                                                @"b4": @(2),
                                                @"a5": @(1),
                                                @"b5": @(2),
                                                @"a6": @(1),
                                                @"b6": @(2),
                                                @"a7": @(1),
                                                @"b7": @(2),
                                                @"a8": @(1),
                                                @"b8": @(2),
                                                @"a9": @(1),
                                                @"b9": @(2),
                                                @"a0/x": @(1),
                                                @"b0/x": @(2),
                                                @"a1/x": @(1),
                                                @"b1/x": @(2),
                                                @"a2/x": @(1),
                                                @"b2/x": @(2),
                                                @"a3/x": @(1),
                                                @"b3/x": @(2),
                                                @"a4/x": @(1),
                                                @"b4/x": @(2),
                                                @"a5/x": @(1),
                                                @"b5/x": @(2),
                                                @"a6/x": @(1),
                                                @"b6/x": @(2),
                                                @"a7/x": @(1),
                                                @"b7/x": @(2),
                                                @"a8/x": @(1),
                                                @"b8/x": @(2),
                                                @"a9/x": @(1),
                                                @"b9/x": @(2),
                                                @"a0/x/y/z": @(1),
                                                @"b0/x/y/z": @(2),
                                                @"a1/x/y/z": @(1),
                                                @"b1/x/y/z": @(2),
                                                @"a2/x/y/z": @(1),
                                                @"b2/x/y/z": @(2),
                                                @"a3/x/y/z": @(1),
                                                @"b3/x/y/z": @(2),
                                                @"a4/x/y/z": @(1),
                                                @"b4/x/y/z": @(2),
                                                @"a5/x/y/z": @(1),
                                                @"b5/x/y/z": @(2),
                                                @"a6/x/y/z": @(1),
                                                @"b6/x/y/z": @(2),
                                                @"a7/x/y/z": @(1),
                                                @"b7/x/y/z": @(2),
                                                @"a8/x/y/z": @(1),
                                                @"b8/x/y/z": @(2),
                                                @"a9/x/y/z": @(1),
                                                @"b9/x/y/z": @(2),
                                                @"$SYS/#": @(0)
                                                } mutableCopy];

        manager.subscriptions = subscriptions;
        
        // allow 5 sec for connect
        self.timedout = false;
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:5
                                                          target:self
                                                        selector:@selector(timedout:)
                                                        userInfo:nil
                                                         repeats:false];

        [manager connectWithHelpers:self clean:YES];
        
        while (!self.timedout && manager.state != MQTTSessionManagerStateConnected) {
            DDLogInfo(@"waiting for connect %d", manager.state);
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
        }
        if (timer.valid) [timer invalidate];
        
        manager.subscriptions = @{};
        
        // allow 5 sec for subscribing
        self.timedout = false;
        timer = [NSTimer scheduledTimerWithTimeInterval:5
                                                 target:self
                                               selector:@selector(timedout:)
                                               userInfo:nil
                                                repeats:false];
        
        
        while (!self.timedout) {
            [manager sendData:[[NSDate date].description dataUsingEncoding:NSUTF8StringEncoding]
                        topic:TOPIC qos:MQTTQosLevelExactlyOnce retain:FALSE];
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        if (timer.valid) [timer invalidate];
        
        manager.subscriptions = [@{TOPIC: @(0),
                                   @"a0": @(1),
                                   @"b0": @(2),
                                   @"a1": @(1),
                                   @"b1": @(2),
                                   @"a2": @(1),
                                   @"b2": @(2),
                                   @"a3": @(1),
                                   @"b3": @(2),
                                   @"a4": @(1),
                                   @"b4": @(2),
                                   @"a5": @(1),
                                   @"b5": @(2),
                                   @"a6": @(1),
                                   @"b6": @(2),
                                   @"a7": @(1),
                                   @"b7": @(2),
                                   @"a8": @(1),
                                   @"b8": @(2),
                                   @"a9": @(1),
                                   @"b9": @(2),
                                   @"a0/x/y/z": @(1),
                                   @"b0/x/y/z": @(2),
                                   @"a1/x/y/z": @(1),
                                   @"b1/x/y/z": @(2),
                                   @"a2/x/y/z": @(1),
                                   @"b2/x/y/z": @(2),
                                   @"a3/x/y/z": @(1),
                                   @"b3/x/y/z": @(2),
                                   @"a4/x/y/z": @(1),
                                   @"b4/x/y/z": @(2),
                                   @"a5/x/y/z": @(1),
                                   @"b5/x/y/z": @(2),
                                   @"a6/x/y/z": @(1),
                                   @"b6/x/y/z": @(2),
                                   @"a7/x/y/z": @(1),
                                   @"b7/x/y/z": @(2),
                                   @"a8/x/y/z": @(1),
                                   @"b8/x/y/z": @(2),
                                   @"a9/x/y/z": @(1),
                                   @"b9/x/y/z": @(2),
                                   @"$SYS/#": @(0)
                                   } mutableCopy];
        
        // allow 5 sec for subscribing
        self.timedout = false;
        timer = [NSTimer scheduledTimerWithTimeInterval:5
                                                 target:self
                                               selector:@selector(timedout:)
                                               userInfo:nil
                                                repeats:false];
        
        
        while (!self.timedout) {
            [manager sendData:[[NSDate date].description dataUsingEncoding:NSUTF8StringEncoding]
                        topic:TOPIC qos:MQTTQosLevelExactlyOnce retain:FALSE];
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        if (timer.valid) [timer invalidate];
        
        manager.subscriptions = [@{TOPIC: @(0),
                                   @"a0": @(1),
                                   @"b0": @(2),
                                   @"a1": @(1),
                                   @"b1": @(2),
                                   @"a2": @(1),
                                   @"b2": @(2),
                                   @"a3": @(1),
                                   @"b3": @(2),
                                   @"a4": @(1),
                                   @"b4": @(2),
                                   @"a5": @(1),
                                   @"b5": @(2),
                                   @"a6": @(1),
                                   @"b6": @(2),
                                   @"a7": @(1),
                                   @"b7": @(2),
                                   @"a8": @(1),
                                   @"b8": @(2),
                                   @"a9": @(1),
                                   @"b9": @(2),
                                   @"a0/x": @(1),
                                   @"b0/x": @(2),
                                   @"a1/x": @(1),
                                   @"b1/x": @(2),
                                   @"a2/x": @(1),
                                   @"b2/x": @(2),
                                   @"a3/x": @(1),
                                   @"b3/x": @(2),
                                   @"a4/x": @(1),
                                   @"b4/x": @(2),
                                   @"a5/x": @(1),
                                   @"b5/x": @(2),
                                   @"a6/x": @(1),
                                   @"b6/x": @(2),
                                   @"a7/x": @(1),
                                   @"b7/x": @(2),
                                   @"a8/x": @(1),
                                   @"b8/x": @(2),
                                   @"a9/x": @(1),
                                   @"b9/x": @(2),
                                   @"$SYS/#": @(0)
                                   } mutableCopy];
        
        // allow 5 sec for subscribing
        self.timedout = false;
        timer = [NSTimer scheduledTimerWithTimeInterval:5
                                                 target:self
                                               selector:@selector(timedout:)
                                               userInfo:nil
                                                repeats:false];
        
        
        while (!self.timedout) {
            [manager sendData:[[NSDate date].description dataUsingEncoding:NSUTF8StringEncoding]
                        topic:TOPIC qos:MQTTQosLevelExactlyOnce retain:FALSE];
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        if (timer.valid) [timer invalidate];
        
        
        for (int i = 0; i < 30; i++) {
            subscriptions[[NSString stringWithFormat:@"abc/%d", i]] = @1;
            manager.subscriptions = subscriptions;
        }
        
        for (int i = 0; i < 30; i++) {
            [subscriptions removeObjectForKey:[NSString stringWithFormat:@"abc/%d", i]];
            manager.subscriptions = subscriptions;
        }
        
        // allow 5 sec for subscribing
        self.timedout = false;
        timer = [NSTimer scheduledTimerWithTimeInterval:5
                                                 target:self
                                               selector:@selector(timedout:)
                                               userInfo:nil
                                                repeats:false];

        while (!self.timedout) {
            [manager sendData:[[NSDate date].description dataUsingEncoding:NSUTF8StringEncoding]
                        topic:TOPIC qos:MQTTQosLevelExactlyOnce retain:FALSE];
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        if (timer.valid) [timer invalidate];
        
        // allow 5 sec for sending and receiving
        self.timedout = false;
        timer = [NSTimer scheduledTimerWithTimeInterval:5
                                                 target:self
                                               selector:@selector(timedout:)
                                               userInfo:nil
                                                repeats:false];

        while (!self.timedout) {
            [manager sendData:[[NSDate date].description dataUsingEncoding:NSUTF8StringEncoding]
                        topic:TOPIC qos:MQTTQosLevelExactlyOnce retain:FALSE];
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        if (timer.valid) [timer invalidate];
        
        [manager sendData:[[NSData alloc] init] topic:TOPIC qos:MQTTQosLevelExactlyOnce retain:true];
        
        // allow 3 sec for disconnect
        self.timedout = false;
        timer = [NSTimer scheduledTimerWithTimeInterval:3
                                                 target:self
                                               selector:@selector(timedout:)
                                               userInfo:nil
                                                repeats:false];
        
        [manager disconnect];
        while (!self.timedout && manager.state != MQTTSessionStatusClosed) {
            DDLogInfo(@"waiting for disconnect %d", manager.state);
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
        }
        
        if (timer.valid) [timer invalidate];
        
        [manager removeObserver:self forKeyPath:@"effectiveSubscriptions"];
    }
}

- (void)testMQTTSessionManagerDestoryedWhenDeallocated {
    __weak MQTTSessionManager *weakManager = nil;
    @autoreleasepool {
        MQTTSessionManager *manager = [[MQTTSessionManager alloc] init];
        weakManager = manager;
    }
    XCTAssertNil(weakManager);
}

- (void)testMQTTSessionManagerRecconnectionWithConnectToLast {
    if (![self.parameters[@"websocket"] boolValue]) {
        self.step = -1;
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:[self.parameters[@"timeout"] intValue]
                                                          target:self
                                                        selector:@selector(stepper:)
                                                        userInfo:nil
                                                         repeats:true];

        MQTTSessionManager *manager = [[MQTTSessionManager alloc] init];
        manager.delegate = self;

        [manager connectWithHelpers:self clean:YES];

        while (self.step == -1 && manager.state != MQTTSessionManagerStateConnected) {
            DDLogInfo(@"[testMQTTSessionManager] waiting for connect %d", manager.state);
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        XCTAssertEqual(manager.state, MQTTSessionManagerStateConnected);

        [manager disconnect];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];

        XCTAssertEqual(manager.state, MQTTSessionManagerStateClosed);

        while (self.step <= 0) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }

        [manager connectToLast];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];

        XCTAssertEqual(manager.state, MQTTSessionManagerStateConnected);

        while (self.step <= 1) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        
        [timer invalidate];
    }
}

#pragma mark - helpers


- (void)sessionManager:(MQTTSessionManager *)sessionManager
     didReceiveMessage:(NSData *)data
               onTopic:(NSString *)topic
              retained:(BOOL)retained {
    DDLogInfo(@"[MQTTSessionManager] didReceiveMessage (%lu) t:%@ r%d",
              (unsigned long)data.length, topic, retained);
    if ([topic isEqualToString:TOPIC]) {
        if (!retained && data.length) {
            self.received++;
        } else {
            self.received = 0;
        }
    }
}

- (void)sessionManager:(MQTTSessionManager *)sessionManager didDeliverMessage:(UInt16)msgID {
    DDLogVerbose(@"[MQTTSessionManager] messageDelivered %d", msgID);
}

- (void)timedout:(NSTimer *)timer {
    DDLogVerbose(@"[MQTTSessionManager] timedout");
    self.timedout = true;
}

- (void)stepper:(NSTimer *)timer {
    DDLogVerbose(@"[MQTTSessionManager] stepper s:%d", self.step);
    self.step++;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"effectiveSubscriptions"]) {
        MQTTSessionManager *manager = (MQTTSessionManager *)object;
        DDLogInfo(@"[MQTTSessionManager] effectiveSubscriptions changed: %@", manager.effectiveSubscriptions);
    }
}

@end
