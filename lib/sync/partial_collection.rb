module Sync
  class PartialCollection
    attr_accessor :direction, :creator
    
    def initialize(options)
      @direction = options[:direction]

      if options[:new]
        klass = options[:refetch] ? RefetchPartialCreator : PartialCreator
        @creator = klass.new(options[:partial_name], options[:new], options[:scope], self)
      end
    end

    def data_attributes_start
      hash = { sync_collection_start: true, direction: direction }

      if creator
        hash.merge({ name: creator.name, resource_name: creator.resource.name, channel: creator.channel, refetch: creator.refetch })
      else
        hash
      end
    end
    
    def data_attributes_end
      { sync_collection_end: true }
    end
  end
end