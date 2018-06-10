#!/bin/sh
rm -rf mosquitto
git clone https://github.com/eclipse/mosquitto.git
sed -i .old -e "s/OpenSSL/openssl/" mosquitto/CMakeLists.txt
sed -i .old -e 's/option(WITH_SRV "Include SRV lookup support?" ON)/option(WITH_SRV "Include SRV lookup support?" OFF)/' mosquitto/CMakeLists.txt

#option(WITH_WEBSOCKETS "Include websockets ?" ON)
#if (${WITH_WEBSOCKETS} STREQUAL ON)
#        find_package(libwebsockets REQUIRED)
#        add_definitions("-DWITH_WEBSOCKETS")
#endif (${WITH_WEBSOCKETS} STREQUAL ON)

#export OPENSSL_ROOT_DIR=/usr/local/Cellar/openssl/1.0.2e
export OPENSSL_ROOT_DIR=/usr/local/Cellar/openssl@1.1/1.1.0h
cd mosquitto
mkdir build
cd build
cmake --trace ..
make
src/mosquitto_passwd -c pwdfile user
echo `pwd`
src/mosquitto -c ../mosquitto.conf -v
