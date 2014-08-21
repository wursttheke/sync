module Sync
  class RefetchPartialCreator < PartialCreator

    def initialize(name, resource, scopes, context)
      super
      self.refetch = true
      self.partial = RefetchPartial.new(name, self.resource.model, scopes, context)
    end

    def message
      Sync.client.build_message(channel,
        refetch: true,
        resourceId: resource.id,
        authToken: partial.refetch_auth_token,
        channelPrefix: partial.channel_prefix
      )
    end
  end
end
