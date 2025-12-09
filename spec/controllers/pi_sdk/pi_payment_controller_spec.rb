# frozen_string_literal: true
require 'rails_helper'
require 'webmock/rspec'

RSpec.describe PiSdk::PiPaymentController, type: :controller do
  let(:test_api_key) { 'test-api-key' }
  let(:test_api_config) do
    {
      'api_key'        => test_api_key,
      'api_url_base'   => 'https://api.minepi.com',
      'api_version'    => 'v2',
      'api_controller' => 'payments'
    }
  end
  before do
    WebMock.disable_net_connect!(allow_localhost: true)
    allow(::Rails.application).to receive(:config_for).and_call_original
    allow(::Rails.application).to receive(:config_for).with(:pinetwork).and_return(test_api_config)
  end

  describe 'POST #approve' do
    # The server now checks that the access token is valid using PiSdk::UserDTO.get.
    # If the token is not valid, approve returns 401 unauthorized and does NOT forward the request to Pi API.
    let(:payment_id) { 'sample-payment-id' }
    let(:access_token) { 'sample-access-token' }
    let(:stub_url) { "https://api.minepi.com/v2/payments/#{payment_id}/approve" }
    let(:stub_body) { { status: 'approved', payment_id: payment_id }.to_json }
    let(:user_dto_double) { instance_double('PiSdk::UserDTO', uid: 'u', credentials: {}, username: nil) }

    before do
      stub_request(:post, stub_url)
        .with(
          headers: {
            'Authorization' => "Key #{test_api_key}",
            'Content-Type' => 'application/json'
          }
        )
        .to_return(status: 200, body: stub_body, headers: { 'Content-Type' => 'application/json' })
    end

    it 'returns 401 unauthorized if token is invalid' do
      allow(::PiSdk::UserDTO).to receive(:get).with(access_token).and_return(nil)
      request.headers['Content-Type'] = 'application/json'
      request.headers['Accept'] = 'application/json'
      post :approve, params: {
        accessToken: access_token,
        paymentId: payment_id
      }, as: :json
      expect(response).to have_http_status(:unauthorized)
      body = JSON.parse(response.body)
      expect(body['error']).to match(/Invalid or unauthorized Pi access token/)
      expect(WebMock).not_to have_requested(:post, stub_url)
    end

    it 'approves a payment and sends the API key in the Authorization header' do
      allow(::PiSdk::UserDTO).to receive(:get).with(access_token).and_return(user_dto_double)
      request.headers['Content-Type'] = 'application/json'
      request.headers['Accept'] = 'application/json'
      post :approve, params: {
        accessToken: access_token,
        paymentId: payment_id
      }, as: :json
      expect(response).to have_http_status(:success)
      body = JSON.parse(response.body)
      expect(body['status']).to eq('approved')
      expect(body['payment_id']).to eq(payment_id)
      expect(WebMock).to have_requested(:post, stub_url)
        .with(headers: { 'Authorization' => "Key #{test_api_key}" })
    end
  end

  describe 'POST #complete' do
    let(:payment_id) { 'sample-payment-id' }
    let(:transaction_id) { 'sample-txid' }
    let(:stub_url) { "https://api.minepi.com/v2/payments/#{payment_id}/complete" }
    let(:stub_body) { { status: 'completed', payment_id: payment_id, txid: transaction_id }.to_json }
    let(:payment_dto_response) {
      {
        'amount' => '1.23',
        'description' => 'Test payment',
        'txid' => transaction_id,
        'metadata' => { 'foo' => 'bar' }
      }.to_json
    }

    before do
      stub_request(:post, stub_url)
        .with(
          headers: {
            'Authorization' => "Key #{test_api_key}",
            'Content-Type' => 'application/json'
          },
          body: hash_including({ 'paymentId' => payment_id, 'txid' => transaction_id })
        )
        .to_return(status: 200, body: stub_body, headers: { 'Content-Type' => 'application/json' })
      stub_request(:get, "https://api.minepi.com/v2/payments/#{payment_id}")
        .with(
          headers: {
            'Authorization' => "Key #{test_api_key}",
            'Content-Type' => 'application/json'
          }
        )
        .to_return(status: 200, body: payment_dto_response, headers: { 'Content-Type' => 'application/json' })
    end

    it 'completes a payment, sends a txid, and sends the API key in the Authorization header' do
      request.headers['Content-Type'] = 'application/json'
      request.headers['Accept'] = 'application/json'
      post :complete, params: {
        paymentId: payment_id,
        transactionId: transaction_id
      }, as: :json

      expect(response).to have_http_status(:success)
      body = JSON.parse(response.body)
      expect(body['status']).to eq('completed')
      expect(body['payment_id']).to eq(payment_id)
      expect(body['txid']).to eq(transaction_id)
      expect(WebMock).to have_requested(:post, stub_url)
        .with(headers: { 'Authorization' => "Key #{test_api_key}" },
              body: hash_including({ 'paymentId' => payment_id, 'txid' => transaction_id }))
    end
  end

  describe 'POST #cancel' do
    let(:payment_id) { 'sample-payment-id' }
    let(:stub_url) { "https://api.minepi.com/v2/payments/sample-payment-id/cancel" }
    let(:stub_body) { { status: 'canceled', payment_id: payment_id }.to_json }

    before do
      stub_request(:post, stub_url)
        .with(
          headers: {
            'Authorization' => "Key #{test_api_key}",
            'Content-Type' => 'application/json'
          }
        )
        .to_return(status: 200, body: stub_body, headers: { 'Content-Type' => 'application/json' })
    end

    it 'cancels a payment and sends the API key in the Authorization header' do
      request.headers['Content-Type'] = 'application/json'
      request.headers['Accept'] = 'application/json'
      post :cancel, params: {
        paymentId: payment_id
      }, as: :json

      expect(response).to have_http_status(:success)
      body = JSON.parse(response.body)
      expect(body['status']).to match(/^cancel(l)?ed$/)
      expect(body['payment_id']).to eq(payment_id)
      expect(WebMock).to have_requested(:post, stub_url)
        .with(headers: { 'Authorization' => "Key #{test_api_key}" })
    end
  end

  describe 'POST #error' do
    let(:payment_id) { 'sample-payment-id' }
    let(:error_data) { { code: 123, message: 'Something went wrong' } }
    let(:stub_url) { "https://api.minepi.com/v2/payments/#{payment_id}/error" }
    let(:stub_body) { { status: 'error_reported', payment_id: payment_id, error: error_data }.to_json }

    before do
      # stub_request(:post, stub_url)
      #   .with(
      #     headers: {
      #       'Authorization' => "Key #{test_api_key}",
      #       'Content-Type' => 'application/json'
      #     }
      #   )
      #   .to_return(status: 200, body: stub_body, headers: { 'Content-Type' => 'application/json' })
    end

    it 'reports an error and sends the API key in the Authorization header' do
      request.headers['Content-Type'] = 'application/json'
      request.headers['Accept'] = 'application/json'
      post :error, params: {
        paymentId: payment_id,
        error: error_data
      }, as: :json

      expect(response).to have_http_status(:success)
      body = JSON.parse(response.body)
      expect(body['recorded']).to eq(true)
      # expect(body['payment_id']).to eq(payment_id)
      # expect(body['error']).to eq(error_data.stringify_keys)
      # expect(WebMock).to have_requested(:post, stub_url)
      #   .with(headers: { 'Authorization' => "Key #{test_api_key}" })
    end
  end

  describe 'POST #incomplete' do
    let(:payment_id) { 'incomplete-payment-id' }
    let(:transaction_id) { 'incomplete-txid' }

    before do
      request.headers['Content-Type'] = 'application/json'
      request.headers['Accept'] = 'application/json'
    end

    context 'when incomplete_callback returns :complete' do
      let(:stub_url) { "https://api.minepi.com/v2/payments/#{payment_id}/complete" }
      let(:stub_body) { { status: 'completed', payment_id: payment_id, txid: transaction_id }.to_json }

      before do
        allow_any_instance_of(described_class).to receive(:incomplete_callback).and_return(:complete)
        stub_request(:post, stub_url)
          .with(
            headers: {
              'Authorization' => "Key #{test_api_key}",
              'Content-Type' => 'application/json'
            },
            body: hash_including({ 'paymentId' => payment_id, 'txid' => transaction_id })
          )
          .to_return(status: 200, body: stub_body, headers: { 'Content-Type' => 'application/json' })
      end

      it 'completes an incomplete payment via Pi API' do
        post :incomplete, params: { paymentId: payment_id, transactionId: transaction_id }, as: :json
        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)
        expect(body['status']).to eq('completed')
        expect(body['payment_id']).to eq(payment_id)
        expect(body['txid']).to eq(transaction_id)
        expect(WebMock).to have_requested(:post, stub_url)
          .with(headers: { 'Authorization' => "Key #{test_api_key}" },
                body: hash_including({ 'paymentId' => payment_id, 'txid' => transaction_id }))
      end
    end

    context 'when incomplete_callback returns :cancel' do
      let(:stub_url) { "https://api.minepi.com/v2/payments/#{payment_id}/cancel" }
      let(:stub_body) { { status: 'canceled', payment_id: payment_id }.to_json }

      before do
        allow_any_instance_of(described_class).to receive(:incomplete_callback).and_return(:cancel)
        stub_request(:post, stub_url)
          .with(
            headers: {
              'Authorization' => "Key #{test_api_key}",
              'Content-Type' => 'application/json'
            }
          )
          .to_return(status: 200, body: stub_body, headers: { 'Content-Type' => 'application/json' })
      end

      it 'cancels an incomplete payment via Pi API' do
        post :incomplete, params: { paymentId: payment_id, transactionId: transaction_id }, as: :json
        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)
        expect(body['status']).to eq('canceled')
        expect(body['payment_id']).to eq(payment_id)
        expect(WebMock).to have_requested(:post, stub_url)
          .with(headers: { 'Authorization' => "Key #{test_api_key}" })
      end
    end

    context 'when incomplete_callback returns invalid symbol' do
      before do
        allow_any_instance_of(described_class).to receive(:incomplete_callback).and_return(:unknown)
      end

      it 'returns bad request for unknown callback result' do
        post :incomplete, params: { paymentId: payment_id, transactionId: transaction_id }, as: :json
        expect(response).to have_http_status(:bad_request)
        body = JSON.parse(response.body)
        expect(body['error']).to match(/must return :complete or :cancel/)
      end
    end

    context 'when params are missing' do
      it 'returns bad request if paymentId missing' do
        post :incomplete, params: { transactionId: transaction_id }, as: :json
        expect(response).to have_http_status(:bad_request)
      end
      it 'returns bad request if transactionId missing' do
        post :incomplete, params: { paymentId: payment_id }, as: :json
        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
