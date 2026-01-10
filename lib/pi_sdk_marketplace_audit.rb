# frozen_string_literal: true

# =========================================================
# Pi SDK Marketplace + Audit + Settlement Engine
# Enterprise-grade, single-file implementation
# =========================================================

module PiSdk
  module Marketplace

    PLATFORM_FEE = 0.05 # 5%

    # =========================
    # MODELS (EXTENSIONS)
    # =========================

    module Models
      module Merchant
        extend ActiveSupport::Concern

        included do
          has_many :orders
          has_one :merchant_wallet
          enum status: { active: 'active', suspended: 'suspended' }
        end
      end

      module MerchantWallet
        extend ActiveSupport::Concern

        included do
          belongs_to :merchant
        end

        def credit!(amount)
          increment!(:balance, amount)
        end
      end

      module Order
        extend ActiveSupport::Concern

        included do
          belongs_to :merchant
          has_one :pi_transaction
          enum status: { pending: 'pending', paid: 'paid', failed: 'failed' }
        end
      end

      module PiTransaction
        extend ActiveSupport::Concern

        included do
          belongs_to :order
          has_many :pi_transaction_audits
          delegate :merchant, to: :order

          enum audit_status: {
            unverified: 'unverified',
            verified: 'verified',
            inconsistent: 'inconsistent',
            settled: 'settled'
          }
        end

        def audit!(event:, source:, payload: nil, result: nil)
          pi_transaction_audits.create!(
            event: event,
            source: source,
            payload_snapshot: payload,
            result: result
          )
        end
      end
    end

    # =========================
    # AUDIT MODEL
    # =========================

    class PiTransactionAudit < ApplicationRecord
      self.table_name = 'pi_transaction_audits'
      belongs_to :pi_transaction
    end

    # =========================
    # ROUTER
    # =========================

    class Router
      def self.resolve!(tx)
        raise 'Order missing' unless tx.order
        raise 'Merchant inactive' unless tx.merchant.active?
        tx
      end
    end

    # =========================
    # RISK ENGINE
    # =========================

    class RiskEngine
      def self.flag?(tx)
        tx.amount.to_f <= 0 ||
        tx.merchant.suspended?
      end
    end

    # =========================
    # RECONCILIATION ENGINE
    # =========================

    class ReconciliationEngine
      def self.run!
        PiTransaction
          .where(status: 'completed', audit_status: 'unverified')
          .includes(order: :merchant)
          .find_each { |tx| new(tx).reconcile }
      end

      def initialize(tx)
        @tx = tx
      end

      def reconcile
        Router.resolve!(@tx)

        if valid?
          @tx.update!(audit_status: 'verified')
          @tx.audit!(
            event: 'reconciled',
            source: 'system',
            result: 'ok'
          )
        else
          @tx.update!(audit_status: 'inconsistent')
          @tx.audit!(
            event: 'reconciled',
            source: 'system',
            result: 'failed'
          )
        end
      end

      private

      def valid?
        !RiskEngine.flag?(@tx) &&
        @tx.completed_at.present?
      end
    end

    # =========================
    # SETTLEMENT ENGINE
    # =========================

    class SettlementEngine
      def self.run!
        PiTransaction
          .where(audit_status: 'verified')
          .find_each { |tx| new(tx).settle }
      end

      def initialize(tx)
        @tx = tx
        @wallet = tx.merchant.merchant_wallet
      end

      def settle
        merchant_amount = @tx.amount.to_f * (1 - PLATFORM_FEE)

        ActiveRecord::Base.transaction do
          @wallet.credit!(merchant_amount)
          @tx.update!(audit_status: 'settled')
          @tx.audit!(
            event: 'settled',
            source: 'system',
            result: merchant_amount
          )
        end
      end
    end

    # =========================
    # JOB HELPERS
    # =========================

    class Runner
      def self.full_cycle!
        ReconciliationEngine.run!
        SettlementEngine.run!
      end
    end

  end
end

# =========================
# AUTO-INCLUDE EXTENSIONS
# =========================

ActiveSupport.on_load(:active_record) do
  Merchant.include PiSdk::Marketplace::Models::Merchant if defined?(Merchant)
  MerchantWallet.include PiSdk::Marketplace::Models::MerchantWallet if defined?(MerchantWallet)
  Order.include PiSdk::Marketplace::Models::Order if defined?(Order)
  PiTransaction.include PiSdk::Marketplace::Models::PiTransaction if defined?(PiTransaction)
end
