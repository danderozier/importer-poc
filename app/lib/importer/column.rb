# frozen_string_literal: true

module Importer
  class Column
    attr_reader :index, :key, :overwrite

    def initialize(index:, key:, overwrite: false)
      @index = index
      @key = key
      @overwrite = overwrite
    end
  end
end