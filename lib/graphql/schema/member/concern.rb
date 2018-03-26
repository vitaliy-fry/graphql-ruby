# frozen_string_literal: true

module GraphQL
  class Schema
    module Member
      # This is borrowed from ActiveSupport::Concern
      # @api private
      module Concern
        def self.extended(base)
          base.instance_variable_set(:@_dependencies, [])
        end

        def append_features(base)
          if base.instance_variable_defined?(:@_dependencies)
            base.instance_variable_get(:@_dependencies) << self
            false
          else
            return false if base < self
            @_dependencies.each { |dep| base.include(dep) }
            super
            base.extend const_get(:ClassMethods) if const_defined?(:ClassMethods)
            base.class_eval(&@_included_block) if instance_variable_defined?(:@_included_block)
          end
        end

        def included(base = nil, &block)
          if base.nil?
            raise "Multiple included { ... } blocks, merge them" if instance_variable_defined?(:@_included_block)

            @_included_block = block
          else
            super
          end
        end
      end
    end
  end
end
