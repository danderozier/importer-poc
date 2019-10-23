require 'rails_helper'

RSpec.describe Importer::Base, type: :model do
  subject { ContactImporter.new(mappings) }

  let(:mappings) do
    [
      { index: 0, key: :member_id, overwrite: false },
      { index: 1, key: :name, overwrite: false },
      { index: 2, key: :address, overwrite: true },
      { index: 3, key: :organization, overwrite: true },
      { index: 4, key: :email, overwrite: false }
    ]
  end
  let(:data) do
    [
      ['12345', 'John X. Doe', '123 Main St', 'Apple', 'johndoe@test.com' ],
      ['45678', 'Jane Roe', '420 Elm St', 'Microsoft', 'janeroe@test.com' ],
      ['8', 'T', '69 Mott St', 'Google', 'invalid@test.com' ],
    ]
  end

  describe 'import' do
    before(:example) do
      Contact.create(name: 'John Doe', email: 'johndoe@test.com', member_id: nil, address: nil, organization: 'LinkedIn')
      @result = subject.import(data)
    end

    it 'updates the existing contact' do
      c = Contact.find_by_email('johndoe@test.com')
      expect(c.address).to eq('123 Main St')
      expect(c.member_id).to eq('12345')
      expect(c.name).to eq('John Doe')
      expect(c.organization).to eq('Apple')
    end

    it 'creates a new contact' do
      c = Contact.find_by_email('janeroe@test.com')
      expect(c.address).to eq('420 Elm St')
      expect(c.member_id).to eq('45678')
      expect(c.name).to eq('Jane Roe')
      expect(c.organization).to eq('Microsoft')
    end

    it 'does not create the invalid contact' do
      c = Contact.find_by_email('invalid@test.com')
      expect(c).to be_nil
    end

    it 'returns correct results' do
      expect(@result).to eq(
        0 => {
          updated: {
            address: [nil, '123 Main St'],
            member_id: [nil, '12345'],
            organization: ['LinkedIn', 'Apple']
          }
        },
        1 => {
          created: {
            address: [nil, '420 Elm St'],
            email: [nil, 'janeroe@test.com'],
            member_id: [nil, '45678'],
            name: [nil, 'Jane Roe'],
            organization: [nil, 'Microsoft']
          }
        },
        2 => {
          errors: {
            member_id: ['must be five digits'],
            name: ['is too short (minimum is 2 characters)']
          }
        }
      )
    end
  end
end
