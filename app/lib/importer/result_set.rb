# frozen_string_literal: true

module Importer
  class ResultSet < Dry::Struct
    extend Forwardable

    ALLOWED_TYPES = %w[create update skip error]

    class Result < Dry::Struct
      class DuplicateIndexError < Dry::Struct::Error
        def initialize(index)
          super("A result with index #{index} already exists")
        end
      end

      attribute :type, Types::Coercible::String.constrained(included_in: ALLOWED_TYPES)
      attribute :index, Types::Coercible::Integer
      attribute :details, Types::Hash.default { Hash.new }
    end

    attribute :results, Types::Array.of(Result).default { Array.new }

    # Delegate #to_h and #length to the results array.
    def_delegators :results, :to_h, :length

    # Add a result
    #
    # @param [String, Symbol] Result type: `create`, `update`, `skip`, or `error`
    # @param [Number] Row index of result
    # @param [Hash] Result details. For `create` or `update` this should be
    #   results of #saved_changes_for; for `error` it should be results of #errors.
    def add(type, index:, details:)
      raise Result::DuplicateIndexError.new(index)  if find(index)

      results << Result.new(type: type, index: index, details: details)
    end

    # Find result for a given row index.
    #
    # @param [Number] index
    # @return [Importer::ResultSet::Result]
    def find(index)
      results.find { |r| r.index == index }
    end

    # Fetch all results of type `create`
    #
    # @return [Array]
    def created
      fetch_results('create')
    end

    # Fetch all results of type `update`
    #
    # @return [Array]
    def updated
      fetch_results('update')
    end

    # Fetch all results of type `error`
    #
    # @return [Array]
    def errors
      fetch_results('error')
    end

    # Fetch all results of type `skip`
    #
    # @return [Array]
    def skipped
      fetch_results('skip')
    end

    private

    # Fetch all results of the given type.
    #
    # @param [String, Symbol] type
    # @return [Hash]
    def fetch_results(type)
      results.select { |r| r.type == type }
    end
  end
end
