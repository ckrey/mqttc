var aedes = require('aedes')()
var http = require('http')
var wss = require('websocket-stream')
var server = require('net').createServer(aedes.handle)
var port = 1883
var wsport = 8080

server.listen(port, function () {
  console.log('server listening on port', port)
})

server = http.createServer((req, res)  => {
})

const ws = wss.createServer({
	server: server
}, aedes.handle)

server.listen(wsport, () => {
  console.log('server listening on websockets port', wsport)
})


aedes.on('publish', function (packet, client) {
  if (client) {
    console.log('message from client', client.id)
  }
})

aedes.on('subscribe', function (subscriptions, client) {
  if (client) {
    console.log('subscribe from client', subscriptions, client.id)
  }
})

aedes.on('client', function (client) {
  console.log('new client', client.id)
})

