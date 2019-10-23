# frozen_string_literal: true

module Importer
  class Base
    attr_reader :mapper

    def initialize(klass, mappings, unique_keys)
      @mapper = Mapper.new(klass, mappings, unique_keys)
    end

    def import(data)
      results = {}
      data.each_with_index do |row, index|
        results[index] = mapper.import(row)
      end
      results
    end

    def dry_run(data)
      ActiveRecord::Base.transaction do
        execute(data)
      end
    end
  end
end