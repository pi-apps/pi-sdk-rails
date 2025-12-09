# frozen_string_literal: true
#
# PiTransactionBehavior is a host-app-includeable Rails concern.
# It adds useful Pi Network business logic to any app model storing Pi transaction state
# (idempotency, anti-fraud, deduplication, state transitions, etc.).
#
# Usage:
#   class PiTransaction < ApplicationRecord
#     include PiNetwork::Rails::PiTransactionBehavior
#     # ...
#   end
#
# Methods may be used or overridden by the host app.

require 'active_support/concern'

module PiSdk
  module PiTransactionBehavior
    extend ActiveSupport::Concern

    included do
      # Optionally, validations or callbacks here
      # validates :pi_payment_id, uniqueness: true
    end

    class_methods do
      # Finds or creates a PiTransaction by pi_payment_id (unique).
      # If found, updates state (if present in options) and saves.
      # If not found, fetches PaymentDTO, instantiates and fills transaction fields, saves.
      # @param payment_id [String] The Pi Network payment ID
      # @param options [Hash] Options, e.g. :state (Symbol or String)
      # @return [self] transaction instance (always saved)
      def find_or_create_by_pi_payment_id(payment_id, **options)
        tx = find_by_pi_payment_id(payment_id)
        if tx
          tx.state = options[:state].to_s if options[:state]
          tx.save!
          return tx
        end
        payment_dto = ::PiSdk::PaymentDTO.get(payment_id)
        tx = new(payment_id: payment_id, **options)
        if payment_dto
          tx.amount   = payment_dto.amount_decimal
          tx.memo     = payment_dto.description
          tx.txid     = payment_dto.txid
          tx.metadata = payment_dto.metadata
          tx.order_id = tx.metadata[self::ORDER_KEY_NAME.to_s]
        end
        tx.state = options[:state].to_s if options[:state]
        tx.save!
        tx
      end

      def find_by_pi_payment_id(payment_id)
        where(payment_id: payment_id).first
      end
    end

    # Returns true if this transaction has already been processed (approved/complete/etc), for anti-fraud/idempotency
    # Override to reflect your state column(s)
    def processed?
      !!(respond_to?(:processed) ? processed : nil)
    end

    # Mark the transaction as processed/approved (should set state column, persist record as needed)
    # Override for custom state logic
    def mark_as_processed!
      if respond_to?(:processed=)
        self.processed = true
        save!
      else
        raise NotImplementedError, "Include a :processed column and override this method as appropriate."
      end
    end

    # Mark transaction as canceled (if supported in your schema)
    def mark_as_canceled!
      if respond_to?(:canceled=)
        self.canceled = true
        save!
      else
        raise NotImplementedError, 'Include a :canceled column and override this method as appropriate.'
      end
    end

    # Returns true if this transaction has been canceled
    def canceled?
      !!(respond_to?(:canceled) ? canceled : nil)
    end

    # Override or extend to include further business/engine logic as needed
  end
end
