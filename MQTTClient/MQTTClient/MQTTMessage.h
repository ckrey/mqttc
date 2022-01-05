//
// MQTTMessage.h
// MQTTClient.framework
//
// Copyright © 2013-2022, Christoph Krey. All rights reserved.
//
// based on
//
// Copyright (c) 2011, 2013, 2lemetry LLC
//
// All rights reserved. This program and the accompanying materials
// are made available under the terms of the Eclipse Public License v1.0
// which accompanies this distribution, and is available at
// http://www.eclipse.org/legal/epl-v10.html
//
// Contributors:
//    Kyle Roche - initial API and implementation and/or initial documentation
//

#import <Foundation/Foundation.h>
@class MQTTProperties;
@class MQTTWill;

/**
 Enumeration of MQTT Quality of Service levels
 */
typedef NS_ENUM(UInt8, MQTTQosLevel) {
    MQTTQosLevelAtMostOnce = 0,
    MQTTQosLevelAtLeastOnce = 1,
    MQTTQosLevelExactlyOnce = 2
};

/**
 Enumeration of MQTT SUBSCRIBE retain handling options
 */
typedef NS_ENUM(UInt8, MQTTRetainHandling) {
    MQTTSendRetained = 0,
    MQTTSendRetainedIfNotYetSubscribed = 1,
    MQTTDontSendRetained = 2
};

/**
 Enumeration of MQTT protocol version
 */
typedef NS_ENUM(UInt8, MQTTProtocolVersion) {
    MQTTProtocolVersion0 = 0,
    MQTTProtocolVersion31 = 3,
    MQTTProtocolVersion311 = 4,
    MQTTProtocolVersion50 = 5
};

typedef NS_ENUM(UInt8, MQTTCommandType) {
    MQTT_None = 0,
    MQTTConnect = 1,
    MQTTConnack = 2,
    MQTTPublish = 3,
    MQTTPuback = 4,
    MQTTPubrec = 5,
    MQTTPubrel = 6,
    MQTTPubcomp = 7,
    MQTTSubscribe = 8,
    MQTTSuback = 9,
    MQTTUnsubscribe = 10,
    MQTTUnsuback = 11,
    MQTTPingreq = 12,
    MQTTPingresp = 13,
    MQTTDisconnect = 14,
    MQTTAuth = 15
};

@interface MQTTMessage : NSObject
@property (nonatomic) MQTTCommandType type;
@property (nonatomic) MQTTQosLevel qos;
@property (nonatomic) BOOL retainFlag;
@property (nonatomic) BOOL dupFlag;
@property (nonatomic) UInt16 mid;
@property (strong, nonatomic) NSData *data;
@property (strong, nonatomic) NSNumber *returnCode;
@property (strong, nonatomic) NSNumber *connectAcknowledgeFlags;
@property (strong, nonatomic) MQTTProperties *properties;

/**
 Enumeration of MQTT reason codes
 */

typedef NS_ENUM(NSUInteger, MQTTReturnCode) {
    MQTTAccepted = 0,
    MQTTRefusedUnacceptableProtocolVersion = 1,
    MQTTRefusedIdentiferRejected = 2,
    MQTTRefusedServerUnavailable = 3,
    MQTTRefusedBadUserNameOrPassword = 4,
    MQTTRefusedNotAuthorized = 5,

    MQTTSuccess = 0,
    MQTTDisconnectWithWillMessage = 4,
    MQTTNoSubscriptionExisted = 17,
    MQTTContinueAuthentication = 24,
    MQTTReAuthenticate = 25,
    MQTTUnspecifiedError = 128,
    MQTTMalformedPacket = 129,
    MQTTProtocolError = 130,
    MQTTImplementationSpecificError = 131,
    MQTTUnsupportedProtocolVersion = 132,
    MQTTClientIdentifierNotValid = 133,
    MQTTBadUserNameOrPassword = 134,
    MQTTNotAuthorized = 135,
    MQTTServerUnavailable = 136,
    MQTTServerBusy = 137,
    MQTTBanned = 138,
    MQTTServerShuttingDown = 139,
    MQTTBadAuthenticationMethod = 140,
    MQTTKeepAliveTimeout = 141,
    MQTTSessionTakenOver = 142,
    MQTTTopicFilterInvalid = 143,
    MQTTTopicNameInvalid = 144,
    MQTTPacketIdentifierInUse = 145,
    MQTTPacketIdentifierNotFound = 146,
    MQTTReceiveMaximumExceeded = 147,
    MQTTPacketTooLarge = 149,
    MQTTMessageRateTooHigh = 150,
    MQTTQuotaExceeded = 151,
    MQTTAdministrativeAction = 152,
    MQTTPayloadFormatInvalid = 153,
    MQTTRetainNotSupported = 154,
    MQTTQoSNotSupported = 155,
    MQTTUseAnotherServer = 156,
    MQTTServerMoved = 157,
    MQTTSharedSubscriptionNotSupported = 158,
    MQTTConnectionRateExceeded = 159,
    MQTTSubscriptionIdentifiersNotSupported = 161,
    MQTTWildcardSubscriptionNotSupported = 162
};

// factory methods
+ (MQTTMessage *)connectMessageWithClientId:(NSString*)clientId
                                   userName:(NSString*)userName
                                   password:(NSString*)password
                                  keepAlive:(NSInteger)keeplive
                               cleanSession:(BOOL)cleanSessionFlag
                                       will:(MQTTWill *)will
                              protocolLevel:(MQTTProtocolVersion)protocolLevel
                      sessionExpiryInterval:(NSNumber *)sessionExpiryInterval
                                 authMethod:(NSString *)authMethod
                                   authData:(NSData *)authData
                  requestProblemInformation:(NSNumber *)requestProblemInformation
                 requestResponseInformation:(NSNumber *)requestResponseInformation
                             receiveMaximum:(NSNumber *)receiveMaximum
                          topicAliasMaximum:(NSNumber *)topicAliasMaximum
                             userProperties:(NSArray <NSDictionary <NSString *, NSString *> *> *)userProperties
                          maximumPacketSize:(NSNumber *)maximumPacketSize
;

+ (MQTTMessage *)pingreqMessage;

+ (MQTTMessage *)disconnectMessage:(MQTTProtocolVersion)protocolLevel
                        returnCode:(MQTTReturnCode)returnCode
             sessionExpiryInterval:(NSNumber *)sessionExpiryInterval
                      reasonString:(NSString *)reasonString
                    userProperties:(NSArray <NSDictionary <NSString *, NSString *> *> *)userProperties;

+ (MQTTMessage *)authMessage:(MQTTProtocolVersion)protocolLevel
                  returnCode:(MQTTReturnCode)returnCode
                  authMethod:(NSString *)authMethod
                    authData:(NSData *)authData
                reasonString:(NSString *)reasonString
              userProperties:(NSArray <NSDictionary <NSString *, NSString *> *> *)userProperties;

+ (MQTTMessage *)subscribeMessageWithMessageId:(UInt16)msgId
                                        topics:(NSDictionary *)topics
                                 protocolLevel:(MQTTProtocolVersion)protocolLevel
                       subscriptionIdentifier:(NSNumber *)subscriptionIdentifier
                                userProperties:(NSArray <NSDictionary <NSString *, NSString *> *> *)userProperties;

+ (MQTTMessage *)unsubscribeMessageWithMessageId:(UInt16)msgId
                                          topics:(NSArray *)topics
                                   protocolLevel:(MQTTProtocolVersion)protocolLevel
                                  userProperties:(NSArray <NSDictionary <NSString *, NSString *> *> *)userProperties;

+ (MQTTMessage *)publishMessageWithData:(NSData*)payload
                                onTopic:(NSString*)topic
                                    qos:(MQTTQosLevel)qosLevel
                                  msgId:(UInt16)msgId
                             retainFlag:(BOOL)retain
                                dupFlag:(BOOL)dup
                          protocolLevel:(MQTTProtocolVersion)protocolLevel
                 payloadFormatIndicator:(NSNumber *)payloadFormatIndicator
              messageExpiryInterval:(NSNumber *)messageExpiryInterval
                             topicAlias:(NSNumber *)topicAlias
                          responseTopic:(NSString *)responseTopic
                        correlationData:(NSData *)correlationData
                         userProperties:(NSArray <NSDictionary <NSString *, NSString *> *> *)userProperties
                            contentType:(NSString *)contentType;

+ (MQTTMessage *)pubackMessageWithMessageId:(UInt16)msgId
                              protocolLevel:(MQTTProtocolVersion)protocolLevel
                                 returnCode:(MQTTReturnCode)returnCode
                               reasonString:(NSString *)reasonString
                             userProperties:(NSArray <NSDictionary <NSString *, NSString *> *> *)userProperties;

+ (MQTTMessage *)pubrecMessageWithMessageId:(UInt16)msgId
                              protocolLevel:(MQTTProtocolVersion)protocolLevel
                                 returnCode:(MQTTReturnCode)returnCode
                               reasonString:(NSString *)reasonString
                             userProperties:(NSArray <NSDictionary <NSString *, NSString *> *> *)userProperties;

+ (MQTTMessage *)pubrelMessageWithMessageId:(UInt16)msgId
                              protocolLevel:(MQTTProtocolVersion)protocolLevel
                                 returnCode:(MQTTReturnCode)returnCode
                               reasonString:(NSString *)reasonString
                             userProperties:(NSArray <NSDictionary <NSString *, NSString *> *> *)userProperties;

+ (MQTTMessage *)pubcompMessageWithMessageId:(UInt16)msgId
                               protocolLevel:(MQTTProtocolVersion)protocolLevel
                                  returnCode:(MQTTReturnCode)returnCode
                                reasonString:(NSString *)reasonString
                              userProperties:(NSArray <NSDictionary <NSString *, NSString *> *> *)userProperties;

+ (MQTTMessage *)messageFromData:(NSData *)data
                   protocolLevel:(MQTTProtocolVersion)protocolLevel
             maximumPacketLength:(NSNumber *)maximumPacketLength;

// instance methods
- (instancetype)initWithType:(MQTTCommandType)type;
- (instancetype)initWithType:(MQTTCommandType)type
                        data:(NSData *)data;
- (instancetype)initWithType:(MQTTCommandType)type
                         qos:(MQTTQosLevel)qos
                        data:(NSData *)data;
- (instancetype)initWithType:(MQTTCommandType)type
                         qos:(MQTTQosLevel)qos
                  retainFlag:(BOOL)retainFlag
                     dupFlag:(BOOL)dupFlag
                        data:(NSData *)data;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSData *wireFormat;


@end
