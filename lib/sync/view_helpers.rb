module Sync

  module ViewHelpers

    # Surround partial render in a sync_tag (unless already done by the user 
    # in the partial), watching for sync_update and sync_destroy channels 
    # from pubsub server
    #
    # Supports automatic ordering of collections on change.
    # Use a sync_scope with an order clause to enable this feature.
    #
    # Rails 4: Use the new symbol style order statement:
    # sync_scope :ordered, -> { order(created_at: :desc) }
    #
    # Rails 3: You have to use the arel table to define the order 
    # clause like this: order(Todo.arel_table[:created_at].desc)
    #
    # Sync cannot recognize the string style order statement and will 
    # ignore it: order("created_at DESC")
    #
    # options - The Hash of options
    #   partial - The String partial filename without leading underscore
    #   resource - The ActiveModel resource
    #   collection - The Array of ActiveModel resources to use in place of 
    #                single resource
    #   new - custom ActiveRecord instance (e.g. Todo.new)
    #         defaults to collection.new if a collection
    #         (ActiveRecord::Relation or Sync::Scope) is passed, otherwise 
    #         defaults to false. Set to false, if you do not wish to sync new 
    #         records.
    #   direction - one of :append, :prepend or :sort
    #               defaults to :sort if a Sync::Scope collection is passed and 
    #               contains an order statement, otherwise defaults to :append
    #
    # Examples:
    #   
    #   class Todo < ActiveRecord::Base
    #     sync :all
    #     sync_scope :top, -> { 
    #       where(completed: false).order(created_at: :desc).limit(10) 
    #     }
    #   end
    #
    #   Sync all changes to a single ActiveRecord resource (update, delete):
    #   <%= sync partial: 'todo', resource: Todo.find(123) %>
    #
    #   Sync all changes (new, update, destroy) to a Sync::Scope collection
    #   <%= sync partial: 'todo', collection: Todo.top %>
    #
    def sync(options = {})
      options[:collection] ||= [options.fetch(:resource)]
      options[:scope]      ||= options[:collection].is_a?(Sync::Scope) ? options[:collection] : nil
      options[:partial_name] = options.fetch(:partial, options[:scope])
      options[:order]        = Sync::OrderInfo.from_scope(options[:scope])
      options[:direction]  ||= options[:order].empty? ? :append : :sort
      options[:limit]        = limit_info(options[:collection])
      options[:container]  ||= {}
      options[:container][:tag] ||= :div
      
      options[:new] = if options[:new]
        options[:new]
      elsif options[:collection].is_a?(ActiveRecord::Relation) || options[:collection].is_a?(Sync::Scope)
        options[:collection].new
      else
        false
      end

      collection_tag(options)
    end

    def sync_tag_called?
      @sync_tag_called.present? && @sync_tag_called == true
    end

    def sync_tag(name, content_or_options_with_block = nil, options = nil, escape = true, &block)
      sync_tag_called!

      if block_given?
        options = content_or_options_with_block if content_or_options_with_block.is_a?(Hash)
        options[:data] ||= {}
        options[:data].merge!(current_partial.data_attributes)
        content_tag_string(name, capture(&block), options, escape)
      else
        options ||= {}
        options[:data] ||= {}
        options[:data].merge!(current_partial.data_attributes)
        content_tag_string(name, content_or_options_with_block, options, escape)
      end
    end

    def current_partial
      @current_partial
    end
    
    def current_partial=(partial)
      @current_partial = partial
    end

    def reset_sync_tag_called!
      @sync_tag_called = false
    end

    private

    def sync_tag_called!
      @sync_tag_called = true
    end
    
    def collection_tag(options)
      partial_collection = PartialCollection.new(options)
      
      tag_options = options[:container].except(:tag)
      tag_options[:data] ||= {}
      tag_options[:data].merge!(partial_collection.data_attributes)

      content_tag options[:container][:tag], tag_options do
        options[:collection].each do |resource|
          klass = options[:refetch] ? RefetchPartial : Partial
          partial = klass.new(options[:partial_name], resource, options[:scope], self)
          concat partial.render
        end
      end
    end
    
    # Extract the limit info, if an ActiveRecord::Relation or Sync::Scope 
    # is passed.
    #
    def limit_info(collection)
      collection.arel.limit if collection.respond_to?(:arel)
    end
  end
end
