class Sync.PartialCreator

  attributes:
    name: null
    resourceName: null
    authToken: null
    channel: null
    selector: null
    direction: 'append'
    refetch: false

  # attributes
  #
  #   name - The String name of the partial without leading underscore
  #   resourceName - The String undercored class name of the resource
  #   channel - The String channel to listen for new publishes on
  #   selector - The String selector to find the element in the DOM
  #   direction - The String direction to insert. One of "append" or "prepend"
  #   refetch - The Boolean to refetch markup from server or receive markup
  #             from pubsub update. Default false.
  #
  constructor: (attributes = {}) ->
    @[key] = attributes[key] ? defaultValue for key, defaultValue of @attributes
    @$el = $("[data-sync-id='#{@selector}']")
    @sortDirections = @$el.data("sync-directions")
    @adapter = Sync.adapter

  subscribe: ->
    @adapter.subscribe @channel, (data) =>
      @insert data.html,
              data.order,
              data.resourceId,
              data.authToken,
              data.channelUpdate,
              data.channelDestroy,
              data.selectorStart,
              data.selectorEnd
  
  # Return all item start tags inside collection
  #
  items: ->
    @$el.nextUntil("[data-sync-collection-end]", "[data-sync-item-start]")
  
  # Return an Array with all item objects containing the order information 
  # needed for sorting. Add the sync_id to it so the DOM node can be found
  # later on.
  #
  # e.g. [
  #        {"title":"Bike","age":25,"sync_id":"/995ca57-start"},
  #        {"title":"Car","age":21},"sync_id":"/0be80c0-start"},
  #      ]
  #
  itemsForSorting: ->
    for item in @items()
      object = $(item).data("sync-order")
      object["sync_id"] = $(item).data("sync-id")
      object
  
  # Inserts the html placeholder snippet at the correct position in the 
  # collection with regard to @sortDirections
  #
  insertSorted: (html) ->
    itemStart = $(html).filter ->
      $(this).is('script')

    order = itemStart.data("sync-order")
    order["sync_id"] = itemStart.data("sync-id")
    order["new"] = true
    
    # Build Array of items to be sorted, add new item object (order) to it
    itemsCurrent = @itemsForSorting()
    itemsTarget = itemsCurrent.slice(0)
    itemsTarget.push order
    
    # SQL style multi-key asc/desc sorting of object arrays
    mksort.sort itemsTarget, @sortDirections

    # Get the position of the item to be inserted
    position = (index for item, index in itemsTarget when item["new"]?)[0]

    # Insert item at position or at the end of collection
    if position is itemsCurrent.length
      @$el.nextAll("[data-sync-collection-end]").eq(0).before(html)
    else
      $("[data-sync-id='#{itemsCurrent[position]["sync_id"]}']").before(html)


  insertPlaceholder: (html) ->
    switch @direction
      when "append"  then @$el.nextAll("[data-sync-collection-end]").eq(0).before(html)
      when "prepend" then @$el.after(html)
      when "sort" then @insertSorted(html)
            
  insert: (html, order, resourceId, authToken, channelUpdate, channelDestroy, selectorStart, selectorEnd) ->
    @insertPlaceholder """
      <script type='text/javascript' data-sync-item-start data-sync-id='#{selectorStart}'
        data-sync-order='#{order}'></script>
      <script type='text/javascript' data-sync-el-placeholder></script>
      <script type='text/javascript' data-sync-item-end data-sync-id='#{selectorEnd}'></script>
    """
    partial = new Sync.Partial(
      name: @name
      resourceName: @resourceName
      resourceId: resourceId
      authToken: authToken
      channelUpdate: channelUpdate
      channelDestroy: channelDestroy
      selectorStart: selectorStart
      selectorEnd: selectorEnd
      refetch: @refetch
    )
    partial.subscribe()
    partial.insert(html)

