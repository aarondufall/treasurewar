sys = require('sys')
require('./lib/models/game')
require('./lib/models/order')
require('jade')
_ = require('underscore')
express = require('express')
app = express()
server = require('http').createServer(app)
assets = require('connect-assets')

#----------------------------------------
# Config Settings
DEFAULT_SERVER_PORT = 8000
DEFAULT_GAME_WIDTH = 60
MAX_CONNECTIONS_PER_HOST = 5
TICKS_PER_SECOND = 5
#----------------------------------------

server.listen(process.argv[2] || DEFAULT_SERVER_PORT)

app.configure( ->
  app.set("view options", { layout: false, pretty: true })
  app.use(express.favicon())
  app.use(assets())
  app.use(express.static(__dirname + '/public'))
)


# Server config:
app.get('/', (req, res) ->
  res.render(__dirname + '/views/index.jade')
)

game = new Game()
game_width = process.argv[3] || DEFAULT_GAME_WIDTH
game_height = Math.floor(game_width * 3 / 4)
game.spawnDungeon(game_width, game_height)
sys.puts game.mapToString()

visualizers = []
connected_hosts = {}

io = require('socket.io').listen(server)

tickGame = ->
  # console.log "Game tick"
  game.tick()
  # Send updated world state to each player
  for client in io.sockets.clients()
    if isVisualizer(client)
      client.emit 'world state', game.visualizerTickPayload()
    else if game.findPlayer(client.id)
      client.emit 'tick', game.tickPayloadFor(client.id)
    else
      client.disconnect()

setInterval tickGame, Math.floor(1000 / TICKS_PER_SECOND)

isVisualizer = (socket) ->
  _(visualizers).contains socket.id

io.sockets.on('connection', (socket) ->
  ip_address = socket.handshake.address.address
  console.log "Spawning player for #{socket.id} #{ip_address}"

  matching_addresses = _(io.sockets.clients()).filter (a) => (a.handshake.address.address == ip_address)
  if matching_addresses.length > MAX_CONNECTIONS_PER_HOST
    console.log "Kicking #{ip_address} for too many connections"
    socket.disconnect()
    return

  game.spawnPlayer(socket.id)

  socket.on("set name", (player_name) ->
    game.setName(socket.id, player_name) unless isVisualizer(socket)
  )

  socket.on("visualizer", (data) ->
    visualizers.push socket.id
    game.disconnectPlayer(socket.id)
    socket.emit 'map', game.map
  )

  socket.on("move", (data) ->
    game.registerOrder(new Order(socket.id, "move", data)) unless isVisualizer(socket)
  )

  socket.on("attack", (data) ->
    game.registerOrder(new Order(socket.id, "attack", data)) unless isVisualizer(socket)
  )

  socket.on("drop", (data) ->
    game.registerOrder(new Order(socket.id, "drop", data)) unless isVisualizer(socket)
  )

  socket.on("pick up", (data) ->
    game.registerOrder(new Order(socket.id, "pick up", data)) unless isVisualizer(socket)
  )

  socket.on("disconnect",  ->
    visualizers = _(visualizers).reject (id) -> id == socket.id
    game.disconnectPlayer(socket.id)
  )
)
