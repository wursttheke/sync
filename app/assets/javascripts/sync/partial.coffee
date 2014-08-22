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
    
    view: null

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
  #
  constructor: ($element, collection) ->
    @$element      = $element
    @collection    = collection
    
    @name          = $element.data('name')
    @resourceName  = $element.data('resource-name')
    @resourceId    = $element.data('resource-id')
    @authToken     = $element.data('auth-token')
    @channelPrefix = $element.data('channel-prefix')

    @channelUpdate    = "#{@channelPrefix}-update"
    @channelDestroy   = "#{@channelPrefix}-destroy"

    @view   = new (Sync.viewClassFromPartialName(@name, @resourceName))(@$element, @name, @)
    @adapter = Sync.adapter


  subscribe: ->
    @subscriptionUpdate = @adapter.subscribe @channelUpdate, (data) =>
      if @collection.refetch
        @refetchFromServer (data) => @update(data)
      else
        @update(data)

    @subscriptionDestroy = @adapter.subscribe @channelDestroy, => @remove()

  update: (data) -> 
    @view.beforeUpdate(data.html, {})

  remove: -> 
    @view.beforeRemove()
    @destroy() if @view.isRemoved()


  insert: (html) ->
    if @collection.refetch
      @refetchFromServer (data) => @view.beforeInsert($($.trim(data.html)), {})
    else
      @view.beforeInsert(@$element, {})


  destroy: ->
    @subscriptionUpdate.cancel()
    @subscriptionDestroy.cancel()
    @$element?.remove()
    delete @$element


  refetchFromServer: (callback) ->
    $.ajax
      type: "GET"
      url: "/sync/refetch.json"
      data:
        auth_token: @authToken
        order: Object.keys(@collection.order)
        partial_name: @name
        resource_name: @resourceName
        resource_id: @resourceId
      success: (data) -> callback(data)

