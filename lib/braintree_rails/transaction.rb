module BraintreeRails
  class Transaction
    include Model
    singleton_class.not_supported_apis(:delete)
    not_supported_apis(:update, :update!, :destroy)

    define_attributes(
      :create => [
        :amount, :billing, :channel, :custom_fields, :customer_id, :descriptor, :merchant_account_id,
        :options, :order_id, :payment_method_token, :purchase_order_number, :recurring, :shipping,
        :tax_amount, :tax_exempt, :type, :venmo_sdk_payment_method_code
      ],
      :readonly => [
        :avs_error_response_code, :avs_postal_code_response_code, :avs_street_address_response_code, :billing_details,
        :channel, :created_at, :credit_card, :credit_card_details, :currency_iso_code, :customer, :customer_details,
        :cvv_response_code, :id, :plan_id, :purchase_order_number, :refund_ids, :refunded_transaction_id, :settlement_batch_id,
        :shipping_details, :status, :status_history, :subscription_details, :updated_at
      ]
    )

    has_many   :add_ons,      :class => AddOns
    has_many   :discounts,    :class => Discounts
    has_one    :billing,      :class => BillingAddress,  :foreign_key => :billing_details
    has_one    :shipping,     :class => ShippingAddress, :foreign_key => :shipping_details
    belongs_to :customer,     :class => Customer,        :foreign_key => :customer_details
    belongs_to :credit_card,  :class => CreditCard,      :foreign_key => :credit_card_details
    belongs_to :subscription, :class => Subscription,    :foreign_key => :subscription_id
    belongs_to :plan,         :class => Plan,            :foreign_key => :plan_id

    around_persist :clear_encryped_attributes

    def type
      @type ||= 'sale'
    end

    def submit_for_settlement(amount = nil)
      submit_for_settlement!(amount)
    rescue RecordInvalid
      false
    end

    def submit_for_settlement!(amount = nil)
      !!with_update_braintree(:submit_for_settlement) {Braintree::Transaction.submit_for_settlement!(id, amount)}
    end

    def refund(amount = nil)
      refund!(amount)
    rescue RecordInvalid
      false
    end

    def refund!(amount = nil)
      !!with_update_braintree(:refund) {Braintree::Transaction.refund!(id, amount)}
    end

    def void
      void!
    rescue RecordInvalid
      false
    end

    def void!
      !!with_update_braintree(:void) {Braintree::Transaction.void!(id)}
    end

    def add_errors(validation_errors)
      propergate_errors_to_associations(validation_errors)
      super(validation_errors)
    end

    def clear_encryped_attributes
      yield if block_given?
    ensure
      credit_card.clear_encryped_attributes if credit_card.present?
    end

    def attributes
      super.except(:customer_details, :credit_card_details, :billing_details, :shipping_details, :subscription_details, :status_history, :descriptor)
    end

    protected

    def propergate_errors_to_associations(validation_errors)
      [customer, credit_card, billing, shipping].each do |association|
        association.add_errors(validation_errors.except('base')) if association
      end
    end

    def attributes_for(action)
      super.merge(customer_attributes).merge(credit_card_attributes)
    end

    def customer_attributes
      if customer.present?
        if customer.persisted?
          {:customer_id => customer.id}
        else
          {:customer => customer.attributes_for(:as_association)}
        end
      else
        {}
      end
    end

    def credit_card_attributes
      if credit_card.present?
        if credit_card.persisted?
          {:payment_method_token => credit_card.token}
        else
          {:credit_card => credit_card.attributes_for(:as_association)}
        end
      elsif customer.present? && customer.default_credit_card
        {:payment_method_token => customer.default_credit_card.token}
      else
        {}
      end
    end
  end
end
