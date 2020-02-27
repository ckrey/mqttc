//
//  SwiftTests.swift
//  MQTTClient
//
//  Created by Christoph Krey on 14.01.15.
//  Copyright © 2015-2019 Christoph Krey. All rights reserved.
//

import Foundation

class SwiftTests : MQTTTestHelpers {
    var sessionConnected = false;
    var sessionError = false;
    var sessionReceived = false;
    var sessionSubAcked = false;
    
    override func setUp() {
        super.setUp();
    }
    
    override func tearDown() {
        super.tearDown();
    }
    
    func testSwiftSubscribe() {
        print("testSwiftSubscribe")

        if ((parameters.value(forKey: "websocket")) as AnyObject).boolValue != true {

            session = MQTTSession()
            session!.delegate = self;

            let transport = MQTTNWTransport()
            transport.host = (parameters.value(forKey: "host") as! String)
            transport.port = UInt32(parameters.value(forKey: "port") as! Int)
            transport.tls = parameters.value(forKey: "tls") as! Bool
            session!.transport = transport
            session!.connect(connectHandler: { (error) in
                //
            })

            while !sessionConnected && !sessionError {
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 1))
            }

            session!.subscribe(toTopicV5: "#", at: .atMostOnce, noLocal: false, retainAsPublished: false, retainHandling: .sendRetained, subscriptionIdentifier: 0, userProperties: nil, subscribeHandler: { (error, reasonString, userProperties, reasonCodes) in
                //
            })

            while sessionConnected && !sessionError && !sessionSubAcked {
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 1))
            }

            session!.publishDataV5("sent from Xcode 8.0 using Swift".data(using: String.Encoding.utf8, allowLossyConversion: false)!,
                                   onTopic: TOPIC,
                                   retain: false,
                                   qos: .atMostOnce,
                                   payloadFormatIndicator: nil,
                                   messageExpiryInterval: nil,
                                   topicAlias: nil,
                                   responseTopic: nil,
                                   correlationData: nil,
                                   userProperties: nil,
                                   contentType: nil,
                                   publishHandler: { (error, reasonString, userProperties, reasonCode) in
                                    //
            })

            while sessionConnected && !sessionError && !sessionReceived {
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 1))
            }

            session!.close(with: .success,
                           sessionExpiryInterval: nil,
                           reasonString: nil,
                           userProperties: nil,
                           disconnectHandler: { (error) in
                            //
            })
        }
    }
    
    func testSwiftSessionManager() {
        print("testSwiftSessionManager")

        if ((parameters.value(forKey: "websocket")) as AnyObject).boolValue != true {
            let m = MQTTSessionManager()
            m.delegate = self
            
            m.connect(to: (parameters.value(forKey: "host") as! String),
                      port: parameters.value(forKey: "port") as! UInt32,
                      tls:  parameters.value(forKey: "tls") as! Bool,
                      keepalive: 60,
                      clean: true,
                      auth: false,
                      user: nil,
                      pass: nil,
                      will: nil,
                      withClientId: nil,
                      allowUntrustedCertificates: parameters.value(forKey: "allowUntrustedCertificates") as! Bool,
                      certificates: self.clientCerts(),
                      protocolLevel: .version311,
                      runLoop: RunLoop.current
            )
            
            while (m.state != .connected) {
                print("waiting for connect \(m.state)");
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 1))
            }

            m.disconnect()
        }
    }
    
    override func handleEvent(_ session: MQTTSession, event eventCode: MQTTSessionEvent, error: Error!) {
        switch eventCode {
        case .connected:
            sessionConnected = true
        case .connectionClosed:
            sessionConnected = false
        default:
            sessionError = true
        }
    }

    override func newMessageV5(_ session: MQTTSession, data: Data, onTopic topic: String, qos: MQTTQosLevel, retained: Bool, mid: UInt32, payloadFormatIndicator: NSNumber?, messageExpiryInterval: NSNumber?, topicAlias: NSNumber?, responseTopic: String?, correlationData: Data?, userProperties: [[String : String]]?, contentType: String?, subscriptionIdentifiers: [NSNumber]?) {
        sessionReceived = true;
    }
    
    override func subAckReceivedV5(_ session: MQTTSession, msgID: UInt16, reasonString: String?, userProperties: [[String : String]]?, reasonCodes: [NSNumber]?) {
        sessionSubAcked = true;
    }
}
