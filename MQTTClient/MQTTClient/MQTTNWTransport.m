//
//  MQTTNWTransport.m
//  MQTTClient
//
//  Created by Christoph Krey on 01.10.19.
//  Copyright © 2019 Christoph Krey. All rights reserved.
//

#import "MQTTNWTransport.h"
#import "MQTTLog.h"
#import <os/availability.h>

API_AVAILABLE(ios(13.0), macos(10.15))
@interface MQTTNWTransport ()
@property (strong, nonatomic) NSURLSession *session;
@property (strong, nonatomic) NSURLSessionStreamTask *streamTask;
@property (strong, nonatomic) NSURLSessionWebSocketTask *webSocketTask;
@end

@implementation MQTTNWTransport

- (instancetype)init {
    self = [super init];

    self.host = @"localhost";
    self.port = 1883;
    //self.path = @"/mqtt";
    self.tls = false;
    self.ws = false;
    //self.allowUntrustedCertificates = false;
    //self.pinnedCertificates = nil;
    //self.headers = nil;

    return self;
}


- (void)open {
    DDLogVerbose(@"[MQTTNWTransport] session");

#define EPHEMERAL 1
#ifdef EPHEMERAL
    self.session =
    [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]
                                  delegate:self
                             delegateQueue:nil];
#else
    self.session =
    [NSURLSession sharedSession];
#endif

    DDLogVerbose(@"[MQTTNWTransport] task");
    if (self.ws) {
        NSString *urlString = [NSString stringWithFormat:@"ws%@://%@:%u/mqtt",
                               self.tls ? @"s": @"",
                               self.host,
                               (unsigned int)self.port];
        NSURL *url = [NSURL URLWithString:urlString];
        if (@available(iOS 13.0, macOS 10.15, *)) {
            self.webSocketTask = [self.session webSocketTaskWithURL:url protocols:@[@"mqtt"]];
        } else {
            // Fallback on earlier versions
        }
    } else {
        self.streamTask = [self.session streamTaskWithHostName:self.host
                                                          port:self.port];
    }

    DDLogVerbose(@"[MQTTNWTransport] resume");
    if (self.ws) {
        [self.webSocketTask resume];
    } else {
        [self.streamTask resume];
    }

    if (!self.ws) {
        if (self.tls) {
            [self.streamTask startSecureConnection];
        }
    }

    [self.delegate mqttTransportDidOpen:self];
    [self read];
}

- (void)read {
    DDLogVerbose(@"[MQTTNWTransport] read");
    if (self.ws) {
        if (@available(iOS 13.0, macOS 10.15, *)) {
            [self.webSocketTask receiveMessageWithCompletionHandler:^(NSURLSessionWebSocketMessage * _Nullable message, NSError * _Nullable error) {
                DDLogVerbose(@"[MQTTNWTransport] receiveMessage %@ %@", message, error);
                if (error) {
                    [self.delegate mqttTransport:self didFailWithError:error];
                } else {
                    [self.delegate mqttTransport:self didReceiveMessage:message.data];
                    [self read];
                }
            }];
        } else {
            // Fallback on earlier versions
        }
    } else {
        [self.streamTask readDataOfMinLength:0
                                   maxLength:1024
                                     timeout:0
                           completionHandler:
         ^(NSData * _Nullable data, BOOL atEOF, NSError * _Nullable error) {
            DDLogVerbose(@"[MQTTNWTransport] read %@ %d %@", data, atEOF, error);
            if (atEOF || error || !data) {
                [self.delegate mqttTransport:self didFailWithError:error];
            } else {
                [self.delegate mqttTransport:self didReceiveMessage:data];
                [self read];
            }
        }];
    }
}

- (void)close {
    if (self.ws) {
        [self.webSocketTask cancel];
    } else {
        [self.streamTask cancel];
    }
}

- (BOOL)send:(NSData *)data {
    if (self.ws) {
        if (@available(iOS 13.0, macOS 10.15, *)) {
            DDLogVerbose(@"[MQTTNWTransport] send ws %ld %@",
                         (long)self.webSocketTask.state,
                         self.webSocketTask.error);

            NSURLSessionWebSocketMessage *message = [[NSURLSessionWebSocketMessage alloc] initWithData:data];
            [self.webSocketTask sendMessage:message
                          completionHandler:^(NSError * _Nullable error) {
                DDLogVerbose(@"[MQTTNWTransport] sendMessage error %@", error);
            }];
        } else {
            // Fallback on earlier versions
        }
    } else {
        DDLogVerbose(@"[MQTTNWTransport] send stream %ld %@",
                     (long)self.streamTask.state,
                     self.streamTask.error);
        [self.streamTask writeData:data
                           timeout:0
                 completionHandler:^(NSError * _Nullable error) {
            DDLogVerbose(@"[MQTTNWTransport] send error %@", error);
        }];
    }
    return TRUE;
}

- (void)URLSession:(NSURLSession *)session
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    DDLogVerbose(@"[MQTTNWTransport] didReceiveChallenge %@ %@ %@",
                 challenge, challenge.protectionSpace, challenge.proposedCredential);

    if (self.ignoreInvalidCertificates) {
        if (self.ignoreHostname ||
            [challenge.protectionSpace.host isEqualToString:self.host]) {
            NSURLCredential *sc = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            completionHandler(NSURLSessionAuthChallengeUseCredential, sc);
            return;
        }
    }
    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, challenge.proposedCredential);
}

@end
