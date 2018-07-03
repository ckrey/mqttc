## [moquette](http://andsel.github.io/moquette/)

> Try the demo instance
> Point your MQTT client to `broker.moquette.io`

```
$ mosquitto_sub -d -v -t '#' -h 'broker.moquette.io'
```
does not work! Need to register 

```
wget https://bintray.com/artifact/download/andsel/generic/moquette-distribution-0.11.tar
tar xvf moquette-distribution-0.11.tar
cd bin
mkdir config
wget https://raw.githubusercontent.com/andsel/moquette/master/distribution/src/main/resources/moquette.conf config/moquette.conf
./moquette-distribution
```

From Source:
```
git clone https://github.com/andsel/moquette.git
cd moquette/distribution
../gradlew clean distribution:distMoquetteTar
tar xvzf moquette-0.12-SNAPSHOT.tar.gz
cd moquette-0.12-SNAPSHOT
cd bin
./moquette.sh
```







