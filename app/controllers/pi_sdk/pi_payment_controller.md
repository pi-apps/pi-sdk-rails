# PiPaymentController Actions Specification

This document specifies the expected behavior of the PiPaymentController actions. All actions accept **only JSON requests**.

## Class Variables
= URL_BASE is https://api.minepi.com
- PI_API is v2
- PI_CONTROLLER is payments
PI URLs concatenate the URL_BASE, PI_API, and PI CONTROLLER. It is followed by a payment id, if relevant, and
an action namee. Example: "https://api.minepi.com/v2/payments/#{payment_id}/approve"

## Request Headers
- By default include 'Authorization' =>"Key API_KEY' in all request headers to Pi Services unless otherwise directed
- The API key should be defined in an initializer that is generated as part of the pinetwork:install process
- Access the API_KEY through a function call

## Common To All Actions
- If the payload is unparsable JSON, render an error message with unprocessable entity status
- Skip authenticity verificaion for the actions in this controller

## Endpoints

### POST /pi_payment/approve
- **Description:** Endpoint to approve a payment, typically at the start of transaction validation.
- **Expected input:** JSON payload with transaction details.
-- The payload contains assessToken and paymentId
- **Response:** Returns transaction approval status.
POST an approve action with the payment id to the PI URL.
If the response is valid JSON, render the response as JSON and echo the respose code. Log the approval action.
Otherwise, log the error including the body of the response and it's status code.

### POST /pi_payment/complete
- **Description:** Finalizes a transaction after confirmation from the Pi Network.
- **Expected input:** JSON payload referencing the transaction.
-- The payload consists of accessToken, a payment id, and a transaction id
- **Response:** Confirms transaction was processed and resource granted, if successful.
POST a complete action with the payment id to the PI URL and the transaction id as data
If the response is valid JSON, render the response as JSON and echo the respose code. Log the approval action.
Otherwise, log the error including the body of the response and it's status code.

### POST /pi_payment/cancel
- **Description:** Called when a payment is cancelled by the client or after a timeout.
- **Expected input:** JSON payload referencing the cancellation context.
- **Response:** Returns acknowledgement of cancelled transaction.
POST a cancel action with the payment id to the PI URL
If the response is valid JSON, render the response as JSON and echo the respose code. Log the approval action.
Otherwise, log the error including the body of the response and it's status code.

### POST /pi_payment/error
- **Description:** Reports an error encountered in the Pi payment process.
- **Expected input:** JSON describing the error context.
- **Response:** Logs or records error details for review.
POST a cancel action with the payment id to the PI URL
If the response is valid JSON, render the response as JSON and echo the respose code. Log the approval action.
Otherwise, log the error including the body of the response and it's status code.

### GET /pi_payment/me
- **Description:** Used to fetch information about the requesting user (e.g., session, Pi Network ID).
- **Expected input:** None required, authorization may be needed.
- **Response:** Returns user's current payment session details or relevant info.
Not sure if this is necessary on the server.
Raise an exception if this is actally called.

---

**All endpoints will respond with `406 Not Acceptable` if requests are not of type JSON.**
