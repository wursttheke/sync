class Sync.PartialCollection

  # attributes
  #
  #   name - The String name of the partial without leading underscore
  #   resourceName - The String undercored class name of the resource
  #   channel - The String channel to listen for new publishes on
  #   direction - The String direction to insert. One of "append" or "prepend"
  #   orderDirections - Array with order infos.
  #   refetch - The Boolean to refetch markup from server or receive markup
  #             from pubsub update. Default false.
  #
  constructor: ($element) ->
    @$element       = $element

    @name           = $element.data('name')
    @resourceName   = $element.data('resource-name')
    @channel        = $element.data('channel')
    @direction      = $element.data('sync-direction')
    @order          = $element.data('sync-order') || []
    @refetch        = $element.data('refetch')

    @adapter = Sync.adapter

  init: ->
    # Subscribe to new items, if channel exists
    @subscribe() if @channel
      
    # Initialize items of this collection
    for item, index in @items()
      partial = new Sync.Partial($(item), @)
      partial.subscribe()


  subscribe: ->
    @adapter.subscribe @channel, (data) => @insertPartial data
  
  items: ->
    @$element.children()

  insertPartial: (data) ->
    partial = new Sync.Partial($(data.html), @)
    partial.subscribe()
    partial.insert()
    
  insertElement: ($el) ->
    switch @direction
      when "append"  then @$element.append($el)
      when "prepend" then @$element.prepend($el)
      when "sort"
        @$element.append($el)
        @reorder()
    
  reorder: ->
    if @direction == "sort"
      for i in [@order.length - 1..0]
        @items().tsort('', {data: "sync-order-#{i}", order:"#{@order[i]}"})

