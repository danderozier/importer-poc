require 'rails_helper'

RSpec.describe Importer::Mapper, type: :model do
  subject { described_class.new(Contact, mappings, unique_keys) }

  let(:mappings) do
    [
      { index: 0, key: :member_id, overwrite: false },
      { index: 1, key: :name, overwrite: false },
      { index: 2, key: :address, overwrite: true },
      { index: 3, key: :organization, overwrite: true },
      { index: 4, key: :email, overwrite: false }
    ]
  end
  let(:unique_keys) { :email }
  let(:data) do
    [
      '12345',
      'Test Contact',
      '123 Main St',
      'Acme Packing Co',
      'test@test.com'
    ]
  end

  describe 'unique keys' do

    context 'when one unique key is specified' do
      let(:unique_keys) { :email }

      it 'returns one unique key mapping' do
        expect(subject.query_params_for(data)).to eq(email: 'test@test.com')
      end
    end

    context 'when two unique keys are specified' do
      let(:unique_keys) { %i[email name] }

      it 'returns one unique key mapping' do
        expect(subject.query_params_for(data)).to eq(
          email: 'test@test.com',
          name: 'Test Contact'
        )
      end
    end
  end

  describe 'import' do

    context 'when contact does not exist' do
      before(:example) do
        @type, @details = subject.import(data)
      end

      it 'creates a new contact' do
        c = Contact.find_by_email('test@test.com')
        expect(c).to_not be(nil)
        expect(c.name).to eq('Test Contact')
        expect(c.email).to eq('test@test.com')
        expect(c.address).to eq('123 Main St')
        expect(c.organization).to eq('Acme Packing Co')
        expect(c.member_id).to eq('12345')
      end

      it 'returns correct results' do
        expect(@type).to eq(:create)
        expect(@details).to eq(
          address: [nil, '123 Main St'],
          email: [nil, 'test@test.com'],
          member_id: [nil, '12345'],
          name: [nil, 'Test Contact'],
          organization: [nil, 'Acme Packing Co']
        )
      end
    end

    context 'when contact exists' do
      before(:example) do
        Contact.create(
          name: nil,
          email: 'test@test.com',
          address: '420 Elm St',
          organization: nil,
          member_id: '98765'
        )
        @type, @details = subject.import(data)
      end

      it 'updates the contact' do
        c = Contact.find_by_email('test@test.com')
        # overwrite is true + data doesn't exist = update
        expect(c.organization).to eq('Acme Packing Co')
        # overwrite is true + data exists = update
        expect(c.address).to eq('123 Main St')
        # overwrite is false + data doesn't exist = update
        expect(c.name).to eq('Test Contact')
        # overwrite is false + data exists = don't update
        expect(c.member_id).to eq('98765')
      end

      it 'returns correct results' do
        expect(@type).to eq(:update)
        expect(@details).to eq(
          address: ['420 Elm St', '123 Main St'],
          name: [nil, 'Test Contact'],
          organization: [nil, 'Acme Packing Co']
        )
      end
    end

    context 'when contact exists with same data' do
      before(:example) do
        @contact = Contact.create(
          name: 'Test Contact',
          email: 'test@test.com',
          address: '123 Main St',
          organization: 'Acme Packing Co',
          member_id: '12345'
        )
        @type, @details = subject.import(data)
      end

      it 'does not update the contact' do
        c = Contact.find_by_email('test@test.com')
        expect(c).to eq(@contact)
      end

      it 'returns correct results' do
        expect(@type).to eq(:skip)
        expect(@details).to eq({})
      end
    end

    context 'when given invalid data' do
      let(:data) do
        [
          '6',
          'T',
          '123 Main St',
          'Acme Packing Co',
          'test@test.com'
        ]
      end
      before(:example) do
        @type, @details = subject.import(data)
      end

      it 'does not create a contact' do
        c = Contact.find_by_email('test@test.com')
        expect(c).to be_nil
      end

      it 'returns correct errors' do
        expect(@type).to eq(:error)
        expect(@details).to eq(
          member_id: ['must be five digits'],
          name: ['is too short (minimum is 2 characters)']
        )
      end
    end
  end
end
