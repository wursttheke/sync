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

    @name              = element.data('name')
    @resourceName      = element.data('resource-name')
    @channel           = element.data('channel')
    @selector          = element.data('channel')
    @direction         = element.data('direction')
    @orderDirections   = element.data('order-directions') || {}
    @refetch           = element.data('refetch')

    @$end              = element.nextAll("[data-sync-collection-end]").eq(0)

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

  insertPlaceholder: (html) ->
    switch @direction
      when "append"  then @$end.before(html)
      when "prepend" then @$start.after(html)
      when "sort"  then @$end.before(html)
            
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
    

