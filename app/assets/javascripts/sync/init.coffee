# Initialize Sync and adapter (Faye, ...)
Sync.init()

# Initialize syncing of all collections on the page
Sync.onReady ->
  for element, index in $("[data-sync-collection-start]")
    do ->
      collection = new Sync.PartialCollection($(element))
      collection.init()