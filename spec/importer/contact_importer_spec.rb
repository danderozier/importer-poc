require 'rails_helper'

RSpec.describe ContactImporter, type: :model do
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
      ['99999', 'George Burns', '69 Mott St', 'The Funny Pages', 'georgeburns@test.com']
    ]
  end

  describe 'dry run' do
    before(:example) do
      @contact_1 = Contact.create(name: 'John Doe', email: 'johndoe@test.com', member_id: nil, address: nil, organization: 'LinkedIn')
      @contact_2 = Contact.create(name: 'George Burns', email: 'georgeburns@test.com', member_id: '99999', address: '69 Mott St', organization: 'The Funny Pages')
      @results = subject.dry_run(data)
    end

    it 'does not update the existing contact' do
      c = Contact.find_by_email('johndoe@test.com')
      expect(c).to eq(@contact_1)
      # expect(c.address).to be_nil
      # expect(c.member_id).to be_nil
      # expect(c.name).to eq('John Doe')
      # expect(c.organization).to eq('LinkedIn')
    end

    it 'does not create a new contact' do
      c = Contact.find_by_email('janeroe@test.com')
      expect(c).to be_nil
    end

    it 'does not create an invalid contact' do
      c = Contact.find_by_email('invalid@test.com')
      expect(c).to be_nil
    end

    it 'does not modify an existing contact with unchanged data' do
      c = Contact.find_by_email('georgeburns@test.com')
      expect(c).to eq(@contact_2)
    end

    it 'returns correct results' do
      expect(@results.length).to eq(4)

      expect(@results.updated.length).to eq(1)
      expect(@results.updated[0].type).to eq('update')
      expect(@results.updated[0].index).to eq(0)
      expect(@results.updated[0].details).to eq(
        address: [nil, '123 Main St'],
        member_id: [nil, '12345'],
        organization: ['LinkedIn', 'Apple']
      )

      expect(@results.created.length).to eq(1)
      expect(@results.created[0].type).to eq('create')
      expect(@results.created[0].index).to eq(1)
      expect(@results.created[0].details).to eq(
        address: [nil, '420 Elm St'],
        email: [nil, 'janeroe@test.com'],
        member_id: [nil, '45678'],
        name: [nil, 'Jane Roe'],
        organization: [nil, 'Microsoft']
      )

      expect(@results.errors.length).to eq(1)
      expect(@results.errors[0].type).to eq('error')
      expect(@results.errors[0].index).to eq(2)
      expect(@results.errors[0].details).to eq(
        member_id: ['must be five digits'],
        name: ['is too short (minimum is 2 characters)']
      )

      expect(@results.skipped.length).to eq(1)
      expect(@results.skipped[0].type).to eq('skip')
      expect(@results.skipped[0].index).to eq(3)
      expect(@results.skipped[0].details).to eq({})
    end
  end

  describe 'import' do
    before(:example) do
      Contact.create(name: 'John Doe', email: 'johndoe@test.com', member_id: nil, address: nil, organization: 'LinkedIn')
      @contact = Contact.create(name: 'George Burns', email: 'georgeburns@test.com', member_id: '99999', address: '69 Mott St', organization: 'The Funny Pages')
      @results = subject.import(data)
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

    it 'does not modify an existing contact with unchanged data' do
      c = Contact.find_by_email('georgeburns@test.com')
      expect(c).to eq(@contact)
    end

    it 'returns correct results' do
      expect(@results.length).to eq(4)

      expect(@results.updated.length).to eq(1)
      expect(@results.updated[0].type).to eq('update')
      expect(@results.updated[0].index).to eq(0)
      expect(@results.updated[0].details).to eq(
        address: [nil, '123 Main St'],
        member_id: [nil, '12345'],
        organization: ['LinkedIn', 'Apple']
      )

      expect(@results.created.length).to eq(1)
      expect(@results.created[0].type).to eq('create')
      expect(@results.created[0].index).to eq(1)
      expect(@results.created[0].details).to eq(
        address: [nil, '420 Elm St'],
        email: [nil, 'janeroe@test.com'],
        member_id: [nil, '45678'],
        name: [nil, 'Jane Roe'],
        organization: [nil, 'Microsoft']
      )

      expect(@results.errors.length).to eq(1)
      expect(@results.errors[0].type).to eq('error')
      expect(@results.errors[0].index).to eq(2)
      expect(@results.errors[0].details).to eq(
        member_id: ['must be five digits'],
        name: ['is too short (minimum is 2 characters)']
      )

      expect(@results.skipped.length).to eq(1)
      expect(@results.skipped[0].type).to eq('skip')
      expect(@results.skipped[0].index).to eq(3)
      expect(@results.skipped[0].details).to eq({})
    end
  end
end
