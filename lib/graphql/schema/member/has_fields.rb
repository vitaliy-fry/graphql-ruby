# frozen_string_literal: true
module GraphQL
  class Schema
    module Member
      # Shared code for Object and Interface
      module HasFields
        extend GraphQL::Schema::Member::Concern

        included do
          class << self
            # Add a field to this object or interface with the given definition
            # @see {GraphQL::Schema::Field#initialize} for method signature
            # @return [void]
            def field(*args, **kwargs, &block)
              kwargs[:owner] = self
              field_defn = field_class.new(*args, **kwargs, &block)
              add_field(field_defn)
              nil
            end

            # @return [Hash<String => GraphQL::Schema::Field>] Fields on this object, keyed by name, including inherited fields
            def fields
              f = {}

              if respond_to?(:superclass) && superclass.respond_to?(:fields)
                f.merge!(superclass.fields)
              end

              own_interfaces.each do |int|
                if int.is_a?(Module)
                  int.fields.each do |name, field|
                    f[name] = field
                  end
                else
                  int.all_fields.each do |legacy_f|
                    f[legacy_f.name] = GraphQL::Schema::Field.new(legacy_f.name, field: legacy_f, owner: int)
                  end
                end
              end

              # Local overrides take precedence over inherited fields
              f.merge!(own_fields)

              f
            end

            # Register this field with the class, overriding a previous one if needed
            # @param field_defn [GraphQL::Schema::Field]
            # @return [void]
            def add_field(field_defn)
              own_fields[field_defn.name] = field_defn
              nil
            end

            # @return [Class] The class to initialize when adding fields to this kind of schema member
            def field_class(new_field_class = nil)
              if new_field_class
                @field_class = new_field_class
              elsif @field_class
                @field_class
              else
                ancestors[1..-1].each do |anc|
                  if anc < HasFields
                    return anc.field_class
                  end
                end
                GraphQL::Schema::Field
              end
            end

            def global_id_field(field_name)
              field field_name, "ID", null: false, resolve: GraphQL::Relay::GlobalIdResolve.new(type: self)
            end

            # @return [Array<GraphQL::Schema::Field>] Fields defined on this class _specifically_, not parent classes
            def own_fields
              @own_fields ||= {}
            end

            def own_interfaces
              @own_interfaces ||= []
            end
          end
        end
      end
    end
  end
end
