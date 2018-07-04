//
//  MQTTTestHelpers.m
//  MQTTClient
//
//  Created by Christoph Krey on 09.12.15.
//  Copyright © 2015-2018 Christoph Krey. All rights reserved.
//

#import "MQTTLog.h"
#import "MQTTStrict.h"
#import "MQTTTestHelpers.h"
#import "MQTTCFSocketTransport.h"
#import "MQTTInMemoryPersistence.h"
#import "MQTTCoreDataPersistence.h"
#import "MQTTWebsocketTransport.h"
#import "MQTTSSLSecurityPolicy.h"
#import "MQTTSSLSecurityPolicyTransport.h"

@implementation MQTTTestHelpers

- (void)setUp {
    [super setUp];

#ifdef LUMBERJACK
#ifdef DEBUG
    [DDLog addLogger:[DDTTYLogger sharedInstance] withLevel:DDLogLevelVerbose];
#else
    [DDLog addLogger:[DDTTYLogger sharedInstance] withLevel:DDLogLevelWarning];
#endif
#endif
    
    NSURL *url = [[NSBundle bundleForClass:[MQTTTestHelpers class]] URLForResource:@"MQTTTestHelpers"
                                                                     withExtension:@"plist"];
    NSDictionary *plist = [NSDictionary dictionaryWithContentsOfURL:url];
    NSDictionary *brokers = plist[@"brokers"];
    NSString *broker = plist[@"broker"];
    MQTTStrict.strict = FALSE;
    self.parameters = brokers[broker];
    self.session = [self newSession];

    self.timer = [NSTimer scheduledTimerWithTimeInterval:1
                                                  target:self
                                                selector:@selector(ticker:)
                                                userInfo:nil
                                                 repeats:true];
}

- (void)tearDown {
    [self.timer invalidate];
    [super tearDown];
}

- (void)ticker:(NSTimer *)timer {
    DDLogVerbose(@"[MQTTTestHelpers] ticker");
}

- (void)timedout:(id)object {
    DDLogWarn(@"[MQTTTestHelpers] timedout");
    self.timedout = TRUE;
}

- (void)newMessage:(MQTTSession *)session data:(NSData *)data onTopic:(NSString *)topic qos:(MQTTQosLevel)qos retained:(BOOL)retained mid:(unsigned int)mid {
    DDLogVerbose(@"[MQTTTestHelpers] newMessage q%d r%d m%d %@:%@",
                 qos, retained, mid, topic, data);
    self.messageMid = mid;
    if (topic && [topic hasPrefix:@"$"]) {
        self.SYSreceived = true;
    }
}

- (void)messageDeliveredV5:(MQTTSession *)session
                     msgID:(UInt16)msgID
                     topic:(NSString *)topic
                      data:(NSData *)data
                       qos:(MQTTQosLevel)qos
                retainFlag:(BOOL)retainFlag
    payloadFormatIndicator:(NSNumber *)payloadFormatIndicator
     messageExpiryInterval:(NSNumber *)messageExpiryInterval
                topicAlias:(NSNumber *)topicAlias
             responseTopic:(NSString *)responseTopic
           correlationData:(NSData *)correlationData
            userProperties:(NSArray<NSDictionary<NSString *,NSString *> *> *)userProperties
               contentType:(NSString *)contentType {
    DDLogVerbose(@"[MQTTTestHelpers] messageDeliveredV5 %d q%d r%d pfa=%@ mei=%@ ta=%@ rt=%@ cd=%@ up=%@ ct=%@ %@:%@",
                 msgID,
                 qos,
                 retainFlag,
                 payloadFormatIndicator,
                 messageExpiryInterval,
                 topicAlias,
                 responseTopic,
                 (correlationData.length < 64 ?
                  correlationData.description :
                  [correlationData subdataWithRange:NSMakeRange(0, 64)].description),
                 userProperties,
                 contentType,
                 topic,
                 (data.length < 64 ?
                  data.description :
                  [data subdataWithRange:NSMakeRange(0, 64)].description));
    self.deliveredMessageMid = msgID;
}

- (void)newMessageV5:(MQTTSession *)session
                data:(NSData *)data
             onTopic:(NSString *)topic
                 qos:(MQTTQosLevel)qos
            retained:(BOOL)retained
                 mid:(unsigned int)mid
payloadFormatIndicator:(NSNumber *)payloadFormatIndicator
messageExpiryInterval:(NSNumber *)messageExpiryInterval
          topicAlias:(NSNumber *)topicAlias
       responseTopic:(NSString *)responseTopic
     correlationData:(NSData *)correlationData
      userProperties:(NSArray<NSDictionary<NSString *,NSString *> *> *)userProperties
         contentType:(NSString *)contentType
subscriptionIdentifiers:(NSArray<NSNumber *> *)subscriptionIdentifiers {
    DDLogVerbose(@"[MQTTTestHelpers] newMessageV5 %d q%d r%d pfa=%@ mei=%@ ta=%@ rt=%@ cd=%@ up=%@ ct=%@ si=%@ %@:%@",
                 mid,
                 qos,
                 retained,
                 payloadFormatIndicator,
                 messageExpiryInterval,
                 topicAlias,
                 responseTopic,
                 (correlationData.length < 64 ?
                  correlationData.description :
                  [correlationData subdataWithRange:NSMakeRange(0, 64)].description),
                 userProperties,
                 contentType,
                 subscriptionIdentifiers,
                 topic,
                 (data.length < 64 ?
                  data.description :
                  [data subdataWithRange:NSMakeRange(0, 64)].description));
    self.messageMid = mid;
    if (!self.subscriptionIdentifiers) {
        self.subscriptionIdentifiers = subscriptionIdentifiers;
    } else {
        if (subscriptionIdentifiers) {
            if (self.subscriptionIdentifiers) {
                self.subscriptionIdentifiers = [self.subscriptionIdentifiers arrayByAddingObjectsFromArray:subscriptionIdentifiers];
            }
        }
    }
    if (topic && [topic hasPrefix:@"$"]) {
        self.SYSreceived = true;
    }
}

- (void)sessionManager:(MQTTSessionManager *)sessionManager
     didReceiveMessage:(NSData *)data
               onTopic:(NSString *)topic
              retained:(BOOL)retained {
    DDLogVerbose(@"[MQTTTestHelpers] didReceiveMessage r%d %@:%@",
                 retained, topic, data);
    if (topic && [topic hasPrefix:@"$"]) {
        self.SYSreceived = true;
    }
}

- (void)handleEvent:(MQTTSession *)session event:(MQTTSessionEvent)eventCode error:(NSError *)error {
    DDLogVerbose(@"[MQTTTestHelpers] handleEvent:%ld error:%@", (long)eventCode, error);
    if (self.event == -1)  {
        self.event = eventCode;
        self.error = error;
    }
}

- (void)connected:(MQTTSession *)session sessionPresent:(BOOL)sessionPresent {
    self.connected = TRUE;
    self.sessionPresent = sessionPresent;
}

- (void)connectionRefused:(MQTTSession *)session error:(NSError *)error {
    self.error = error;
    self.connectionError = error;
}

- (void)sending:(MQTTSession *)session
           type:(MQTTCommandType)type
            qos:(MQTTQosLevel)qos
       retained:(BOOL)retained
          duped:(BOOL)duped
            mid:(UInt16)mid
           data:(NSData *)data {
    DDLogVerbose(@"[MQTTTestHelpers] sending: %02X q%d r%d d%d m%d (%ld) %@",
                 type, qos, retained, duped, mid, data.length,
                 data.length < 64 ? data.description : [data subdataWithRange:NSMakeRange(0, 64)].description);
}

- (void)received:(MQTTSession *)session
            type:(MQTTCommandType)type
             qos:(MQTTQosLevel)qos
        retained:(BOOL)retained
           duped:(BOOL)duped
             mid:(UInt16)mid
            data:(NSData *)data {
    DDLogVerbose(@"[MQTTTestHelpers] received:%d qos:%d retained:%d duped:%d mid:%d (%ld) data:%@",
                 type, qos, retained, duped, mid, data.length,
                 data.length < 64 ? data.description : [data subdataWithRange:NSMakeRange(0, 64)].description);
    self.type = type;
}

- (void)subAckReceivedV5:(MQTTSession *)session
                   msgID:(UInt16)msgID
            reasonString:(NSString *)reasonString
          userProperties:(NSArray<NSDictionary<NSString *,NSString *> *> *)userProperties
             reasonCodes:(NSArray<NSNumber *> *)reasonCodes {
    DDLogInfo(@"[MQTTTestHelpers] subAckReceivedV5 m%d rs=%@ up=%@ rc=%@",
              msgID,
              reasonString,
              userProperties,
              reasonCodes);
    self.subMid = msgID;
    self.qoss = reasonCodes;
}

- (void)unsubAckReceivedV5:(MQTTSession *)session
                     msgID:(UInt16)msgID
              reasonString:(NSString *)reasonString
            userProperties:(NSArray<NSDictionary<NSString *,NSString *> *> *)userProperties
               reasonCodes:(NSArray<NSNumber *> *)reasonCodes {
    DDLogInfo(@"[MQTTTestHelpers] unsubAckReceivedV5 m%d rs=%@ up=%@ rc=%@",
              msgID,
              reasonString,
              userProperties,
              reasonCodes);
    self.unsubMid = msgID;
}

- (NSArray *)clientCerts {
    NSArray *clientCerts = nil;
    if (self.parameters[@"clientp12"] && self.parameters[@"clientp12pass"]) {
        
        NSString *path = [[NSBundle bundleForClass:[MQTTTestHelpers class]] pathForResource:self.parameters[@"clientp12"]
                                                                                     ofType:@"p12"];
        
        clientCerts = [MQTTCFSocketTransport clientCertsFromP12:path passphrase:self.parameters[@"clientp12pass"]];
        if (!clientCerts) {
            DDLogVerbose(@"[MQTTTestHelpers] invalid p12 file");
        }
    }
    return clientCerts;
}

- (MQTTSSLSecurityPolicy *)securityPolicy {
    MQTTSSLSecurityPolicy *securityPolicy = nil;
    
    if ([self.parameters[@"secpol"] boolValue]) {
        if (self.parameters[@"serverCER"]) {
            
            NSString *path = [[NSBundle bundleForClass:[MQTTTestHelpers class]] pathForResource:self.parameters[@"serverCER"]
                                                                                         ofType:@"cer"];
            if (path) {
                NSData *certificateData = [NSData dataWithContentsOfFile:path];
                if (certificateData) {
                    securityPolicy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModeCertificate];
                    securityPolicy.pinnedCertificates = @[certificateData];
                } else {
                    DDLogError(@"[MQTTTestHelpers] error reading cer file");
                }
            } else {
                DDLogError(@"[MQTTTestHelpers] cer file not found");
            }
        } else {
            securityPolicy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModeNone];
        }
        if (self.parameters[@"allowUntrustedCertificates"]) {
            securityPolicy.allowInvalidCertificates = [self.parameters[@"allowUntrustedCertificates"] boolValue];
        }
        if (self.parameters[@"validatesDomainName"]) {
            securityPolicy.validatesDomainName = [self.parameters[@"validatesDomainName"] boolValue];
        }
        if (self.parameters[@"validatesCertificateChain"]) {
            securityPolicy.validatesCertificateChain = [self.parameters[@"validatesCertificateChain"] boolValue];
        }
    }
    return securityPolicy;
}

- (id<MQTTPersistence>)persistence {
    id <MQTTPersistence> persistence;
    
    if (self.parameters[@"CoreData"]) {
        persistence = [[MQTTCoreDataPersistence alloc] init];
    } else {
        persistence = [[MQTTInMemoryPersistence alloc] init];
    }
    
    if (self.parameters[@"persistent"]) {
        persistence.persistent = [self.parameters[@"persistent"] boolValue];
    }
    
    if (self.parameters[@"maxSize"]) {
        persistence.maxSize = [self.parameters[@"maxSize"] unsignedIntValue];
    }
    
    if (self.parameters[@"maxSizeSize"]) {
        persistence.maxWindowSize = [self.parameters[@"maxWindowSize"] boolValue];
    }
    
    if (self.parameters[@"maxMessages"]) {
        persistence.maxMessages = [self.parameters[@"maxMessages"] boolValue];
    }
    
    return persistence;
}

- (id<MQTTTransport>)transport {
    id<MQTTTransport> transport;
    
    if ([self.parameters[@"websocket"] boolValue]) {
        MQTTWebsocketTransport *websocketTransport = [[MQTTWebsocketTransport alloc] init];
        websocketTransport.host = self.parameters[@"host"];
        websocketTransport.port = [self.parameters[@"port"] intValue];
        websocketTransport.tls = [self.parameters[@"tls"] boolValue];
        if (self.parameters[@"path"]) {
            websocketTransport.path = self.parameters[@"path"];
        }
        websocketTransport.allowUntrustedCertificates = [self.parameters[@"allowUntrustedCertificates"] boolValue];

        transport = websocketTransport;
    } else {
        MQTTSSLSecurityPolicy *securityPolicy = [self securityPolicy];
        if (securityPolicy) {
            MQTTSSLSecurityPolicyTransport *sslSecPolTransport = [[MQTTSSLSecurityPolicyTransport alloc] init];
            sslSecPolTransport.host = self.parameters[@"host"];
            sslSecPolTransport.port = [self.parameters[@"port"] intValue];
            sslSecPolTransport.tls = [self.parameters[@"tls"] boolValue];
            sslSecPolTransport.certificates = [self clientCerts];
            sslSecPolTransport.securityPolicy = securityPolicy;

            transport = sslSecPolTransport;
        } else {
            MQTTCFSocketTransport *cfSocketTransport = [[MQTTCFSocketTransport alloc] init];
            cfSocketTransport.host = self.parameters[@"host"];
            cfSocketTransport.port = [self.parameters[@"port"] intValue];
            cfSocketTransport.tls = [self.parameters[@"tls"] boolValue];
            cfSocketTransport.certificates = [self clientCerts];
            transport = cfSocketTransport;
        }
    }
    return transport;
}

- (MQTTSession *)newSession {
    MQTTSession *session = [[MQTTSession alloc] init];
    session.transport = [self transport];
    session.clientId = nil;
    session.sessionExpiryInterval = nil;
    session.userName = self.parameters[@"user"];
    session.password = self.parameters[@"pass"];
    session.protocolLevel = [self.parameters[@"protocollevel"] intValue];
    session.persistence = [self persistence];
    return session;
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
