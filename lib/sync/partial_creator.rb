module Sync
  class PartialCreator
    attr_accessor :name, :resource, :context, :partial

    def initialize(name, resource, scopes, context)
      self.name = name
      self.resource = Resource.new(resource, scopes)
      self.context = context
      self.partial = Partial.new(name, self.resource.model, scopes, context)
    end

    def auth_token
      @auth_token ||= Channel.new("#{polymorphic_path}-_#{name}").to_s
    end

    def channel
      @channel ||= auth_token
    end

    def selector
      "#{channel}"
    end

    def sync_new
      message.publish
    end

    def message
      Sync.client.build_message(channel,
        html: partial.render_to_string,
        order: partial.order_values_string,
        resourceId: resource.id,
        authToken: partial.auth_token,
        channelPrefix: partial.channel_prefix,
      )
    end

    private

    def polymorphic_path
      resource.polymorphic_new_path
    end
  end
end
