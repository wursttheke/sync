class Sync.View
  
  removed: false

  constructor: (@$el, @name, @partial) ->

  beforeUpdate: (html, data) -> @update(html)

  afterUpdate: -> #noop
  
  beforeInsert: ($el, data) -> @insert($el)

  afterInsert: -> #noop

  beforeRemove: -> @remove()

  afterRemove: -> #noop

  isRemoved: -> @removed

  remove: ->
    @$el.remove()
    @$el = $()
    @removed = true
    @afterRemove()


  bind: -> #noop

  show: -> @$el.show()

  update: (html) -> 
    $new = $($.trim(html))
    @$el.replaceWith($new)
    @partial.collection.reorder()
    @$el = $new
    @afterUpdate()
    @bind()


  insert: ($el) ->
    @partial.collection.insertElement($el)
    @$el = $el
    @afterInsert()
    @bind()


