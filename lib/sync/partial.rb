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

    def render_to_string
      context.render_to_string(partial: path, locals: locals, formats: [:html])
    end

    def render
      context.render(partial: path, locals: locals, formats: [:html])
    end

    def sync(action)
      message(action).publish
    end

    def message(action)
      Sync.client.build_message channel_for_action(action),
        html: (render_to_string unless action.to_s == "destroy"),
        order: (order_values_string unless action.to_s == "destroy")
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

    def selector_start
      "#{channel_prefix}-start"
    end

    def selector_end
      "#{channel_prefix}-end"
    end

    def creator_for_scope(scope)
      PartialCreator.new(name, resource.model, scope, context)
    end

    def order_values_string
      order_info.values_string(resource.model)
    end
    
    def order_values
      order_info.values(resource.model)
    end

    def order_keys_string
      order_info.direction_keys.join("-")
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
