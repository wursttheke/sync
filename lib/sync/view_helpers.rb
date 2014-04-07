module Sync

  module ViewHelpers

    # Surround partial render in script tags, watching for 
    # sync_update and sync_destroy channels from pubsub server
    #
    # Supports automatic ordering of collections on change
    # Use a sync_scope with an order clause to enable this.
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
    #   Sync all changes (new, update, destroy) to an Sync::Scope collection
    #   <%= sync partial: 'todo', collection: Todo.top %>
    #
    def sync(options = {})
      collection   = options[:collection] || [options.fetch(:resource)]
      scope        = options[:channel] || options[:scope] || (collection.is_a?(Sync::Scope) ? collection : nil)
      partial_name = options.fetch(:partial, scope)
      refetch      = options.fetch(:refetch, false)
      order        = Sync::OrderInfo.new(collection)
      direction    = options.fetch(:direction, order.empty? ? :append : :sort)
      limit        = limit_info(collection)

      new_resource = if options[:new]
        options[:new]
      elsif collection.is_a?(ActiveRecord::Relation) || collection.is_a?(Sync::Scope)
        collection.new
      else
        false
      end

      results = []
      
      if new_resource
        results << container_start_tag(partial_name, new_resource, scope, refetch, direction, order)
      else
        results << container_start_tag_empty
      end
      
      collection.each do |resource|
        if refetch
          partial = RefetchPartial.new(partial_name, resource, scope, self)
        else
          partial = Partial.new(partial_name, resource, scope, self)
        end
        results << partial_tags(partial, refetch)
      end

      results << container_end_tag
      safe_join(results)
    end

    # DEPRECATED: Setup listener for new resource from sync_new channel, 
    # appending partial in place
    #
    def sync_new(options = {})
      warn "[DEPRECATION] `sync_new` is deprecated. See CHANGELOG for details."
    end
    
    private
    
    def partial_tags(partial, refetch)
      "<script type='text/javascript' data-sync-order='#{partial.order_values_string}' 
        data-sync-id='#{partial.selector_start}'>
        Sync.onReady(function(){
          var partial = new Sync.Partial({
            name:           '#{partial.name}',
            resourceName:   '#{partial.resource.name}',
            resourceId:     '#{partial.resource.model.id}',
            authToken:      '#{partial.refetch_auth_token}',
            channelUpdate:  '#{partial.channel_for_action(:update)}',
            channelDestroy: '#{partial.channel_for_action(:destroy)}',
            selectorStart:  '#{partial.selector_start}',
            selectorEnd:    '#{partial.selector_end}',
            refetch:        #{refetch}
          });
          partial.subscribe();
        });
      </script>
      #{partial.render}
      <script type='text/javascript' data-sync-id='#{partial.selector_end}'>
      </script>".html_safe
    end
    
    def container_start_tag_empty
      "<script type='text/javascript' data-sync-start></script>".html_safe
    end
    
    def container_start_tag(partial_name, resource, scope, refetch, direction, order)
      if refetch
        creator = RefetchPartialCreator.new(partial_name, resource, scope, self)
      else
        creator = PartialCreator.new(partial_name, resource, scope, self)
      end
      "<script type='text/javascript' data-sync-order='#{order.directions_string}'
        data-sync-start data-sync-id='#{creator.selector}'>
        Sync.onReady(function(){
          var creator = new Sync.PartialCreator({
            name:         '#{partial_name}',
            resourceName: '#{creator.resource.name}',
            channel:      '#{creator.channel}',
            selector:     '#{creator.selector}',
            direction:    '#{direction}',
            refetch:      #{refetch}
          });
          creator.subscribe();
        });
      </script>".html_safe
    end
    
    def container_end_tag
      "<script type='text/javascript' data-sync-end></script>".html_safe
    end
    
    # Extract the limit info, if an ActiveRecord::Relation or Sync::Scope 
    # is passed.
    #
    def limit_info(collection)
      collection.arel.limit if collection.respond_to?(:arel)
    end
  end
end
