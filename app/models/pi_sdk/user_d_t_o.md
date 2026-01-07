A UserDTO from the Pi Network Server is a hash with the following structure
```
{
  uid: string, // An app-specific user identifier
  credentials: {
    scopes: Array<Scope>, // a list of granted scopes
    valid_until: {
      timestamp: number,    // (integer) seconds since Unix epoch, UTC
      iso8601: string      // (string) ISO8601 formatted date/time with timezone Z (always UTC)
    }
  },
  username?: string, // The user's Pi username. Requires the `username` scope.
}
type Scope = "username" | "payments" | "wallet_address";
```

The UserDTO class encapsulates this hash with standard Ruby access methods. All strings should be UTF-8 encoded; timestamps are always UTC.

## API and Error Handling
- The `.get(access_token)` method performs a GET to Pi's `/v2/me` endpoint.
- If the API call fails (HTTP error, invalid token, network error, parsing error): it returns `nil` and **never raises an exception** for normal user code.
- All transient errors and API errors result in `nil`; if debug/tracing is needed, see warnings to stderr (suppressible in tests via RSpec, see model spec).

## Preferred Date Parsing
- When calling `valid_until`, the preferred value is `iso8601` (parsed via `DateTime.iso8601`).
- If `iso8601` is missing or empty, will fall back to parsing `timestamp` as UTC (`DateTime.strptime(ts, '%s')`).
- If both are absent or invalid, `valid_until` returns nil.
- All date/times are assumed UTC; if the API stops supplying Z timezone in iso8601, verify any parsing changes.

## DTO Attributes
- `uid: String` (always present)
- `credentials: Hash` (present, may contain empty scopes or valid_until)
- `username: String (optional)`
- `scope_list: Array<String>` (from credentials)
- `valid_until_iso8601: String|nil`
- `valid_until_timestamp: Integer|nil`
- `valid_until: DateTime|nil` (preferred API output: use this in most code)

Example:
```
{
  "uid": "pi-network_uid_45",
  "credentials": {
    "scopes": ["username", "payments"],
    "valid_until": {
      "timestamp": 1717979469,
      "iso8601": "2024-06-10T17:31:09Z"
    }
  },
  "username": "myuser"
}
```

## Testing/Updates
- Canonical spec for test data is found at `spec/models/pi_sdk/rails/user_d_t_o_spec.rb`.
- If the Pi API changes structure or adds keys, update this file and spec accordingly.

## Output and Test Practices
- All warnings printed to stderr during .get internal errors can and should be suppressed in test suites using RSpec's `allow(described_class).to receive(:warn)` or similar block.

## Usage Example (IRB/Console)
```ruby
# Fetching
user = PiSdk::UserDTO.get("API_TOKEN_HERE")
if user
  puts user.uid, user.username, user.scope_list
  puts "Token valid until: #{user.valid_until}"
else
  puts "Token not valid or API error"
end
```

## Note
- This markdown file serves as the canonical developer spec for UserDTO value objects in pi-sdk-rails. Developers should refer here when updating DTO logic or specs.
