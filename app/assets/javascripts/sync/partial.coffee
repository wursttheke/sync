class Sync.Partial

  attributes:
    collection: null
    name: null
    resourceName: null
    resourceId: null
    authToken: null
    channelPrefix: null
    channelUpdate: null
    channelDestroy: null
    selectorStart: null
    selectorEnd: null
    refetch: false

    subscriptionUpdate: null
    subscriptionDestroy: null

  # attributes
  #
  #   name - The String name of the partial without leading underscore
  #   resourceName - The String undercored class name of the resource
  #   resourceId
  #   authToken - The String auth token for the partial
  #   channelPrefix - The String channel prefix
  #   channelUpdate - The String channel to listen for update publishes on
  #   channelDestroy - The String channel to listen for destroy publishes on
  #   selectorStart - The String selector to mark beginning in the DOM
  #   selectorEnd - The String selector to mark ending in the DOM
  #   refetch - The Boolean to refetch markup from server or receive markup
  #             from pubsub update. Default false.
  #
  constructor: ($start, collection) ->
    @collection    = collection
    
    @name          = $start.data('name')
    @resourceName  = $start.data('resource-name')
    @resourceId    = $start.data('resource-id')
    @refetch       = $start.data('refetch')
    @authToken     = $start.data('auth-token')
    @channelPrefix = $start.data('channel-prefix')

    @channelUpdate    = "#{@channelPrefix}-update"
    @channelDestroy   = "#{@channelPrefix}-destroy"
    @selectorStart    = "#{@channelPrefix}-start"
    @selectorEnd      = "#{@channelPrefix}-end"

    @$start = -> $("[data-sync-id='#{@selectorStart}']")
    @$end   = -> $("[data-sync-id='#{@selectorEnd}']")
    @$el    = -> @$start().nextUntil(@$end())
    @view   = new (Sync.viewClassFromPartialName(@name, @resourceName))(@$el(), @name)
    @adapter = Sync.adapter


  subscribe: ->
    @subscriptionUpdate = @adapter.subscribe @channelUpdate, (data) =>
      if @refetch
        @refetchFromServer (data) => @update(data)
      else
        @update(data)

    @subscriptionDestroy = @adapter.subscribe @channelDestroy, => @remove()

  
  update: (data) -> 
    @view.beforeUpdate(data.html, {})
    @$start().data "sync-order", data.order
    # @collection.moveSorted(@$start(), @$el(), @$end()) unless data.order.length is 0

  remove: -> 
    @view.beforeRemove()
    @destroy() if @view.isRemoved()


  insert: (html) ->
    if @refetch
      @refetchFromServer (data) => @view.beforeInsert($($.trim(data.html)), {})
    else
      @view.beforeInsert($($.trim(html)), {})


  destroy: ->
    @subscriptionUpdate.cancel()
    @subscriptionDestroy.cancel()
    @$start().remove()
    @$end().remove()
    @$el()?.remove()
    delete @$start()
    delete @$end()
    delete @$el()


  refetchFromServer: (callback) ->
    $.ajax
      type: "GET"
      url: "/sync/refetch.json"
      data:
        auth_token: @authToken
        order: Object.keys(@collection.orderDirections)
        partial_name: @name
        resource_name: @resourceName
        resource_id: @resourceId
      success: (data) -> callback(data)

