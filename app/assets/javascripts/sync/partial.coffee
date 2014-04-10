class Sync.Partial

  attributes:
    name: null
    resourceName: null
    resourceId: null
    authToken: null
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
  #   channelUpdate - The String channel to listen for update publishes on
  #   channelDestroy - The String channel to listen for destroy publishes on
  #   selectorStart - The String selector to mark beginning in the DOM
  #   selectorEnd - The String selector to mark ending in the DOM
  #   refetch - The Boolean to refetch markup from server or receive markup
  #             from pubsub update. Default false.
  #
  constructor: (attributes = {}) ->
    @[key] = attributes[key] ? defaultValue for key, defaultValue of @attributes
    @$start = $("[data-sync-id='#{@selectorStart}']")
    @$end   = $("[data-sync-id='#{@selectorEnd}']")
    @$el    = @$start.nextUntil(@$end)
    @view   = new (Sync.viewClassFromPartialName(@name, @resourceName))(@$el, @name)
    @adapter = Sync.adapter


  subscribe: ->
    @subscriptionUpdate = @adapter.subscribe @channelUpdate, (data) =>
      if @refetch
        @refetchFromServer (html) => @update(html)
      else
        @update(data.html)

    @subscriptionDestroy = @adapter.subscribe @channelDestroy, => @remove()

  
  update: (html) -> @view.beforeUpdate(html, {})

  remove: -> 
    @view.beforeRemove()
    @destroy() if @view.isRemoved()


  insert: (html) ->
    if @refetch
      @refetchFromServer (html) => @view.beforeInsert($($.trim(html)), {})
    else
      @view.beforeInsert($($.trim(html)), {})


  destroy: ->
    @subscriptionUpdate.cancel()
    @subscriptionDestroy.cancel()
    @$start.remove()
    @$end.remove()
    @$el?.remove()
    delete @$start
    delete @$end
    delete @$el


  refetchFromServer: (callback) ->
    $.ajax
      type: "GET"
      url: "/sync/refetch.json"
      data:
        auth_token: @authToken
        partial_name: @name
        resource_name: @resourceName
        resource_id: @resourceId
      success: (data) -> callback(data.html)

