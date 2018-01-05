MQTT-Client-Framework mqttc
===========================

an Objective-C native MQTT Framework http://mqtt.org

* [Introduction](http://www.hivemq.com/blog/mqtt-client-library-encyclopedia-mqtt-client-framework)

### Tested with a long list of brokers

* mosquitto
* paho
* rabbitmq
* hivemq
* rsmb
* mosca
* vernemq
* emqtt
* moquette
* ActiveMQ
* Apollo
* CloudMQTT
* aws
* hbmqtt (MQTTv311 only, limitations)
* [aedes](https://github.com/mcollina/aedes) 
* [mqttswift](https://github.com/ckrey/mqttswift)

### As a CocoaPod

Use the CocoaPod mqttc! 

Add this to your Podfile:

```
pod 'mqttc'
```
which is a short for
```
pod 'mqttc/Min'
pod 'mqttc/Manager'
```

The Manager subspec includes the MQTTSessionManager class.

Additionally add this subspec if you want to use MQTT over Websockets:

```
pod 'mqttc/Websocket'
```

If you want to do your logging with CocoaLumberjack (my suggestion), use
```
pod 'mqttc/MinL'
pod 'mqttc/ManagerL'
pod 'mqttc/WebsocketL'
```
instead.

### Comparison MQTT Clients for iOS (incomplete)

|Wrapper|---|----|MQTTKit  |Marquette|Moscapsule|Musqueteer|MQTT-Client|MqttSDK|CocoaMQTT|
|-------|---|----|---------|---------|----------|----------|-----------|-------|---------|
|       |   |    |Obj-C    |Obj-C    |Swift     |Obj-C     |Obj-C      |Obj-C  |Swift    |
|Library|IBM|Paho|Mosquitto|Mosquitto|Mosquitto |Mosquitto |native     |native |native   |


