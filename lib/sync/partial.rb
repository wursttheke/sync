module Sync
  class Partial
    attr_accessor :name, :resource, :context, :order_info

    def self.all(model, context, scope = nil)
      resource = Resource.new(model, scope)

      Dir["#{Sync.views_root}/#{resource.plural_name}/_*.*"].map do |partial|
        partial_name = File.basename(partial)
        Partial.new(partial_name[1...partial_name.index('.')], resource.model, scope, context)
      end
    end

    def initialize(name, resource, scope, context)
      self.name = name
      self.resource = Resource.new(resource, scope)
      self.order_info = OrderInfo.from_scope(scope)
      self.context = context
    end

    # Render the Partial and return the resulting HTML String
    # Check if user wrapped template content inside a 'sync_tag'. If not,
    # wrap the evaluated template into the standard sync_tag which is
    # a simple DIV.
    #
    def render
      context.current_partial = self
      html = context.render(partial: path, locals: locals, formats: [:html])
      result = context.sync_tag_called? ? html : context.sync_tag(:div, html)
      context.current_partial = nil
      context.reset_sync_tag_called!
      result
    end

    def sync(action)
      message(action).publish
    end

    def message(action)
      Sync.client.build_message channel_for_action(action),
        html: (render unless action.to_s == "destroy")
    end

    def authorized?(auth_token)
      self.auth_token == auth_token
    end

    def auth_token
      @auth_token ||= Channel.new("#{polymorphic_path}-#{name}-#{order_keys_string}").to_s
    end
    
    # For the refetch feature we need an auth_token that wasn't created
    # with scopes, because the scope information is not available on the
    # refetch-request. So we create a refetch_auth_token which is based 
    # only on model_name and id plus the name of this partial
    #
    def refetch_auth_token
      @refetch_auth_token ||= Channel.new("#{model_path}-#{name}-#{order_keys_string}").to_s
    end

    def channel_prefix
      @channel_prefix ||= auth_token
    end

    def channel_for_action(action)
      "#{channel_prefix}-#{action}"
    end

    def creator_for_scope(scope)
      PartialCreator.new(name, resource.model, scope, context)
    end
    
    def order_values
      order_info.values(resource.model)
    end

    def order_keys_string
      order_info.direction_keys.join("-")
    end
    
    def data_attributes
      hash = {
        sync_item: true,
        name: name,
        resource_name: resource.name,
        resource_id: resource.model.id,
        auth_token: refetch_auth_token,
        channel_prefix: channel_prefix
      }
      
      order_values.each_with_index do |(key,value),index|
        hash["sync_order_#{index}".to_sym] = value
      end
      
      hash
    end

    private

    def path
      "sync/#{resource.plural_name}/#{name}"
    end

    def locals
      locals_hash = {}
      locals_hash[resource.base_name.to_sym] = resource.model
      locals_hash
    end
    
    def model_path
      resource.model_path
    end

    def polymorphic_path
      resource.polymorphic_path
    end
  end
end
