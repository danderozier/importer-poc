# frozen_string_literal: true

module Importer
  class Base
    attr_reader :mapper

    alias inspect to_s

    def initialize(klass, mappings, unique_keys)
      @mapper = Mapper.new(klass, mappings, unique_keys)
    end

    def import(data, dry_run: false)
      results = ResultSet.new

      ActiveRecord::Base.transaction do
        data.each_with_index do |row, index|
          result, details = mapper.import(row)
          results.add(result, index: index, details: details)
        end
        raise ActiveRecord::Rollback if dry_run
      end

      results
    end

    def dry_run(data)
      import(data, dry_run: true)
    end
  end
end