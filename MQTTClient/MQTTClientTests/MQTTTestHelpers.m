//
//  MQTTTestHelpers.m
//  MQTTClient
//
//  Created by Christoph Krey on 09.12.15.
//  Copyright © 2015-2020 Christoph Krey. All rights reserved.
//

#import "MQTTLog.h"
#import "MQTTStrict.h"
#import "MQTTTestHelpers.h"
#import "MQTTNWTransport.h"
#import "MQTTInMemoryPersistence.h"
#import "MQTTCoreDataPersistence.h"

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
    self.newMessages = 0;
    self.retainedMessages = 0;
    self.deliveredMessages = 0;
}

- (void)tearDown {
    [self.timer invalidate];
    [super tearDown];
}

- (void)ticker:(NSTimer *)timer {
    DDLogVerbose(@"[MQTTTestHelpers] ticker");
}

- (void)timedout:(id)object {
    DDLogVerbose(@"[MQTTTestHelpers] timedout");
    self.timedout = TRUE;
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
    self.deliveredMessages++;
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
    DDLogVerbose(@"[MQTTTestHelpers] newMessageV5 %d q%d r%d pfa=%@ mei=%@ ta=%@ rt=%@ cd=%@ up=%@ ct=%@ si=%@ %@:(%ld)%@",
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
                 data.length,
                 (data.length < 64 ?
                  data.description :
                  [data subdataWithRange:NSMakeRange(0, 64)].description));
    self.messageMid = mid;
    self.newMessages++;
    if (retained) {
        self.retainedMessages++;
    }
    
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
        self.SYSreceived++;
    }
}

- (void)sessionManager:(MQTTSessionManager *)sessionManager
     didReceiveMessage:(NSData *)data
               onTopic:(NSString *)topic
              retained:(BOOL)retained {
    DDLogVerbose(@"[MQTTTestHelpers] didReceiveMessage r%d %@:%@",
                 retained, topic, data);
    if (topic && [topic hasPrefix:@"$"]) {
        self.SYSreceived++;
    }
}

- (void)handleEvent:(MQTTSession *)session event:(MQTTSessionEvent)eventCode error:(NSError *)error {
    DDLogVerbose(@"[MQTTTestHelpers] handleEvent:%ld error:%@", (long)eventCode, error);
    if (self.event == -1)  {
        self.event = eventCode;
        self.error = error;
    }
}

- (void)protocolError:(MQTTSession *)session error:(NSError *)error {
    DDLogVerbose(@"[MQTTTestHelpers] protocolError: %@", error);
    if (self.event == -1)  {
        self.event = MQTTSessionEventProtocolError;
        self.error = error;
    }
}

- (void)connected:(MQTTSession *)session sessionPresent:(BOOL)sessionPresent {
    self.connected = TRUE;
    self.sessionPresent = sessionPresent;
    
    DDLogVerbose(@"[MQTTTestHelpers] connected to %@:%d, "
                 "sP:%d, "
                 "bMPS:%@, "
                 "kA:%d, "
                 "sKA:%@, "
                 "eKA:%d, "
                 "bAM:%@, "
                 "bAD:%@, "
                 "bRI:%@, "
                 "sR:%@, "
                 "rS:%@, "
                 "bSEI:%@, "
                 "bRM:%@, "
                 "bTAM:%@, "
                 "mQ:%@, "
                 "rA:%@, "
                 "bUP:%@, "
                 "wSA:%@, "
                 "sIA:%@, "
                 "sSA:%@",
                 session.transport.host,
                 session.transport.port,
                 session.sessionPresent,
                 session.brokerMaximumPacketSize,
                 session.keepAliveInterval,
                 session.serverKeepAlive,
                 session.effectiveKeepAlive,
                 session.brokerAuthMethod,
                 session.brokerAuthData,
                 session.brokerResponseInformation,
                 session.serverReference,
                 session.reasonString,
                 session.brokerSessionExpiryInterval,
                 session.brokerReceiveMaximum,
                 session.brokerTopicAliasMaximum,
                 session.maximumQoS,
                 session.retainAvailable,
                 session.brokerUserProperties,
                 session.wildcardSubscriptionAvailable,
                 session.subscriptionIdentifiersAvailable,
                 session.sharedSubscriptionAvailable
                 );
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
    DDLogVerbose(@"[MQTTTestHelpers] subAckReceivedV5 m%d rs=%@ up=%@ rc=%@",
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
    DDLogVerbose(@"[MQTTTestHelpers] unsubAckReceivedV5 m%d rs=%@ up=%@ rc=%@",
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
        
        clientCerts = [MQTTTransport clientCertsFromP12:path passphrase:self.parameters[@"clientp12pass"]];
        if (!clientCerts) {
            DDLogVerbose(@"[MQTTTestHelpers] invalid p12 file");
        }
    }
    return clientCerts;
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
    
    MQTTNWTransport *nwTransport = [[MQTTNWTransport alloc] init];
    
    nwTransport.ws = [self.parameters[@"websocket"] boolValue];
    if (self.parameters[@"allowUntrustedCertificates"]) {
        nwTransport.allowUntrustedCertificates = [self.parameters[@"allowUntrustedCertificates"] boolValue];
    }
    transport = nwTransport;
    transport.host = self.parameters[@"host"];
    transport.port = [self.parameters[@"port"] intValue];
    transport.tls = [self.parameters[@"tls"] boolValue];
    transport.certificates = [self clientCerts];
    
    return transport;
}

- (MQTTSession *)newSession {
    MQTTSession *session = [[MQTTSession alloc] init];
    session.transport = [self transport];
    session.clientId = nil;
    session.sessionExpiryInterval = nil;
    self.timeoutValue = [self.parameters[@"timeout"] doubleValue];
    session.userName = self.parameters[@"user"];
    session.password = self.parameters[@"pass"];
    session.protocolLevel = [self.parameters[@"protocollevel"] intValue];
    session.persistence = [self persistence];
    return session;
}

-(void)connect {
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

    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)shutdownWithReturnCode:(MQTTReturnCode)returnCode
         sessionExpiryInterval:(NSNumber *)sessionExpiryInterval
                  reasonString:(NSString *)reasonString
                userProperties:(NSArray <NSDictionary <NSString *, NSString *> *> *)userProperties {
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
}

@end
