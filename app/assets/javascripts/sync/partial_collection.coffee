class Sync.PartialCollection

  # attributes
  #
  #   name - The String name of the partial without leading underscore
  #   resourceName - The String undercored class name of the resource
  #   channel - The String channel to listen for new publishes on
  #   selector - The String selector to find the element in the DOM
  #   direction - The String direction to insert. One of "append" or "prepend"
  #   orderDirections - Array with order infos.
  #   refetch - The Boolean to refetch markup from server or receive markup
  #             from pubsub update. Default false.
  #
  constructor: (element) ->
    @$start            = element
    @$end              = element.nextAll("[data-sync-collection-end]").eq(0)

    @name              = element.data('name')
    @resourceName      = element.data('resource-name')
    @channel           = element.data('channel')
    @selector          = element.data('channel')
    @direction         = element.data('direction')
    @orderDirections   = element.data('order-directions') || {}
    @refetch           = element.data('refetch')

    @adapter = Sync.adapter

  init: ->
    # Subscribe to new items, if channel exists
    @subscribe() if @channel
      
    self = @
      
    # Initialize items of this collection
    for item, index in @items()
      do ->
        partial = new Sync.Partial($(item), self)
        partial.subscribe()


  subscribe: ->
    @adapter.subscribe @channel, (data) => @insert data
  
  # Return all item start tags inside collection
  #
  items: ->
    @$start.nextUntil("[data-sync-collection-end]", "[data-sync-item-start]")
  
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
  
  moveSorted: (itemStart, itemContent, itemEnd) ->
    # Build Array of items to be sorted
    itemsCurrent = @itemsForSorting()
    itemsTarget = itemsCurrent.slice(0)

    currentPosition = (index for item, index in itemsCurrent when item["sync_id"] is itemStart.data("sync-id"))[0]

    # SQL style multi-key asc/desc sorting of object arrays,
    # extract new position
    mksort.sort itemsTarget, @orderDirections
    newPosition = (index for item, index in itemsTarget when item["sync_id"] is itemStart.data("sync-id"))[0]

    # Only move item if position has changed after sorting
    # Determine the script-tag (successor) before which the item has to be
    # moved. 
    if newPosition isnt currentPosition
      if newPosition is itemsCurrent.length - 1
        successor = @$end
      else if newPosition > currentPosition
        successor = $("[data-sync-id='#{itemsCurrent[newPosition + 1]["sync_id"]}']")
      else
        successor = $("[data-sync-id='#{itemsCurrent[newPosition]["sync_id"]}']")
      
      successor.before(itemStart, itemContent, itemEnd)
  
  # Inserts the html placeholder snippet at the correct position in the 
  # collection with regard to @sortDirections
  #
  insertSorted: (html) ->
    itemStart = $(html).first("[data-sync-item-start]")
      
    # Extract order object from new HTML snippet and add sync_id to it
    order = itemStart.data("sync-order")
    order["sync_id"] = itemStart.data("sync-id")
    order["new"] = true
    
    # Build Array of items to be sorted, add new item object (order) to it
    itemsCurrent = @itemsForSorting()
    itemsTarget = itemsCurrent.slice(0)
    itemsTarget.push order
    
    # SQL style multi-key asc/desc sorting of object arrays
    mksort.sort itemsTarget, @orderDirections

    # Get the position of the item to be inserted
    position = (index for item, index in itemsTarget when item["new"]?)[0]

    # Insert item at position or at the end of collection
    if position is itemsCurrent.length
      @$end.before(html)
    else
      $("[data-sync-id='#{itemsCurrent[position]["sync_id"]}']").before(html)


  insertPlaceholder: (html) ->
    switch @direction
      when "append"  then @$end.before(html)
      when "prepend" then @$start.after(html)
      when "sort" then @insertSorted(html)
            
  insert: (data) ->
    @insertPlaceholder """
      <script type='text/javascript' data-sync-item-start 
        data-sync-id='#{data.channelPrefix}-start'
        data-sync-order='#{data.order}'
        data-name='#{@name}'
        data-resource-name='#{@resourceName}'
        data-resource-id='#{data.resourceId}'
        data-refetch='#{@refetch}'
        data-auth-token='#{data.authToken}'
        data-channel-prefix='#{data.channelPrefix}'>
      </script>
      <script type='text/javascript' data-sync-el-placeholder></script>
      <script type='text/javascript' data-sync-item-end data-sync-id='#{data.channelPrefix}-end'></script>
    """
    
    partial = new Sync.Partial($("[data-sync-id='#{data.channelPrefix}-start']") , @)
    partial.subscribe()
    partial.insert(data.html)

