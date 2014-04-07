module Sync
  class OrderInfo
    attr_accessor :order_hash
    
    # Extract the order info from a passed Sync::Scope and prepare it for
    # being sent down to the client. It will be used to sort synced collection 
    # items locally in the browser via JS
    #
    def initialize(scopes)
      @order_hash = {}
      scopes = [scopes] unless scopes.is_a?(Array)
      scopes.each do |scope|
        if scope.is_a?(Sync::Scope)
          scope.orders.map do |order|
            if order.is_a?(Arel::Node)
              @order_hash[order.expr.name.to_sym] = order.is_a?(Arel::Nodes::Descending) ? :desc : :asc
            end
          end
        end
      end
    end
    
    # Returns an Array with directions of the order statement
    # e.g. ["asc", "desc"]
    #
    def directions
      @order_hash.values
    end

    # Return the direction information of the order statement in a minimalized
    # string for being used as HTML-data-attribute interpreted by JS
    # e.g "a,d"
    #
    def directions_string
      directions.map do |direction|
        direction == :asc ? "a" : "d"
      end.join(",")
    end

    # Returns an Array of model attribute values needed for sorting
    # a collection via JS in the browser. It converts several types to
    # a simpler format for easy comparison.
    #
    # e.g. ["1216523", "tom", "1"]
    #
    def values(model)
      @order_hash.map do |name, direction|
        case model.class.columns_hash[name.to_s].type
        when :boolean
          # Convert Boolean Values to 1/0 so they can be compared in JS.
          #
          model.send(name) ? "1" : "0"
        when :datetime, :date, :time
          # Convert date type columns to integer timestamps for simple
          # comparison.
          #
          model.send(name).to_i.to_s
        else
          # Downcase and remove all chars exept numbers and letters, so it's 
          # html safe (and can be used as HTML-data-attribute).
          #
          # Reduce the string length to 10 chars, so very long attributes 
          # like texts are not completely sent to the client. This should
          # be enough for the JS comparison of items. We could make this 
          # configurable in the future, if needed.
          #
          model.send(name).to_s.downcase.gsub(/[^0-9A-Za-z.\-]/, '')[0..9]
        end
      end
    end
    
    # Returns an HTML safe string with comma seperated model attribute values 
    # needed for sorting a collection via JS in the browser. 
    # e.g. "1216523,tom,1"
    #
    def values_string(model)
      values(model).join(",")
    end
    
    # Checks if the order information is empty.
    #
    def empty?
      @order_hash.empty?
    end
    
  end
end
