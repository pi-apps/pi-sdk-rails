# frozen_string_literal: true
require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Pinetwork::Rails::UserDTO, type: :model do
  let(:api_response) do
    {
      'uid' => 'p_user_id_123',
      'credentials' => {
        'scopes' => %w[username payments],
        'valid_until' => {
          'timestamp' => 1717979469,
          'iso8601'   => '2024-06-10T17:31:09Z'
        }
      },
      'username' => 'pioneerjoe'
    }
  end

  let(:test_api_config) do
    {
      'api_key'        => 'test-api-key',
      'api_url_base'   => 'https://api.minepi.com',
      'api_version'    => 'v2',
      'api_controller' => 'payments'
    }
  end
  before do
    allow(::Rails.application).to receive(:config_for).and_call_original
    allow(::Rails.application).to receive(:config_for).with(:pinetwork).and_return(test_api_config)
  end

  describe '#initialize and accessors' do
    subject(:dto) { described_class.new(api_response) }

    it 'sets uid' do
      expect(dto.uid).to eq('p_user_id_123')
    end
    it 'sets credentials' do
      expect(dto.credentials).to be_a(Hash)
      expect(dto.credentials['scopes']).to include('username', 'payments')
    end
    it 'sets username' do
      expect(dto.username).to eq('pioneerjoe')
    end
    it 'returns scope_list' do
      expect(dto.scope_list).to eq(['username', 'payments'])
    end
    it 'returns valid_until_timestamp' do
      expect(dto.valid_until_timestamp).to eq(1717979469)
    end
    it 'returns valid_until_iso8601' do
      expect(dto.valid_until_iso8601).to eq('2024-06-10T17:31:09Z')
    end
    it 'valid_until uses iso8601 if present' do
      dt = dto.valid_until
      expect(dt).to be_a(DateTime)
      expect(dt.rfc3339).to eq('2024-06-10T17:31:09+00:00')
    end
    it 'valid_until falls back to timestamp if iso8601 missing' do
      noiso = api_response.dup
      noiso['credentials']['valid_until'].delete('iso8601')
      dto2 = described_class.new(noiso)
      dt = dto2.valid_until
      expect(dt).to be_a(DateTime)
      # Should match unix timestamp
      expect(dt.to_time.to_i).to eq(1717979469)
    end
    it 'valid_until is nil if no valid date info' do
      minimal = described_class.new({})
      expect(minimal.valid_until).to be_nil
    end
  end

  describe '.get' do
    let(:token) { 'good-token' }
    let(:uri) { URI('https://api.minepi.com/v2/me') }
    let(:success_body) { api_response.to_json }
    let(:fail_body) { { 'error' => 'bad token' }.to_json }

    before do
      WebMock.disable_net_connect!(allow_localhost: true)
      allow(described_class).to receive(:warn)
    end

    it 'returns a UserDTO when Pi API returns 200' do
      stub_request(:get, uri.to_s)
        .with(headers: { 'Authorization' => "Bearer #{token}" })
        .to_return(status: 200, body: success_body, headers: { 'Content-Type' => 'application/json' })
      u = described_class.get(token)
      expect(u).to be_a(described_class)
      expect(u.uid).to eq('p_user_id_123')
    end
    it 'returns nil for bad token (401/403)' do
      stub_request(:get, uri.to_s)
        .with(headers: { 'Authorization' => "Bearer #{token}" })
        .to_return(status: 403, body: fail_body)
      expect(described_class.get(token)).to be_nil
    end
    it 'returns nil for network error or exception' do
      stub_request(:get, uri.to_s).to_timeout
      expect(described_class.get(token)).to be_nil
    end
    it 'returns nil on invalid JSON' do
      stub_request(:get, uri.to_s)
        .with(headers: { 'Authorization' => "Bearer #{token}" })
        .to_return(status: 200, body: 'not json', headers: { 'Content-Type' => 'application/json' })
      expect(described_class.get(token)).to be_nil
    end
  end
end
