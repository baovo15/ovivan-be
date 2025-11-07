module ActionDispatch
  module Routing
    class Mapper
      def mresources(resource, **options)
        # Get namespace from @scope[:module] (e.g., "authentication")
        # Get scope (path) from @scope[:path] (e.g., ["", "authentication", "api", "v1"])
        scope_path = (@scope[:path]&.split("/") || []).reject(&:empty?) # Remove empty elements

        # Remove duplication between namespace & scope (Rails already prefixes the namespace in routes)
        full_namespace_path = scope_path.uniq

        # Ensure "application/controllers" is injected **only after authentication**
        transformed_namespace = full_namespace_path.dup
        if !transformed_namespace.include?("applications")
          transformed_namespace = [ "webs", "controllers" ] + scope_path[1..-1]
        end



        # Extract the controller name (default to resource name)
        controller_name = options.delete(:controller) || resource

        # Construct the correct controller reference
        full_controller_path = (transformed_namespace + [ controller_name ]).join("/")

        # Debugging log to check the computed controller path
        Rails.logger.info "Mapped Controller Path: #{full_controller_path}"

        # Define the resources route, letting Rails automatically handle namespace prefixing
        resources resource, controller: full_controller_path.underscore, **options
      end
    end
  end
end
