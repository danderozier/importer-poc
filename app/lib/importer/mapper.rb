# frozen_string_literal: true

module Importer
  class Mapper
    attr_reader :klass, :columns, :importable, :unique

    class Column < Dry::Struct
      attribute :index, Types::Coercible::Integer
      attribute :key, Types::Coercible::Symbol
      attribute :overwrite, Types::Bool.default(false)
    end

    # @param [Object] Model to import
    # @param [Array] Mapping of column indexes to attribute keys
    # @param [Array] Unique keys to find_or_create on
    def initialize(klass, params, find_by_keys)
      @columns = params.map { |m| Column.new(m) }
      find_by_keys = Array(find_by_keys)

      @klass = klass
      @unique, @importable = @columns.partition do |c|
        find_by_keys.include? c.key
      end
    end

    def import(row)
      record = find_or_initialize(row)
      action = record.new_record? ? :create : :update

      importable.each do |col|
        next unless col.overwrite || record.send(col.key).nil?

        record.send("#{col.key}=", row[col.index])
      end

      return [:skip, {}] unless record.changed?

      if record.save
        [action, saved_changes_for(record)]
      else
        [:error, errors_for(record) ]
      end
    end

    def saved_changes_for(record)
      record.saved_changes.symbolize_keys.slice(*importable_keys)
    end

    def errors_for(record)
      record.errors.messages.slice(*importable_keys)
    end

    def query_params_for(row)
      unique.each_with_object({}) do |col, obj|
        obj[col.key] = row[col.index]
      end
    end

    def find_or_initialize(row)
      klass.find_or_initialize_by(query_params_for(row))
    end

    def importable_keys
      columns.map(&:key)
    end
  end
end