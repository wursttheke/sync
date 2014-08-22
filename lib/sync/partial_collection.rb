module Sync
  class PartialCollection
    attr_accessor :direction, :creator, :order_info, :refetch
    
    def initialize(options)
      @direction = options[:direction]
      @order_info = options[:order]
      @refetch = options[:refetch] || false

      if options[:new]
        klass = options[:refetch] ? RefetchPartialCreator : PartialCreator
        @creator = klass.new(options[:partial_name], options[:new], options[:scope], self)
      end
    end

    def data_attributes
      hash = { 
        sync_collection: true, 
        sync_direction: direction,
        refetch: refetch,
        sync_order: order_info.directions_string
      }

      if creator
        hash.merge({ 
          name: creator.name, 
          resource_name: creator.resource.name, 
          channel: creator.channel,
        })
      else
        hash
      end
    end
    
  end
end