module Grape
  module Formatter
    module ActiveModelSerializers
      class << self
        def call(resource, env)
          serializer = fetch_serializer(resource, env)

          if serializer
            serializer.to_json
          else
            Grape::Formatter::Json.call resource, env
          end
        end

        # {
        #   serializer: ArraySerializer,
        #   serializer_options: {
        #     serializer: EachSerializer,
        #     meta: {}
        #   },
        #   adapter_options: {
        #     include: []
        #   },
        #   scope: ...
        # }
        def fetch_serializer(resource, env)
          endpoint = env['api.endpoint']
          options = build_options_from_endpoint(endpoint)
          ams_options = env['ams_options'] || {}
          raise "error" unless ams_options.is_a? Hash
          options.merge!(ams_options)

          serializer = options.fetch(:serializer, ActiveModel::Serializer.serializer_for(resource))
          return nil unless serializer

          options[:scope] = endpoint unless options.key?(:scope)

          # Map shorthand aliases
          options[:serializer_options] ||= {}
          options[:adapter_options] ||= {}
          options[:serializer_options][:meta] = options[:meta] if options[:meta]
          options[:serializer_options][:meta_key] = options[:meta_key] if options[:meta_key]
          options[:serializer_options][:serializer] = options[:each_serializer] if options[:each_serializer]
          options[:serializer_options][:scope] = options[:scope] if options[:scope]
          options[:serializer_options][:only] = options[:only] if options[:only]
          options[:serializer_options][:except] = options[:except] if options[:except]
          options[:adapter_options][:include] = options[:include] if options[:include]

          serializer_instance = serializer.new(resource, options[:serializer_options])
          ActiveModel::Serializer::Adapter.create(serializer_instance, options[:adapter_options])
        end

        def build_options_from_endpoint(endpoint)
          [endpoint.default_serializer_options || {}, endpoint.namespace_options, endpoint.route_options, endpoint.options, endpoint.options.fetch(:route_options)].reduce(:merge)
        end

        # array root is the innermost namespace name ('space') if there is one,
        # otherwise the route name (e.g. get 'name')
        # def default_root(endpoint)
          # innermost_scope = if endpoint.respond_to?(:namespace_stackable)
                              # endpoint.namespace_stackable(:namespace).last
                            # else
                              # endpoint.settings.peek[:namespace]
                            # end

          # if innermost_scope
            # innermost_scope.space
          # else
            # endpoint.options[:path][0].to_s.split('/')[-1]
          # end
        # end
      end
    end
  end
end
