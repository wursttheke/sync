class Sync.Pusher

  subscriptions: []

  connect: ->
    @client = new window.Pusher(Sync.PUSHER_API_KEY)


  isConnected: -> @client?.connection.state is "connected"

  subscribe: (channel, callback) -> 
    subscription = new Sync.Pusher.Subscription(@client, channel, callback)
    @subscriptions.push(subscription)
    subscription

  unsubscribeAll: ->
    subscription.cancel() for subscription in @subscriptions
    @subscriptions = []


    
class Sync.Pusher.Subscription
  constructor: (@client, channel, callback) ->
    @pusherSub = channel
    
    channel = @client.subscribe(channel)
    channel.bind 'sync', callback
    
  cancel: ->
    @client.unsubscribe(@pusherSub) if @client.channel(@pusherSub)?

