module Sync
  class OrderInfo
    attr_accessor :order_hash
    
    def initialize
      @order_hash = ActiveSupport::OrderedHash.new
    end

    # Extract the order info from a passed Sync::Scope and prepare it for
    # being sent down to the client. It will be used to sort synced collection 
    # items locally in the browser via JS
    #
    def self.from_scope(scopes)
      info = self.new
      scopes = [scopes] unless scopes.is_a?(Array)
      scopes.each do |scope|
        if scope.is_a?(Sync::Scope)
          scope.orders.map do |order|
            if order.is_a?(Arel::Node)
              info.add_direction order.expr.name, (order.is_a?(Arel::Nodes::Descending) ? :desc : :asc)
            end
          end
        end
      end
      info
    end

    # Add an order direction
    #
    def add_direction(key, direction = :asc)
      @order_hash[key.to_sym] = direction
    end
    
    # Add multiple order direction keys via an Array
    # (e.g [:name, :age]). Default direction (:asc) will be used.
    #
    def add_directions(keys)
      keys = [keys].flatten.compact
      keys.each do |key|
        add_direction(key)
      end
    end

    def direction_keys
      @order_hash.keys
    end

    # Return the directional information of the order statement in a json
    # string for being used as HTML-data-attribute
    # e.g '["desc","asc"]'
    #
    def directions_string
      @order_hash.values.to_json
    end

    # Returns an Array of model attribute values needed for sorting
    # a collection via JS in the browser. It converts several types to
    # a simpler format for easy comparison.
    #
    # e.g. ["1216523", "tom", "1"]
    #
    def values(model)
      return_hash = ActiveSupport::OrderedHash.new
      @order_hash.each do |name, direction| 
        return_hash[name] = case model.class.columns_hash[name.to_s].type
        when :boolean
          # Convert Boolean Values to 1/0 so they can be compared in JS.
          #
          model.send(name) ? 1 : 0
        when :datetime, :date, :time
          # Convert date type columns to integer timestamps for simple
          # comparison.
          #
          model.send(name).to_i
        when :integer
          model.send(name)
        else
          # Downcase and remove all chars exept numbers and letters, so it's 
          # html safe (and can be used as HTML-data-attribute).
          #
          # Reduce the string length to 10 chars, so very long attributes 
          # like texts are not completely sent to the client. This should
          # be enough for the JS comparison of items. We could make this 
          # configurable in the future, if needed.
          #
          model.send(name).to_s.gsub(/[^0-9A-Za-z.\-]/, '')[0..9]
        end
      end

      return_hash
    end
    
    # Checks if the order information is empty.
    #
    def empty?
      @order_hash.empty?
    end
    
  end
end
