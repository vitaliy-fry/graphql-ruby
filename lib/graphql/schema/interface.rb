# frozen_string_literal: true
module GraphQL
  class Schema
    module Interface
      include GraphQL::Schema::Member
      extend GraphQL::Schema::Member::HasFields
      extend GraphQL::Schema::Member::AcceptsDefinition
      field_class(GraphQL::Schema::Field)
      def self.extended(child_class)
        if !(child_class.singleton_class < GraphQL::Schema::Member::HasFields)
          make_interface(self, child_class)
        end
      end

      class << self
        # When this interface is added to a `GraphQL::Schema::Object`,
        # it calls this method. We add methods to the object by convention,
        # a nested module named `Implementation`
        def apply_implemented(object_class)
          if defined?(self::Implementation)
            object_class.include(self::Implementation)
          end
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

        def make_interface(parent_class, child_class)
          child_class.class_eval do
            puts "make_interface: #{child_class} < #{parent_class}(#{parent_class.field_class})"
            include GraphQL::Schema::Member
            extend GraphQL::Schema::Member::HasFields
            extend GraphQL::Schema::Interface
            field_class(parent_class.field_class)
            class << self
              alias :old_extended :extended
              def extended(next_child_class)
                puts "mi extended: #{next_child_class} < #{self}"
                GraphQL::Schema::Interface.make_interface(self, next_child_class)
                old_extended(next_child_class)
              end
            end
          end
        end
      end
    end
  end
end
