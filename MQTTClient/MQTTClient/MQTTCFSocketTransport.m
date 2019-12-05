//
//  MQTTCFSocketTransport.m
//  MQTTClient
//
//  Created by Christoph Krey on 06.12.15.
//  Copyright © 2015-2019 Christoph Krey. All rights reserved.
//

#import "MQTTCFSocketTransport.h"

#import "MQTTLog.h"

@interface MQTTCFSocketTransport()
@property (strong, nonatomic) MQTTCFSocketEncoder *encoder;
@property (strong, nonatomic) MQTTCFSocketDecoder *decoder;
@end

@implementation MQTTCFSocketTransport
@synthesize state;
@synthesize delegate;
@synthesize runLoop;
@synthesize runLoopMode;
@dynamic host;
@dynamic port;

- (instancetype)init {
    self = [super init];
    self.voip = false;
    return self;
}

- (void)open {
    DDLogVerbose(@"[MQTTCFSocketTransport] open");
    self.state = MQTTTransportOpening;

    NSError* connectError;

    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;

    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)self.host, self.port, &readStream, &writeStream);

    CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
    CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
    
    if (self.tls) {
        NSMutableDictionary *sslOptions = [[NSMutableDictionary alloc] init];
        
        sslOptions[(NSString*)kCFStreamSSLLevel] = (NSString *)kCFStreamSocketSecurityLevelNegotiatedSSL;
        
        if (self.certificates) {
            sslOptions[(NSString *)kCFStreamSSLCertificates] = self.certificates;
        }
        
        if(!CFReadStreamSetProperty(readStream, kCFStreamPropertySSLSettings, (__bridge CFDictionaryRef)(sslOptions))){
            connectError = [NSError errorWithDomain:@"MQTT"
                                               code:errSSLInternal
                                           userInfo:@{NSLocalizedDescriptionKey : @"Fail to init ssl input stream!"}];
        }
        if(!CFWriteStreamSetProperty(writeStream, kCFStreamPropertySSLSettings, (__bridge CFDictionaryRef)(sslOptions))){
            connectError = [NSError errorWithDomain:@"MQTT"
                                               code:errSSLInternal
                                           userInfo:@{NSLocalizedDescriptionKey : @"Fail to init ssl output stream!"}];
        }
    }
    
    if(!connectError){
        self.encoder.delegate = nil;
        self.encoder = [[MQTTCFSocketEncoder alloc] init];
        self.encoder.stream = CFBridgingRelease(writeStream);
        self.encoder.runLoop = self.runLoop;
        self.encoder.runLoopMode = self.runLoopMode;
        self.encoder.delegate = self;
        if (self.voip) {
            [self.encoder.stream setProperty:NSStreamNetworkServiceTypeVoIP forKey:NSStreamNetworkServiceType];
        }
        [self.encoder open];
        
        self.decoder.delegate = nil;
        self.decoder = [[MQTTCFSocketDecoder alloc] init];
        self.decoder.stream =  CFBridgingRelease(readStream);
        self.decoder.runLoop = self.runLoop;
        self.decoder.runLoopMode = self.runLoopMode;
        self.decoder.delegate = self;
        if (self.voip) {
            [self.decoder.stream setProperty:NSStreamNetworkServiceTypeVoIP forKey:NSStreamNetworkServiceType];
        }
        [self.decoder open];
        
    } else {
        [self close];
    }
}

- (void)close {
    DDLogVerbose(@"[MQTTCFSocketTransport] close");
    self.state = MQTTTransportClosing;

    if (self.encoder) {
        [self.encoder close];
        self.encoder.delegate = nil;
    }
    
    if (self.decoder) {
        [self.decoder close];
        self.decoder.delegate = nil;
    }
}

- (BOOL)send:(nonnull NSData *)data {
    return [self.encoder send:data];
}

- (void)decoder:(MQTTCFSocketDecoder *)sender didReceiveMessage:(nonnull NSData *)data {
    [self.delegate mqttTransport:self didReceiveMessage:data];
}

- (void)decoder:(MQTTCFSocketDecoder *)sender didFailWithError:(NSError *)error {
    //self.state = MQTTTransportClosing;
    //[self.delegate mqttTransport:self didFailWithError:error];
}
- (void)encoder:(MQTTCFSocketEncoder *)sender didFailWithError:(NSError *)error {
    self.state = MQTTTransportClosing;
    [self.delegate mqttTransport:self didFailWithError:error];
}

- (void)decoderdidClose:(MQTTCFSocketDecoder *)sender {
    self.state = MQTTTransportClosed;
    [self.delegate mqttTransportDidClose:self];
}
- (void)encoderdidClose:(MQTTCFSocketEncoder *)sender {
    //self.state = MQTTTransportClosed;
    //[self.delegate mqttTransportDidClose:self];
}

- (void)decoderDidOpen:(MQTTCFSocketDecoder *)sender {
    //self.state = MQTTTransportOpen;
    //[self.delegate mqttTransportDidOpen:self];
}
- (void)encoderDidOpen:(MQTTCFSocketEncoder *)sender {
    self.state = MQTTTransportOpen;
    [self.delegate mqttTransportDidOpen:self];
}

@end
