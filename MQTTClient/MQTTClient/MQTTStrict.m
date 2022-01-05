//
//  MQTTStrict.m
//  MQTTClient
//
//  Created by Christoph Krey on 24.07.17.
//  Copyright ©2017-2022 Christoph Krey. All rights reserved.
//

#import <mqttc/MQTTStrict.h>

@implementation MQTTStrict
static BOOL internalStrict = false;

+ (BOOL)strict {
    return internalStrict;
}

+ (void)setStrict:(BOOL)strict {
    internalStrict = strict;
}

@end
