//
//  MQTTClientTests.m
//  MQTTClientTests
//
//  Created by Christoph Krey on 13.01.14.
//  Copyright © 2014-2019 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "MQTTLog.h"
#import "MQTTStrict.h"
#import "MQTTTestHelpers.h"
#import "MQTTNWTransport.h"

@interface MQTTClientTests : MQTTTestHelpers
@property (strong, nonatomic) NSTimer *processingSimulationTimer;
@property (nonatomic) int sent;
@property (nonatomic) int received;
@property (nonatomic) int processed;

@end

@implementation MQTTClientTests

- (void)setUp {
    [super setUp];
    [MQTTLog setLogLevel:DDLogLevelVerbose];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_init {
    [self connect];
    XCTAssertEqual(self.session.status, MQTTSessionStatusConnected, @"Not Connected %ld %@", (long)self.session.status, self.error);
    [self shutdownWithReturnCode:MQTTSuccess sessionExpiryInterval:nil reasonString:nil userProperties:nil];
}

- (void)test_init_zero_clientId_clean {
    self.session.clientId = @"";
    self.session.cleanSessionFlag = TRUE;
    [self connect];
    XCTAssert(!self.timedout, @"timeout");
    if (self.event == MQTTSessionEventConnected) {
        // ok
    } else if (self.event == MQTTSessionEventConnectionRefused) {
        XCTAssert(self.error.code == 0x02, @"error = %@", self.error);
    } else {
        XCTFail(@"Not Connected %ld %@", (long)self.event, self.error);
    }
    [self shutdownWithReturnCode:MQTTSuccess sessionExpiryInterval:nil reasonString:nil userProperties:nil];
}

- (void)test_example {
    MQTTNWTransport *transport = [[MQTTNWTransport alloc] init];
    transport.host = self.parameters[@"host"];
    transport.port = [self.parameters[@"port"] unsignedIntValue];
    
    self.session = [[MQTTSession alloc] init];
    self.session.transport = transport;
    
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
    [self shutdownWithReturnCode:MQTTSuccess sessionExpiryInterval:nil reasonString:nil userProperties:nil];
}


/*
 * [MQTT-3.1.3-8]
 * If the Client supplies a zero-byte ClientId with CleanSession set to 0, the Server MUST
 * respond to the CONNECT Packet with a CONNACK return code 0x02 (Identifier rejected) and
 * then close the Network Connection.
 * [MQTT-3.1.3-9]
 * If the Server rejects the ClientId it MUST respond to the CONNECT Packet with a
 * CONNACK return code 0x02 (Identifier rejected) and then close the Network Connection.
 */
- (void)test_init_zero_clientId_noclean_MQTT_3_1_3_8_MQTT_3_1_3_9 {
    if ([self.parameters[@"protocollevel"] integerValue] == MQTTProtocolVersion50) {
        return;
    }
    self.session.clientId = @"";
    self.session.cleanSessionFlag = FALSE;
    [self connect];
    XCTAssert(!self.timedout, @"timeout");
    XCTAssertEqual(self.event, MQTTSessionEventConnectionRefused, @"MQTTSessionEventConnectionRefused %@", self.error);
    XCTAssert(self.error.code == 0x02, @"error = %@", self.error);
    [self shutdownWithReturnCode:MQTTSuccess sessionExpiryInterval:nil reasonString:nil userProperties:nil];
}

/*
 * [MQTT-3.1.3-8]
 * If the Client supplies a zero-byte ClientId with CleanSession set to 0, the Server MUST
 * respond to the CONNECT Packet with a CONNACK return code 0x02 (Identifier rejected) and
 * then close the Network Connection.
 * [MQTT-3.1.3-9]
 * If the Server rejects the ClientId it MUST respond to the CONNECT Packet with a
 * CONNACK return code 0x02 (Identifier rejected) and then close the Network Connection.
 */
- (void)test_init_zero_clientId_noclean_strict {
    MQTTStrict.strict = TRUE;
    self.session = [self newSession];
    @try {
        self.session.cleanSessionFlag = FALSE;
        self.session.clientId = @"";
        [self.session connectWithConnectHandler:nil];
        XCTFail(@"Should not get here but throw exception before");
    } @catch (NSException *exception) {
        //
    } @finally {
        //
    }
}

- (void)test_init_long_clientId {
    self.session.clientId = @"123456789012345678901234";
    [self connect];
    XCTAssert(!self.timedout, @"timeout");
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    [self shutdownWithReturnCode:MQTTSuccess sessionExpiryInterval:nil reasonString:nil userProperties:nil];
}

- (void)test_init_nonrestricted_clientId {
    self.session.clientId = @"12345678901234567890123";
    [self connect];
    XCTAssert(!self.timedout, @"timeout");
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    [self shutdownWithReturnCode:MQTTSuccess sessionExpiryInterval:nil reasonString:nil userProperties:nil];
}

- (void)test_init_no_clientId {
    self.session = [self session];
    self.session.clientId = nil;
    [self connect];
    XCTAssert(!self.timedout, @"timeout");
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    [self shutdownWithReturnCode:MQTTSuccess sessionExpiryInterval:nil reasonString:nil userProperties:nil];
}

/*
 * [MQTT-3.1.2-8]
 * If the Will Flag is set to 1 this indicates that, if the Connect request is accepted, a Will
 * Message MUST be stored on the Server and associated with the Network Connection. The Will Message
 * MUST be published when the Network Connection is subsequently closed unless the Will Message has
 * been deleted by the Server on receipt of a DISCONNECT Packet.
 * [MQTT-3.1.2-16]
 * If the Will Flag is set to 1 and If Will Retain is set to 0, the Server MUST publish the Will
 * Message as a non-retained message.
 */
- (void)test_connect_will_non_retained_MQTT_3_1_2_8_MQTT_3_1_2_16 {
    MQTTSession *subscribingSession = [self newSession];
    subscribingSession.clientId = @"MQTTClientSub";
    
    [subscribingSession connectWithConnectHandler:^(NSError * _Nullable error) {
        if (error) {
            XCTFail(@"no connection for sub");
            return;
        } else {
            [subscribingSession subscribeToTopicV5:TOPIC
                                           atLevel:MQTTQosLevelAtMostOnce
                                           noLocal:false
                                 retainAsPublished:false
                                    retainHandling:MQTTSendRetained
                            subscriptionIdentifier:0
                                    userProperties:nil
                                  subscribeHandler:nil];
        }
    }];
    
    self.session = [self newSession];
    self.session.will = [[MQTTWill alloc] initWithTopic:TOPIC
                                                   data:[@"will-qos0-non-retained" dataUsingEncoding:NSUTF8StringEncoding]
                                             retainFlag:NO
                                                    qos:MQTTQosLevelAtMostOnce
                                      willDelayInterval:nil
                                 payloadFormatIndicator:nil
                                  messageExpiryInterval:nil
                                            contentType:nil
                                          responseTopic:nil
                                        correlationData:nil
                                         userProperties:nil];
    
    [self connect];
    XCTAssert(!self.timedout, @"timeout");
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    
    [self shutdownWithReturnCode:MQTTDisconnectWithWillMessage
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];

    [subscribingSession closeWithReturnCode:MQTTSuccess
                      sessionExpiryInterval:@0
                               reasonString:nil
                             userProperties:nil
                          disconnectHandler:nil];
}

/*
 * [MQTT-3.1.2-8]
 * If the Will Flag is set to 1 this indicates that, if the Connect request is accepted, a Will
 * Message MUST be stored on the Server and associated with the Network Connection. The Will Message
 * MUST be published when the Network Connection is subsequently closed unless the Will Message has
 * been deleted by the Server on receipt of a DISCONNECT Packet.
 * [MQTT-3.1.2-17]
 * If the Will Flag is set to 1 and If Will Retain is set to 1, the Server MUST publish the Will
 * Message as a retained message.
 */
- (void)test_connect_will_retained_MQTT_3_1_2_8_MQTT_3_1_2_17 {
    MQTTSession *subscribingSession = [self newSession];
    subscribingSession.delegate = self;
    [subscribingSession connectWithConnectHandler:^(NSError * _Nullable error) {
        if (error) {
            XCTFail(@"no connection for sub");
            return;
        } else {
            [subscribingSession subscribeToTopicV5:TOPIC
                                           atLevel:MQTTQosLevelAtMostOnce
                                           noLocal:false
                                 retainAsPublished:false
                                    retainHandling:MQTTSendRetained
                            subscriptionIdentifier:0
                                    userProperties:nil
                                  subscribeHandler:nil];
        }
    }];
    
    
    self.session = [self newSession];
    self.session.will = [[MQTTWill alloc] initWithTopic:TOPIC
                                                   data:[@"will-qos0-retained" dataUsingEncoding:NSUTF8StringEncoding]
                                             retainFlag:TRUE
                                                    qos:MQTTQosLevelAtMostOnce
                                      willDelayInterval:nil
                                 payloadFormatIndicator:nil
                                  messageExpiryInterval:nil
                                            contentType:nil
                                          responseTopic:nil
                                        correlationData:nil
                                         userProperties:nil];
    
    [self connect];
    XCTAssert(!self.timedout, @"timeout");
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);

    self.timedout = FALSE;
    self.newMessages = 0;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:self.timeoutValue];

    [self shutdownWithReturnCode:MQTTDisconnectWithWillMessage
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];

    if ([self.parameters[@"protocollevel"] integerValue] == MQTTProtocolVersion50) {
        while (!self.newMessages &&
               !self.timedout) {
            DDLogVerbose(@"[test_connect_will_retained_MQTT_3_1_2_8_MQTT_3_1_2_17] waiting for will");
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
    }

    // clean retained will
    [subscribingSession publishDataV5:[[NSData alloc] init]
                        onTopic:TOPIC
                         retain:TRUE
                            qos:MQTTQosLevelAtMostOnce
         payloadFormatIndicator:nil
          messageExpiryInterval:nil
                     topicAlias:nil
                  responseTopic:nil
                correlationData:nil
                 userProperties:nil
                    contentType:nil
                 publishHandler:nil];

    [subscribingSession closeWithReturnCode:MQTTSuccess
                      sessionExpiryInterval:@0
                               reasonString:nil
                             userProperties:nil
                          disconnectHandler:nil];

    XCTAssert(!self.timedout, @"timeout");
}

/*
 * [MQTT-3.1.2-14]
 * If the Will Flag is set to 1, the value of Will QoS can be 0 (0x00), 1 (0x01), or 2 (0x02). It MUST NOT be 3 (0x03).
 */
- (void)test_connect_will_flagged_but_qos_3_MQTT_3_1_2_14 {
    self.session.will = [[MQTTWill alloc] initWithTopic:TOPIC
                                                   data:[@"test_connect_will_flagged_but_qos_3_MQTT_3_1_2_14" dataUsingEncoding:NSUTF8StringEncoding]
                                             retainFlag:NO
                                                    qos:3
                                      willDelayInterval:nil
                                 payloadFormatIndicator:nil
                                  messageExpiryInterval:nil
                                            contentType:nil
                                          responseTopic:nil
                                        correlationData:nil
                                         userProperties:nil];
    
    [self connect];
    XCTAssert(!self.timedout, @"timeout");
    XCTAssertEqual(self.event, MQTTSessionEventConnectionClosedByBroker,
                   @"Protocol violation not detected by broker %ld %@", (long)self.event, self.error);
    
    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}

/*
 * [MQTT-3.1.4-2]
 * If the ClientId represents a Client already connected to the Server then the Server MUST disconnect the existing Client.
 */

- (void)test_disconnect_when_same_clientID_connects_MQTT_3_1_4_2 {
    self.session.clientId = @"MQTTClient";
    
    [self connect];
    XCTAssert(!self.timedout, @"timeout");
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    
    
    MQTTSession *sameSession = [self newSession];
    sameSession.clientId = @"MQTTClient";
    
    [sameSession connectWithConnectHandler:^(NSError * _Nullable error) {
        if (error) {
            XCTFail(@"no connection for sub");
            return;
        }
    }];
    
    [self shutdownWithReturnCode:MQTTSuccess sessionExpiryInterval:nil reasonString:nil userProperties:nil];
    [sameSession closeWithReturnCode:MQTTSuccess
               sessionExpiryInterval:@0
                        reasonString:nil
                      userProperties:nil
                   disconnectHandler:nil];
}

/*
 * [MQTT-3.1.3-1]
 * These fields, if present, MUST appear in the order Client Identifier, Will Topic, Will Message, User Name, Password.
 */
- (void)test_connect_all_fields_MQTT_3_1_3_1 {
    self.session.clientId = @"ClientID";
    self.session.will = [[MQTTWill alloc] initWithTopic:@"MQTTClient/will-qos0"
                                                   data:[@"will-qos0" dataUsingEncoding:NSUTF8StringEncoding]
                                             retainFlag:FALSE
                                                    qos:MQTTQosLevelAtMostOnce
                                      willDelayInterval:nil
                                 payloadFormatIndicator:nil
                                  messageExpiryInterval:nil
                                            contentType:nil
                                          responseTopic:nil
                                        correlationData:nil
                                         userProperties:nil];

    [self connect];
    XCTAssert(!self.timedout, @"timeout");
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);

    [self shutdownWithReturnCode:MQTTDisconnectWithWillMessage
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];
}

/*
 * [MQTT-3.1.2-1]
 * If the protocol name is incorrect the Server MAY disconnect the Client, or it MAY
 * continue processing the CONNECT packet in accordance with some other specification.
 * In the latter case, the Server MUST NOT continue to process the CONNECT packet in line with this specification.
 */
- (void)test_connect_protocollevel3__MQTT_3_1_2_1 {
    self.session.protocolLevel = MQTTProtocolVersion31;
    [self connect];
    XCTAssert(!self.timedout, @"timeout");
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"No MQTTSessionEventConnected %@", self.error);
    [self shutdownWithReturnCode:MQTTSuccess sessionExpiryInterval:nil reasonString:nil userProperties:nil];
}

/*
 * [MQTT-3.1.2-1]
 * If the protocol name is incorrect the Server MAY disconnect the Client, or it MAY
 * continue processing the CONNECT packet in accordance with some other specification.
 * In the latter case, the Server MUST NOT continue to process the CONNECT packet in line with this specification.
 */
- (void)test_connect_protocollevel4__MQTT_3_1_2_1 {
    self.session.protocolLevel = MQTTProtocolVersion311;
    [self connect];
    XCTAssert(!self.timedout, @"timeout");
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"No MQTTSessionEventConnected %@", self.error);
    [self shutdownWithReturnCode:MQTTSuccess sessionExpiryInterval:nil reasonString:nil userProperties:nil];
}

/*
 * [MQTT-3.1.2-1]
 * If the protocol name is incorrect the Server MAY disconnect the Client, or it MAY
 * continue processing the CONNECT packet in accordance with some other specification.
 * In the latter case, the Server MUST NOT continue to process the CONNECT packet in line with this specification.
 */
- (void)test_connect_protocollevel5__MQTT_3_1_2_1 {
    self.session.protocolLevel = MQTTProtocolVersion50;
    [self connect];
    XCTAssert(!self.timedout, @"timeout");
    if (self.session.protocolLevel != MQTTProtocolVersion50) {
        XCTAssertEqual(self.event, MQTTSessionEventConnectionClosedByBroker, @"session not closed %@", self.error);
    }
    [self shutdownWithReturnCode:MQTTSuccess sessionExpiryInterval:nil reasonString:nil userProperties:nil];
}

/*
 * [MQTT-3.1.2-2]
 * The Server MUST respond to the CONNECT Packet with a CONNACK return code
 * 0x01 (unacceptable protocol level) and then disconnect the Client if the Protocol
 * Level is not supported by the Server.
 * [MQTT-3.2.2-5]
 * If a server sends a CONNACK packet containing a non-zero return code it MUST then close the Network Connection.
 */
- (void)test_connect_illegal_protocollevel88_MQTT_3_1_2_2_MQTT_3_2_2_5 {
    self.session.protocolLevel = 88;
    [self connect];
    XCTAssert(!self.timedout, @"timeout");
    XCTAssert(self.event == MQTTSessionEventConnectionClosedByBroker ||
              (self.connectionError.code == MQTTRefusedUnacceptableProtocolVersion),
              @"event = %ld error = %@", (long)self.event, self.connectionError);
    [self shutdownWithReturnCode:MQTTSuccess sessionExpiryInterval:nil reasonString:nil userProperties:nil];
}

/*
 * [MQTT-3.1.2-2]
 * The Server MUST respond to the CONNECT Packet with a CONNACK return code
 * 0x01 (unacceptable protocol level) and then disconnect the Client if the Protocol
 * Level is not supported by the Server.
 * [MQTT-3.2.2-5]
 * If a server sends a CONNACK packet containing a non-zero return code it MUST then close the Network Connection.
 */
- (void)test_connect_illegal_protocollevel88_strict {
    MQTTStrict.strict = TRUE;
    self.session = [self newSession];
    @try {
        self.session.protocolLevel = 88;
        [self.session connectWithConnectHandler:nil];
        XCTFail(@"Should not get here but throw exception before");
    } @catch (NSException *exception) {
        //;
    } @finally {
        //
    }
}

/*
 * [MQTT-3.1.2-1]
 * If the protocol name is incorrect the Server MAY disconnect the Client, or it MAY
 * continue processing the CONNECT packet in accordance with some other specification.
 * In the latter case, the Server MUST NOT continue to process the CONNECT packet in line with this specification.
 */
- (void)test_connect_illegal_protocollevel0_and_protocolname_MQTT_3_1_2_1 {
    self.session = [self newSession];
    self.session.protocolLevel = 0;
    [self connect];
    XCTAssert(!self.timedout, @"timeout");
    if (self.event == MQTTSessionEventConnectionClosedByBroker ||
        self.event == MQTTSessionEventConnectionError ||
        (self.event == MQTTSessionEventConnectionRefused && self.error && self.error.code == 0x01)) {
        // Success, although week definition
    } else {
        XCTFail(@"connect returned event:%ld, error:%@", (long)self.event, self.error);
    }
    [self shutdownWithReturnCode:MQTTSuccess sessionExpiryInterval:nil reasonString:nil userProperties:nil];
}

/*
 * [MQTT-3.1.0-1]
 * After a Network Connection is established by a Client to a Server, the first Packet sent from the
 * Client to the Server MUST be a CONNECT Packet.
 */
- (void)test_first_packet_MQTT_3_1_0_1 {
    DDLogVerbose(@"can't test [MQTT-3.1.0-1]");
}

- (void)test_ping {
    self.session.keepAliveInterval = [self.parameters[@"timeout"] intValue] / 2;
    
    [self connect];
    XCTAssert(!self.timedout, @"timeout");
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"No MQTTSessionEventConnected %@", self.error);
    
    self.event = -1;
    self.type = 0xff;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:[self.parameters[@"timeout"] intValue]];
    
    while (!self.timedout && self.event == -1 && self.type == 0xff) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    XCTAssertEqual(self.type, MQTTPingresp, @"No PingResp received %u", self.type);
    XCTAssertNotEqual(self.event, MQTTSessionEventConnectionClosed, @"MQTTSessionEventConnectionClosed %@", self.error);
    XCTAssertNotEqual(self.event, MQTTSessionEventProtocolError, @"MQTTSessionEventProtocolError %@", self.error);
    XCTAssertNotEqual(self.event, MQTTSessionEventConnectionClosedByBroker, @"MQTTSessionEventConnectionClosedByBroker %@", self.error);
    XCTAssert(!self.timedout, @"Timeout 200%% keepalive");
    [self shutdownWithReturnCode:MQTTSuccess sessionExpiryInterval:nil reasonString:nil userProperties:nil];
}

/*
 * [MQTT-3.1.2-5]
 * After the disconnection of a Session that had CleanSession set to 0,
 * the Server MUST store further QoS 1 and QoS 2 messages that match any
 * subscriptions that the client had at the time of disconnection as part of the Session state .
 */
- (void)test_pub_sub_no_cleansession_qos2_MQTT_3_1_2_5 {
    [self no_cleansession:MQTTQosLevelExactlyOnce];
}
- (void)test_pub_sub_no_cleansession_qos1_MQTT_3_1_2_5 {
    [self no_cleansession:MQTTQosLevelAtLeastOnce];
}
- (void)test_pub_sub_no_cleansession_qos0_MQTT_3_1_2_5 {
    [self no_cleansession:MQTTQosLevelAtMostOnce];
}

/*
 * [MQTT-4.3.3-2]
 * In the QoS 2 delivery protocol, the Receiver
 ** MUST respond with a PUBREC containing the Packet Identifier from the incoming PUBLISH Packet,
 *  having accepted ownership of the Application Message.
 ** Until it has received the corresponding PUBREL packet, the Receiver MUST acknowledge any
 *  subsequent PUBLISH packet with the same Packet Identifier by sending a PUBREC. It MUST NOT
 *  cause duplicate messages to be delivered to any onward recipients in this case.
 ** MUST respond to a PUBREL packet by sending a PUBCOMP packet containing the same Packet Identifier as the PUBREL.
 ** After it has sent a PUBCOMP, the receiver MUST treat any subsequent PUBLISH packet that
 *  contains that Packet Identifier as being a new publication.
 */

- (void)test_pub_sub_cleansession_qos2_MQTT_4_3_3_2 {
    [self cleansession:MQTTQosLevelExactlyOnce];
}
- (void)test_pub_sub_cleansession_qos1_MQTT_4_3_3_2 {
    [self cleansession:MQTTQosLevelAtLeastOnce];
}
- (void)test_pub_sub_cleansession_qos0_MQTT_4_3_3_2 {
    [self cleansession:MQTTQosLevelAtMostOnce];
}


/*
 * [MQTT-3.14.1-1]
 * The Server MUST validate that reserved bits are set to zero and disconnect the Client if they are not zero.
 */
- (void)test_disconnect_wrong_flags_MQTT_3_14_1_1 {
    DDLogVerbose(@"can't test [MQTT-3.14.1-1]");
    /*
     '[MQTT-4.3.2-2]',
     '[MQTT-4.3.2-3]',
     
     */
}

/*
 * [MQTT-3.1.4-5]
 * If the Server rejects the CONNECT, it MUST NOT process any data sent by the Client after the CONNECT Packet.
 */
- (void)test_dont_process_after_reject_MQTT_3_1_4_5 {
    self.session.protocolLevel = 88;
    [self connect];
    
    [self.session subscribeToTopicV5:TOPIC
                             atLevel:MQTTQosLevelAtMostOnce
                             noLocal:false
                   retainAsPublished:false
                      retainHandling:MQTTSendRetained
              subscriptionIdentifier:0 userProperties:nil subscribeHandler:nil];
    
    [self.session publishDataV5:[@"Data" dataUsingEncoding:NSUTF8StringEncoding]
                        onTopic:TOPIC
                         retain:NO
                            qos:MQTTQosLevelAtMostOnce
         payloadFormatIndicator:nil
          messageExpiryInterval:nil
                     topicAlias:nil
                  responseTopic:nil
                correlationData:nil
                 userProperties:nil
                    contentType:nil
                 publishHandler:nil];
    
    XCTAssert(!self.timedout, @"timeout");

    XCTAssert(self.event == MQTTSessionEventConnectionClosedByBroker ||
              self.event == MQTTSessionEventConnectionRefused,
                   @"Protocol violation not detected by broker %ld %@", (long)self.event, self.error);

    [self shutdownWithReturnCode:MQTTSuccess sessionExpiryInterval:nil reasonString:nil userProperties:nil];
}

#define SYSTOPIC @"$SYS/#"

- (void)test_systopic {
    [self connect];
    XCTAssert(!self.timedout, @"timeout");
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"MQTTSessionEventConnected %@", self.error);
    
    self.timedout = FALSE;
    self.newMessages = 0 ;

    [self.session subscribeToTopicV5:SYSTOPIC
                             atLevel:MQTTQosLevelAtMostOnce
                             noLocal:false
                   retainAsPublished:false
                      retainHandling:MQTTSendRetained
              subscriptionIdentifier:0
                      userProperties:nil
                    subscribeHandler:nil];

    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:[self.parameters[@"timeout"] intValue]];
    
    while (!self.newMessages && !self.timedout) {
        DDLogVerbose(@"waiting for incoming %@ messages (%ld)",
                     SYSTOPIC, self.newMessages);
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }

    [NSObject cancelPreviousPerformRequestsWithTarget:self];

    [self shutdownWithReturnCode:MQTTSuccess
           sessionExpiryInterval:nil
                    reasonString:nil
                  userProperties:nil];

    XCTAssert(!self.timedout, @"timeout");
}


#define PROCESSING_NUMBER 20
#define PROCESSING_INTERVAL 0.1
#define PROCESSING_TIMEOUT 30

- (void)test_throttling_incoming_q0 {
    [self connect];
    XCTAssert(!self.timedout, @"timeout");
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"MQTTSessionEventConnected %@", self.error);
    
    self.processed = 0;
    self.received = 0;
    
    self.processingSimulationTimer = [NSTimer scheduledTimerWithTimeInterval:PROCESSING_INTERVAL
                                                                      target:self
                                                                    selector:@selector(processingSimulation:)
                                                                    userInfo:nil
                                                                     repeats:true];
    [self.session subscribeToTopicV5:TOPIC
                             atLevel:MQTTQosLevelAtMostOnce
                             noLocal:false
                   retainAsPublished:false
                      retainHandling:MQTTSendRetained
              subscriptionIdentifier:0
                      userProperties:nil
                    subscribeHandler:nil];
    
    for (int i = 0; i < PROCESSING_NUMBER; i++) {
        NSString *payload = [NSString stringWithFormat:@"Data %d", i];
        [self.session publishDataV5:[payload dataUsingEncoding:NSUTF8StringEncoding]
                            onTopic:TOPIC
                             retain:false
                                qos:MQTTQosLevelAtMostOnce
             payloadFormatIndicator:nil
              messageExpiryInterval:nil
                         topicAlias:nil
                      responseTopic:nil
                    correlationData:nil
                     userProperties:nil
                        contentType:nil
                     publishHandler:nil];
    }
    
    self.timedout = FALSE;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:PROCESSING_TIMEOUT];
    
    while ((self.processed != self.received || self.received == 0) && !self.timedout) {
        DDLogVerbose(@"[test_throttling_incoming_q0] waiting for processing %lu/%lu/%d",
                     (unsigned long)self.processed, (unsigned long)self.received, PROCESSING_NUMBER);
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    
    XCTAssert(!self.timedout, @"timeout");
    [self.processingSimulationTimer invalidate];
    
    [self shutdownWithReturnCode:MQTTSuccess sessionExpiryInterval:nil reasonString:nil userProperties:nil];
}

- (void)test_throttling_incoming_q1 {
    [self connect];
    
    XCTAssert(!self.timedout, @"timeout");
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"MQTTSessionEventConnected %@", self.error);
    
    self.processed = 0;
    self.received = 0;
    
    self.processingSimulationTimer =
    [NSTimer scheduledTimerWithTimeInterval:PROCESSING_INTERVAL
                                     target:self
                                   selector:@selector(processingSimulation:)
                                   userInfo:nil
                                    repeats:true];
    [self.session subscribeToTopicV5:TOPIC
                             atLevel:MQTTQosLevelAtLeastOnce
                             noLocal:false
                   retainAsPublished:false
                      retainHandling:MQTTSendRetained
              subscriptionIdentifier:0
                      userProperties:nil
                    subscribeHandler:nil];
    
    for (int i = 0; i < PROCESSING_NUMBER; i++) {
        NSString *payload = [NSString stringWithFormat:@"Data %d", i];
        [self.session publishDataV5:[payload dataUsingEncoding:NSUTF8StringEncoding]
                            onTopic:TOPIC
                             retain:false
                                qos:MQTTQosLevelAtLeastOnce
             payloadFormatIndicator:nil
              messageExpiryInterval:nil
                         topicAlias:nil
                      responseTopic:nil
                    correlationData:nil
                     userProperties:nil
                        contentType:nil
                     publishHandler:nil];
    }
    
    self.timedout = FALSE;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:PROCESSING_TIMEOUT];
    
    while ((self.processed != self.received || self.received != PROCESSING_NUMBER) && !self.timedout) {
        DDLogVerbose(@"[test_throttling_incoming_q1] waiting for processing %lu/%lu/%d",
                     (unsigned long)self.processed, (unsigned long)self.received, PROCESSING_NUMBER);
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    
    XCTAssert(!self.timedout, @"timeout");
    [self.processingSimulationTimer invalidate];
    
    [self shutdownWithReturnCode:MQTTSuccess sessionExpiryInterval:nil reasonString:nil userProperties:nil];
}

- (void)test_throttling_incoming_q2 {
    [self connect];
    XCTAssert(!self.timedout, @"timeout");
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"MQTTSessionEventConnected %@", self.error);
    
    self.processed = 0;
    self.received = 0;
    
    self.processingSimulationTimer = [NSTimer scheduledTimerWithTimeInterval:PROCESSING_INTERVAL
                                                                      target:self
                                                                    selector:@selector(processingSimulation:)
                                                                    userInfo:nil
                                                                     repeats:true];
    [self.session subscribeToTopicV5:TOPIC
                             atLevel:MQTTQosLevelExactlyOnce
                             noLocal:false
                   retainAsPublished:false
                      retainHandling:MQTTSendRetained
              subscriptionIdentifier:0
                      userProperties:nil
                    subscribeHandler:nil];
    
    for (int i = 0; i < PROCESSING_NUMBER; i++) {
        NSString *payload = [NSString stringWithFormat:@"Data %d", i];
        [self.session publishDataV5:[payload dataUsingEncoding:NSUTF8StringEncoding]
                            onTopic:TOPIC
                             retain:false
                                qos:MQTTQosLevelExactlyOnce
             payloadFormatIndicator:nil
              messageExpiryInterval:nil
                         topicAlias:nil
                      responseTopic:nil
                    correlationData:nil
                     userProperties:nil
                        contentType:nil
                     publishHandler:nil];
    }
    
    self.timedout = FALSE;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:PROCESSING_TIMEOUT];
    
    while ((self.processed != self.received || self.received != PROCESSING_NUMBER) && !self.timedout) {
        DDLogVerbose(@"[test_throttling_incoming_q2] waiting for processing %lu/%lu/%d",
                     (unsigned long)self.processed, (unsigned long)self.received, PROCESSING_NUMBER);
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    
    XCTAssert(!self.timedout, @"timeout");
    [self.processingSimulationTimer invalidate];
    
    [self shutdownWithReturnCode:MQTTSuccess sessionExpiryInterval:nil reasonString:nil userProperties:nil];
}

- (void)processingSimulation:(id)userInfo {
    DDLogVerbose(@"processingSimulation %lu/%lu", (unsigned long)self.processed, (unsigned long)self.received);
    if (self.received > self.processed) {
        self.processed++;
    }
}

#pragma mark helpers

- (void)no_cleansession:(MQTTQosLevel)qos {
    DDLogVerbose(@"Cleaning topic");
    
    MQTTSession *sendingSession = [self newSession];
    sendingSession.clientId = @"MQTTClientPub";
    [sendingSession connectWithConnectHandler:^(NSError * _Nullable error) {
        if (error) {
            XCTFail(@"no connection for pub");
            return;
        }
    }];
    [self.session publishDataV5:[[NSData alloc] init]
                        onTopic:TOPIC
                         retain:true
                            qos:qos
         payloadFormatIndicator:nil
          messageExpiryInterval:nil
                     topicAlias:nil
                  responseTopic:nil
                correlationData:nil
                 userProperties:nil
                    contentType:nil
                 publishHandler:nil];
    
    DDLogVerbose(@"Clearing old subs");
    self.session = [self newSession];
    self.session.clientId = @"MQTTClientSub";
    [self connect];
    [self shutdownWithReturnCode:MQTTSuccess sessionExpiryInterval:nil reasonString:nil userProperties:nil];

    DDLogVerbose(@"Subscribing to topic");
    self.session = [self newSession];
    self.session.clientId = @"MQTTClientSub";
    self.session.cleanSessionFlag = FALSE;
    
    [self connect];
    [self.session subscribeToTopicV5:TOPIC
                             atLevel:qos
                             noLocal:false
                   retainAsPublished:false
                      retainHandling:MQTTSendRetained
              subscriptionIdentifier:0
                      userProperties:nil
                    subscribeHandler:nil];
    
    [self shutdownWithReturnCode:MQTTSuccess sessionExpiryInterval:nil reasonString:nil userProperties:nil];

    for (int i = 1; i < BULK; i++) {
        DDLogVerbose(@"publishing to topic %d", i);
        NSString *payload = [NSString stringWithFormat:@"payload %d", i];
        [sendingSession publishDataV5:[payload dataUsingEncoding:NSUTF8StringEncoding]
                              onTopic:TOPIC
                               retain:false
                                  qos:qos
               payloadFormatIndicator:nil
                messageExpiryInterval:nil
                           topicAlias:nil
                        responseTopic:nil
                      correlationData:nil
                       userProperties:nil
                          contentType:nil
                       publishHandler:nil];
    }
    [sendingSession closeWithReturnCode:MQTTSuccess
                  sessionExpiryInterval:@0
                           reasonString:nil
                         userProperties:nil
                      disconnectHandler:nil];
    
    DDLogVerbose(@"receiving from topic");
    self.session = [self newSession];
    self.session.clientId = @"MQTTClientSub";
    self.session.cleanSessionFlag = FALSE;
    
    [self connect];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"No MQTTSessionEventConnected %@", self.error);
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.timedout = FALSE;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:[self.parameters[@"timeout"] intValue]];
    
    while (!self.timedout) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    
    [self shutdownWithReturnCode:MQTTSuccess sessionExpiryInterval:nil reasonString:nil userProperties:nil];
}

- (void)cleansession:(MQTTQosLevel)qos {
    DDLogVerbose(@"Cleaning topic");
    MQTTSession *sendingSession = [self newSession];
    sendingSession.clientId = @"MQTTClientPub";
    
    [sendingSession connectWithConnectHandler:^(NSError * _Nullable error) {
        if (error) {
            XCTFail(@"no connection for pub");
            return;
        }
    }];
    
    [sendingSession publishDataV5:[[NSData alloc] init]
                          onTopic:TOPIC
                           retain:true
                              qos:qos
           payloadFormatIndicator:nil
            messageExpiryInterval:nil
                       topicAlias:nil
                    responseTopic:nil
                  correlationData:nil
                   userProperties:nil
                      contentType:nil
                   publishHandler:nil];
    
    
    DDLogVerbose(@"Clearing old subs");
    self.session = [self newSession];
    self.session.clientId = @"MQTTClientSub";
    [self connect];
    [self shutdownWithReturnCode:MQTTSuccess sessionExpiryInterval:nil reasonString:nil userProperties:nil];

    DDLogVerbose(@"Subscribing to topic");
    self.session = [self newSession];
    self.session.clientId = @"MQTTClientSub";
    [self connect];
    [self.session subscribeToTopicV5:TOPIC
                             atLevel:qos
                             noLocal:false
                   retainAsPublished:false
                      retainHandling:MQTTSendRetained
              subscriptionIdentifier:0
                      userProperties:nil
                    subscribeHandler:nil];
    
    for (int i = 1; i < BULK; i++) {
        DDLogVerbose(@"publishing to topic %d", i);
        NSString *payload = [NSString stringWithFormat:@"payload %d", i];
        [sendingSession publishDataV5:[payload dataUsingEncoding:NSUTF8StringEncoding]
                              onTopic:TOPIC
                               retain:false
                                  qos:qos
               payloadFormatIndicator:nil
                messageExpiryInterval:nil
                           topicAlias:nil
                        responseTopic:nil
                      correlationData:nil
                       userProperties:nil
                          contentType:nil
                       publishHandler:nil];
        
    }
    [sendingSession closeWithReturnCode:MQTTSuccess
                  sessionExpiryInterval:@0
                           reasonString:nil
                         userProperties:nil
                      disconnectHandler:nil];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.timedout = FALSE;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:[self.parameters[@"timeout"] intValue]];
    
    while (!self.timedout) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    
    [self shutdownWithReturnCode:MQTTSuccess sessionExpiryInterval:nil reasonString:nil userProperties:nil];
}

- (BOOL)newMessageWithFeedbackV5:(MQTTSession *)session
                            data:(NSData *)data
                         onTopic:(NSString *)topic
                             qos:(MQTTQosLevel)qos
                        retained:(BOOL)retained
                             mid:(unsigned int)mid
          payloadFormatIndicator:(NSNumber *)payloadFormatIndicator
           messageExpiryInterval:(NSNumber *)messageExpiryInterval
                      topicAlias:(NSNumber *)topicAlias
                   responseTopic:(NSString *)responseTopic
                 correlationData:(NSData *)correlationData userProperties:(NSArray<NSDictionary<NSString *,NSString *> *> *)userProperties
                     contentType:(NSString *)contentType
         subscriptionIdentifiers:(NSArray<NSNumber *> *)subscriptionIdentifiers {
    DDLogVerbose(@"newMessageWithFeedback(%lu):%@ onTopic:%@ qos:%d retained:%d mid:%d", (unsigned long)self.processed, data, topic, qos, retained, mid);
    if (self.processed > self.received - 10) {
        if (!retained && [topic isEqualToString:TOPIC]) {
            self.received++;
        }
        return true;
    } else {
        return false;
    }
}

@end
