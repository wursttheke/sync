class Sync.Faye

  subscriptions: []

  connect: ->
    @client = new window.Faye.Client(Sync.FAYE_HOST)


  isConnected: -> @client?.getState() is "CONNECTED"

  subscribe: (channel, callback) -> 
    subscription = new Sync.Faye.Subscription(@client, channel, callback)
    @subscriptions.push(subscription)
    subscription

  unsubscribeAll: ->
    subscription.cancel() for subscription in @subscriptions
    @subscriptions = []


class Sync.Faye.Subscription
  constructor: (@client, channel, callback) ->
    @fayeSub = @client.subscribe channel, callback
    
  cancel: ->
    @fayeSub.cancel()
    