# frozen_string_literal: true

class ContactImporter < Importer::Base
  def initialize(mappings)
    super(Contact, mappings, :email)
  end
end