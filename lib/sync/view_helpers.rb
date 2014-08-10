module Sync

  module ViewHelpers

    # Surround partial render in script tags, watching for 
    # sync_update and sync_destroy channels from pubsub server
    #
    # Supports automatic ordering of collections on change
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

      options[:new] = if options[:new]
        options[:new]
      elsif options[:collection].is_a?(ActiveRecord::Relation) || options[:collection].is_a?(Sync::Scope)
        options[:collection].new
      else
        false
      end

      collection_tags(options)
    end

    private
    
    def collection_tags(options)
      partial_collection = PartialCollection.new(options)

      capture do
        concat content_tag :script, nil, data: partial_collection.data_attributes_start

        options[:collection].each do |resource|
          klass = options[:refetch] ? RefetchPartial : Partial
          partial = klass.new(options[:partial_name], resource, options[:scope], self)
          concat partial_tags(partial)
        end

        concat content_tag :script, nil, data: partial_collection.data_attributes_end
      end
    end
    
    def partial_tags(partial)
      capture do
        concat content_tag :script, nil, data: partial.data_attributes_start
        concat partial.render
        concat content_tag :script, nil, data: partial.data_attributes_end
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
