module Sync
  class Renderer

    attr_accessor :context

    def initialize
      self.context = ApplicationController.new.view_context
      self.context.instance_eval do
        def url_options
          ActionMailer::Base.default_url_options
        end
      end
    end

    delegate :current_partial, to: :context
    delegate :current_partial=, to: :context
    delegate :render, to: :context
    delegate :sync_tag, to: :context
    delegate :sync_tag_called?, to: :context
  end
end