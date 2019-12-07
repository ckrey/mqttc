Pod::Spec.new do |mqttc|
	mqttc.name         = "mqttc"
	mqttc.version      = "13.1.1"
	mqttc.summary      = "iOS, OSX and tvOS native ObjectiveC MQTT Client Framework"
	mqttc.homepage     = "https://github.com/ckrey/mqttc"
	mqttc.license      = { :type => "EPLv1", :file => "LICENSE" }
	mqttc.author       = { "Christoph Krey" => "c@ckrey.de" }
	mqttc.source       = {
		:git => "https://github.com/ckrey/mqttc.git",
		:tag => "13.1.1",
		:submodules => true
	}

	mqttc.requires_arc = true
	mqttc.platform = :ios, "8.0", :osx, "10.10", :tvos, "9.0"
	mqttc.ios.deployment_target = "8.0"
	mqttc.osx.deployment_target = "10.10"
	mqttc.tvos.deployment_target = "9.0"
	mqttc.default_subspec = 'Core'

	mqttc.subspec 'Core' do |core|
		core.dependency 'mqttc/Min'
		core.dependency 'mqttc/Manager'
	end

	mqttc.subspec 'Min' do |min|
		min.source_files =	"MQTTClient/MQTTClient/MQTTNWTransport.{h,m}",
					"MQTTClient/MQTTClient/MQTTCoreDataPersistence.{h,m}",
					"MQTTClient/MQTTClient/MQTTDecoder.{h,m}",
					"MQTTClient/MQTTClient/MQTTInMemoryPersistence.{h,m}",
					"MQTTClient/MQTTClient/MQTTLog.{h,m}",
					"MQTTClient/MQTTClient/MQTTWill.{h,m}",
					"MQTTClient/MQTTClient/MQTTStrict.{h,m}",
					"MQTTClient/MQTTClient/MQTTClient.h",
					"MQTTClient/MQTTClient/MQTTMessage.{h,m}",
					"MQTTClient/MQTTClient/MQTTPersistence.h",
					"MQTTClient/MQTTClient/MQTTProperties.{h,m}",
					"MQTTClient/MQTTClient/MQTTSession.{h,m}",
					"MQTTClient/MQTTClient/MQTTTransport.{h,m}"
	end

	mqttc.subspec 'MinL' do |minl|
		minl.dependency 'CocoaLumberjack'

		minl.source_files =	"MQTTClient/MQTTClient/MQTTNWTransport.{h,m}",
					"MQTTClient/MQTTClient/MQTTCoreDataPersistence.{h,m}",
					"MQTTClient/MQTTClient/MQTTDecoder.{h,m}",
					"MQTTClient/MQTTClient/MQTTInMemoryPersistence.{h,m}",
					"MQTTClient/MQTTClient/MQTTLog.{h,m}",
					"MQTTClient/MQTTClient/MQTTWill.{h,m}",
					"MQTTClient/MQTTClient/MQTTStrict.{h,m}",
					"MQTTClient/MQTTClient/MQTTClient.h",
					"MQTTClient/MQTTClient/MQTTMessage.{h,m}",
					"MQTTClient/MQTTClient/MQTTPersistence.h",
					"MQTTClient/MQTTClient/MQTTProperties.{h,m}",
					"MQTTClient/MQTTClient/MQTTSession.{h,m}",
					"MQTTClient/MQTTClient/MQTTTransport.{h,m}"
		minl.xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'LUMBERJACK=1' }
	end

	mqttc.subspec 'Manager' do |manager|
		manager.source_files =	"MQTTClient/MQTTClient/MQTTSessionManager.{h,m}", 
					"MQTTClient/MQTTClient/ReconnectTimer.{h,m}",
					"MQTTClient/MQTTClient/ForegroundReconnection.{h,m}"
		manager.dependency 'mqttc/Min'
	end

	mqttc.subspec 'ManagerL' do |managerl|
		managerl.source_files =	"MQTTClient/MQTTClient/MQTTSessionManager.{h,m}", 
					"MQTTClient/MQTTClient/ReconnectTimer.{h,m}", 
					"MQTTClient/MQTTClient/ForegroundReconnection.{h,m}"
		managerl.dependency 'mqttc/MinL'
		managerl.xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'LUMBERJACK=1' }
	end

end
