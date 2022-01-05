//
//  MQTTInMemoryPersistence.m
//  MQTTClient
//
//  Created by Christoph Krey on 22.03.15.
//  Copyright © 2015-2022 Christoph Krey. All rights reserved.
//

#import <mqttc/MQTTInMemoryPersistence.h>

#import <mqttc/MQTTLog.h>

@implementation MQTTInMemoryFlow
@synthesize clientId;
@synthesize incomingFlag;
@synthesize retainedFlag;
@synthesize commandType;
@synthesize qosLevel;
@synthesize messageId;
@synthesize topic;
@synthesize data;
@synthesize deadline;
@synthesize payloadFormatIndicator;
@synthesize messageExpiryInterval;
@synthesize topicAlias;
@synthesize responseTopic;
@synthesize correlationData;
@synthesize userProperties;
@synthesize contentType;
@synthesize subscriptionIdentifiers;

@end

@interface MQTTInMemoryPersistence()
@end

static NSMutableDictionary *clientIds;

@implementation MQTTInMemoryPersistence
@synthesize maxSize;
@synthesize persistent;
@synthesize maxMessages;
@synthesize maxWindowSize;

- (MQTTInMemoryPersistence *)init {
    self = [super init];
    self.maxMessages = MQTT_MAX_MESSAGES;
    self.maxWindowSize = MQTT_MAX_WINDOW_SIZE;
    @synchronized(clientIds) {
        if (!clientIds) {
            clientIds = [[NSMutableDictionary alloc] init];
        }
    }
    return self;
}

- (NSUInteger)windowSize:(NSString *)clientId {
    NSUInteger windowSize = 0;
    NSArray *flows = [self allFlowsforClientId:clientId
                                  incomingFlag:NO];
    for (MQTTInMemoryFlow *flow in flows) {
        if ((flow.commandType).intValue != MQTT_None) {
            windowSize++;
        }
    }
    return windowSize;
}

- (MQTTInMemoryFlow *)storeMessageForClientId:(NSString *)clientId
                                        topic:(NSString *)topic
                                         data:(NSData *)data
                                   retainFlag:(BOOL)retainFlag
                                          qos:(MQTTQosLevel)qos
                                        msgId:(UInt16)msgId
                                 incomingFlag:(BOOL)incomingFlag
                                  commandType:(UInt8)commandType
                                     deadline:(NSDate *)deadline
                       payloadFormatIndicator:(NSNumber *)payloadFormatIndicator
                        messageExpiryInterval:(NSNumber *)messageExpiryInterval
                                   topicAlias:(NSNumber *)topicAlias
                                responseTopic:(NSString *)responseTopic
                              correlationData:(NSData *)correlationData
                               userProperties:(NSArray<NSDictionary<NSString *,NSString *> *> *)userProperties
                                  contentType:(NSString *)contentType
                      subscriptionIdentifiers:(NSData *)subscriptionIdentifers {
    @synchronized(clientIds) {
        
        if (([self allFlowsforClientId:clientId incomingFlag:incomingFlag].count <= self.maxMessages)) {
            MQTTInMemoryFlow *flow = (MQTTInMemoryFlow *)[self createFlowforClientId:clientId
                                                                        incomingFlag:incomingFlag
                                                                           messageId:msgId];
            flow.topic = topic;
            flow.data = data;
            flow.retainedFlag = @(retainFlag);
            flow.qosLevel = @(qos);
            flow.commandType = [NSNumber numberWithUnsignedInteger:commandType];
            flow.deadline = deadline;
            flow.payloadFormatIndicator = payloadFormatIndicator;
            flow.messageExpiryInterval = messageExpiryInterval;
            flow.topicAlias = topicAlias;
            flow.correlationData = correlationData;
            if (userProperties && [NSJSONSerialization isValidJSONObject:userProperties]) {
                NSData *uP = [NSJSONSerialization dataWithJSONObject:userProperties options:0 error:nil];
                flow.userProperties = uP;
            } else {
                flow.userProperties = nil;
            }
            flow.contentType = contentType;
            flow.subscriptionIdentifiers = subscriptionIdentifers;

            return flow;
        } else {
            return nil;
        }
    }
}

- (void)deleteFlow:(MQTTInMemoryFlow *)flow {
    @synchronized(clientIds) {
        
        NSMutableDictionary *clientIdFlows = clientIds[flow.clientId];
        if (clientIdFlows) {
            NSMutableDictionary *clientIdDirectedFlow = clientIdFlows[flow.incomingFlag];
            if (clientIdDirectedFlow) {
                [clientIdDirectedFlow removeObjectForKey:flow.messageId];
            }
        }
    }
}

- (void)deleteAllFlowsForClientId:(NSString *)clientId {
    @synchronized(clientIds) {
        
        DDLogInfo(@"[MQTTInMemoryPersistence] deleteAllFlowsForClientId %@", clientId);
        [clientIds removeObjectForKey:clientId];
    }
}

- (void)sync {
    //
}

- (NSArray *)allFlowsforClientId:(NSString *)clientId
                    incomingFlag:(BOOL)incomingFlag {
    @synchronized(clientIds) {
        
        NSMutableArray *flows = nil;
        NSMutableDictionary *clientIdFlows = clientIds[clientId];
        if (clientIdFlows) {
            NSMutableDictionary *clientIdDirectedFlow = clientIdFlows[@(incomingFlag)];
            if (clientIdDirectedFlow) {
                flows = [NSMutableArray array];
                NSArray *keys = [clientIdDirectedFlow.allKeys sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES]]];
                for (id key in keys) {
                    [flows addObject:clientIdDirectedFlow[key]];
                }
            }
        }
        return flows;
    }
}

- (MQTTInMemoryFlow *)flowforClientId:(NSString *)clientId
                         incomingFlag:(BOOL)incomingFlag
                            messageId:(UInt16)messageId {
    @synchronized(clientIds) {
        
        MQTTInMemoryFlow *flow = nil;
        
        NSMutableDictionary *clientIdFlows = clientIds[clientId];
        if (clientIdFlows) {
            NSMutableDictionary *clientIdDirectedFlow = clientIdFlows[@(incomingFlag)];
            if (clientIdDirectedFlow) {
                flow = clientIdDirectedFlow[[NSNumber numberWithUnsignedInteger:messageId]];
            }
        }
        
        return flow;
    }
}

- (MQTTInMemoryFlow *)createFlowforClientId:(NSString *)clientId
                               incomingFlag:(BOOL)incomingFlag
                                  messageId:(UInt16)messageId {
    @synchronized(clientIds) {
        NSMutableDictionary *clientIdFlows = clientIds[clientId];
        if (!clientIdFlows) {
            clientIdFlows = [[NSMutableDictionary alloc] init];
            clientIds[clientId] = clientIdFlows;
        }
        
        NSMutableDictionary *clientIdDirectedFlow = clientIdFlows[@(incomingFlag)];
        if (!clientIdDirectedFlow) {
            clientIdDirectedFlow = [[NSMutableDictionary alloc] init];
            clientIdFlows[@(incomingFlag)] = clientIdDirectedFlow;
        }
        
        MQTTInMemoryFlow *flow = [[MQTTInMemoryFlow alloc] init];
        flow.clientId = clientId;
        flow.incomingFlag = @(incomingFlag);
        flow.messageId = [NSNumber numberWithUnsignedInteger:messageId];
        
        clientIdDirectedFlow[[NSNumber numberWithUnsignedInteger:messageId]] = flow;
        
        return flow;
    }
}

@end
