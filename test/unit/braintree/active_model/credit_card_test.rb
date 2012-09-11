require File.expand_path(File.join(File.dirname(__FILE__), '../../unit_test_helper'))

describe Braintree::ActiveModel::CreditCard do
  before do
    stub_braintree_request(:get, '/payment_methods/credit_card_id', :body => fixture('credit_card.xml'))
  end

  describe '#initialize' do
    it 'should find credit_card from braintree when given a credit_card id' do
      credit_card = Braintree::ActiveModel::CreditCard.new('credit_card_id')
      braintree_credit_card = Braintree::CreditCard.find('credit_card_id')

      credit_card.persisted?.must_equal true
      Braintree::ActiveModel::CreditCard::Attributes.each do |attribute|
        credit_card.send(attribute).must_equal(braintree_credit_card.send(attribute)) if braintree_credit_card.respond_to?(attribute)
      end
    end

    it 'should wrap a Braintree::CreditCard' do
      braintree_credit_card = Braintree::CreditCard.find('credit_card_id')
      credit_card = Braintree::ActiveModel::CreditCard.new(braintree_credit_card)

      credit_card.persisted?.must_equal true
      Braintree::ActiveModel::CreditCard::Attributes.each do |attribute|
        credit_card.send(attribute).must_equal(braintree_credit_card.send(attribute)) if braintree_credit_card.respond_to?(attribute)
      end
    end

    it 'should extract values from hash' do
      credit_card = Braintree::ActiveModel::CreditCard.new(:token => 'new_id')

      credit_card.persisted?.must_equal false
      credit_card.token.must_equal 'new_id'
    end

    it 'should try to extract value from other types' do
      credit_card = Braintree::ActiveModel::CreditCard.new(OpenStruct.new(:token => 'foobar', :cardholder_name => 'Foo Bar', :persisted? => true))

      credit_card.persisted?.must_equal true
      credit_card.token.must_equal 'foobar'
      credit_card.cardholder_name.must_equal 'Foo Bar'

      credit_card = Braintree::ActiveModel::CreditCard.new(OpenStruct.new({}))
      credit_card.persisted?.must_equal false
    end
  end

  describe '#billing_address' do
    it 'should wrap billing_address with Address object' do
      credit_card = Braintree::ActiveModel::CreditCard.new(OpenStruct.new(:billing_address => nil))
      credit_card.billing_address.class.ancestors.must_include Braintree::ActiveModel::Address

      credit_card = Braintree::ActiveModel::CreditCard.new(OpenStruct.new(:billing_address => {}))
      credit_card.billing_address.class.ancestors.must_include Braintree::ActiveModel::Address

      credit_card.billing_address= Braintree::ActiveModel::Address.new({})
      credit_card.billing_address.class.ancestors.must_include Braintree::ActiveModel::Address
    end
  end

  describe 'validations' do
    it 'should validate precence of customer_id if new_record?' do
      credit_card = Braintree::ActiveModel::CreditCard.new({})
      credit_card.valid?
      credit_card.errors[:customer_id].wont_be :blank?

      credit_card = Braintree::ActiveModel::CreditCard.new({:customer_id => 'foo'})
      credit_card.valid?
      credit_card.errors[:customer_id].must_be :blank?
    end

    it 'should validate length of customer_id' do
      credit_card = Braintree::ActiveModel::CreditCard.new({:customer_id => 'foo' * 13})
      credit_card.valid?
      credit_card.errors[:customer_id].wont_be :blank?

      credit_card = Braintree::ActiveModel::CreditCard.new({:customer_id => 'foo'})
      credit_card.valid?
      credit_card.errors[:customer_id].must_be :blank?

      credit_card = Braintree::ActiveModel::CreditCard.new({:customer_id => 'foo' * 12})
      credit_card.valid?
      credit_card.errors[:customer_id].must_be :blank?
    end

    it 'should validate precence of number if new_record?' do
      credit_card = Braintree::ActiveModel::CreditCard.new({})
      credit_card.valid?
      credit_card.errors[:number].wont_be :blank?

      credit_card = Braintree::ActiveModel::CreditCard.new({:number => '4111111111111'})
      credit_card.valid?
      credit_card.errors[:number].must_be :blank?
    end

    it 'should validate numericality of number' do
      credit_card = Braintree::ActiveModel::CreditCard.new({:number => 'foobar'})
      credit_card.valid?
      credit_card.errors[:number].wont_be :blank?

      credit_card = Braintree::ActiveModel::CreditCard.new({:number => '4111111111111'})
      credit_card.valid?
      credit_card.errors[:number].must_be :blank?
    end

    it 'should validate length of number' do
      credit_card = Braintree::ActiveModel::CreditCard.new({:number => '1'})
      credit_card.valid?
      credit_card.errors[:number].wont_be :blank?

      credit_card = Braintree::ActiveModel::CreditCard.new({:number => '1' * 20})
      credit_card.valid?
      credit_card.errors[:number].wont_be :blank?

      credit_card = Braintree::ActiveModel::CreditCard.new({:number => '1' * 12})
      credit_card.valid?
      credit_card.errors[:number].must_be :blank?

      credit_card = Braintree::ActiveModel::CreditCard.new({:number => '1' * 19})
      credit_card.valid?
      credit_card.errors[:number].must_be :blank?
    end

    it 'should validate precence of cvv' do
      credit_card = Braintree::ActiveModel::CreditCard.new({})
      credit_card.valid?
      credit_card.errors[:cvv].wont_be :blank?

      credit_card = Braintree::ActiveModel::CreditCard.new({:cvv => '111'})
      credit_card.valid?
      credit_card.errors[:cvv].must_be :blank?
    end

    it 'should validate numericality of cvv' do
      credit_card = Braintree::ActiveModel::CreditCard.new({:cvv => 'foo'})
      credit_card.valid?
      credit_card.errors[:cvv].wont_be :blank?

      credit_card = Braintree::ActiveModel::CreditCard.new({:cvv => '111'})
      credit_card.valid?
      credit_card.errors[:cvv].must_be :blank?
    end

    it 'should validate length of cvv' do
      credit_card = Braintree::ActiveModel::CreditCard.new({:cvv => '1'})
      credit_card.valid?
      credit_card.errors[:cvv].wont_be :blank?

      credit_card = Braintree::ActiveModel::CreditCard.new({:cvv => '1' * 5})
      credit_card.valid?
      credit_card.errors[:cvv].wont_be :blank?

      credit_card = Braintree::ActiveModel::CreditCard.new({:cvv => '111'})
      credit_card.valid?
      credit_card.errors[:cvv].must_be :blank?

      credit_card = Braintree::ActiveModel::CreditCard.new({:cvv => '1111'})
      credit_card.valid?
      credit_card.errors[:cvv].must_be :blank?
    end

    it 'should validate length of cardholder_name' do
      credit_card = Braintree::ActiveModel::CreditCard.new({:cardholder_name => 'f' * 256})
      credit_card.valid?
      credit_card.errors[:cardholder_name].wont_be :blank?

      credit_card = Braintree::ActiveModel::CreditCard.new({:cardholder_name => 'f'})
      credit_card.valid?
      credit_card.errors[:cardholder_name].must_be :blank?

      credit_card = Braintree::ActiveModel::CreditCard.new({:cardholder_name => 'f' * 255})
      credit_card.valid?
      credit_card.errors[:cardholder_name].must_be :blank?
    end

    it 'should validate expiration month' do
      credit_card = Braintree::ActiveModel::CreditCard.new({})
      credit_card.valid?
      credit_card.errors[:expiration_month].wont_be :blank?

      credit_card = Braintree::ActiveModel::CreditCard.new({:expiration_month => 0})
      credit_card.valid?
      credit_card.errors[:expiration_month].wont_be :blank?

      credit_card = Braintree::ActiveModel::CreditCard.new({:expiration_month => 13})
      credit_card.valid?
      credit_card.errors[:expiration_month].wont_be :blank?

      credit_card = Braintree::ActiveModel::CreditCard.new({:expiration_month => 1})
      credit_card.valid?
      credit_card.errors[:expiration_month].must_be :blank?

      credit_card = Braintree::ActiveModel::CreditCard.new({:expiration_month => '12'})
      credit_card.valid?
      credit_card.errors[:expiration_month].must_be :blank?
    end

    it 'should validate expiration year' do
      credit_card = Braintree::ActiveModel::CreditCard.new({})
      credit_card.valid?
      credit_card.errors[:expiration_year].wont_be :blank?

      credit_card = Braintree::ActiveModel::CreditCard.new({:expiration_year => 1975})
      credit_card.valid?
      credit_card.errors[:expiration_year].wont_be :blank?

      credit_card = Braintree::ActiveModel::CreditCard.new({:expiration_year => 2201})
      credit_card.valid?
      credit_card.errors[:expiration_year].wont_be :blank?

      credit_card = Braintree::ActiveModel::CreditCard.new({:expiration_year => 1976})
      credit_card.valid?
      credit_card.errors[:expiration_year].must_be :blank?

      credit_card = Braintree::ActiveModel::CreditCard.new({:expiration_year => '2200'})
      credit_card.valid?
      credit_card.errors[:expiration_year].must_be :blank?
    end

    it 'should validate billing_address' do
      credit_card = Braintree::ActiveModel::CreditCard.new({:billing_address => OpenStruct.new(:valid? => false)})
      credit_card.valid?
      credit_card.errors[:billing_address].wont_be :blank?

      credit_card = Braintree::ActiveModel::CreditCard.new(:billing_address => OpenStruct.new(:valid? => true))
      credit_card.valid?
      credit_card.errors[:billing_address].must_be :blank?
    end
  end
end