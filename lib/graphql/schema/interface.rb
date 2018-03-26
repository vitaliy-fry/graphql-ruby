# frozen_string_literal: true
module GraphQL
  class Schema
    module Interface
      extend GraphQL::Schema::Member::Concern
      include GraphQL::Schema::Member
      include GraphQL::Schema::Member::HasFields
      extend GraphQL::Schema::Member::AcceptsDefinition

      included do
        class << self
          def apply_implemented(object_class)
            object_class.include(self)
          end

          def to_graphql
            type_defn = GraphQL::InterfaceType.new
            type_defn.name = graphql_name
            type_defn.description = description
            type_defn.orphan_types = orphan_types
            fields.each do |field_name, field_inst|
              field_defn = field_inst.graphql_definition
              type_defn.fields[field_defn.name] = field_defn
            end
            if respond_to?(:resolve_type)
              type_defn.resolve_type = method(:resolve_type)
            end
            type_defn
          end

          # Here's the tricky part. Make sure behavior keeps making its way down the inheritance chain.
          def append_features(child_class)
            if !child_class.is_a?(Class)
              # In this case, it's been included into another interface.
              # This is how interface inheritance is implemented
              child_class.include(GraphQL::Schema::Interface)
              child_class.extend(GraphQL::Schema::Member::DSLMethods)
              child_class.own_interfaces << self
            end
            super
          end

          def orphan_types(*types)
            if types.any?
              @orphan_types = types
            else
              all_orphan_types = @orphan_types || []
              all_orphan_types += super if defined?(super)
              all_orphan_types.uniq
            end
          end
        end
      end
    end
  end
end
