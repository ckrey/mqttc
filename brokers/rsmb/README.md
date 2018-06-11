
sed -i .old 's/\${GCC}/${GCC} -D_XOPEN_SOURCE -DIPV6_ADD_MEMBERSHIP=IPV6_JOIN_GROUP/' org.eclipse.mosquitto.rsmb/rsmb/src/Makefile
cd org.eclipse.mosquitto.rsmb/rsmb/src
make
./broker

