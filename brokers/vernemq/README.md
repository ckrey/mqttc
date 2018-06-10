# vernemq
virtualbox
debian 9 (stretch)

```
sudo apt-get install git
git clone https://github.com/erlio/vernemq.git
git branch mqtt5-preview
sudo apt-get install make
sudo apt-get install erlang
sudo apt-get install gcc
sudo apt-get install g++
sudo apt-get install libssl-dev
cd vernemq
make rel
_build/default/rel/vernemq/bin/vernemq console

```

you may want to change

> listener.tcp.default = 0.0.0.0:1883

in `_build/default/rel/vernemq/etc/vernemq.conf`
