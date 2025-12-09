# Pinetwork Stimulus Controller

## Overview
This Stimulus controller, named `pinetwork`, provides integration with
the Pi Network JavaScript SDK for Rails apps using the engine.

## Targets
No targets

## Path variablization
- The /payment/.. paths should be variablized in a way that can be changed by the app using the engine
- Default to pi_payment

## Connect
- The controller automatically calls `Pi.init({ version: "2.0", sandbox: true })` if the Pi SDK is available on the window. This initializes the Pi SDK in sandbox mode for development/testing.
- If the Pi SDK is not yet loaded or `Pi.init` is not available, it logs a warning to the console and discontinues processing.
- It then authenticaetes using payments and username scopes and the onIncompletePaymentFound method
-- If successful, it saves the accessToken and user information for later use also calls onConnetion()
-- If unsuccessful, it logs the error
- Provide a stub for onConnection in case child class doew not overload

## onIncompletePaymentFound
- It should log that an incompolete payment was found
- It recieves a PaymentDTO
- It takes the indentifier and transaction id form the PaymentDTO and POST it to the app server /payment/complete as JSON along with a debug field set to 'cancel'

## onReadyForServerApproval
- Takes a single argument, payment id, logs an error and returns if missing
- POST the payment id and the current accessToken saved from initialization to /payment/approve

## onReadyForServerCompletion
- Takes a payment id and transaction id, both must be present to ontinue (log error if so)
- POST the payment id, transaction id, and debug of 'complete' to /payment/complete

## onCancel
- Takes a payment id, logs an error and returns if missing
- POST the payment id and debug set to 'cancel' to /payment/complete

## onError
- Takes an error object and a paymentDTO
- Log the error and payment id
- If there there is no payment id or paymentDTO, log it and return
- POST the paymentDTO, the payment id, error and debug field set to "error" to /payment/error

## onIncompletePaymentFound
- Takes a paymentDTO
- If there there is no payment id or paymentDTO, log it and return
- POST the payment id and transaction id to /payment/complete

## createPayment
- Receives a paymentData object containing ammount: number, memo: string, and metedata: dict
- All fields must be set and metadata not empty
- It should log an error if not connected to the Pi Server and do nothing
- It will call createPayment from Pi using the payment data and a of callbacks
-- onReadyForServerApproval
-- onReadyForServerCompletion
-- onCancel
-- onError
-- onIncompletePaymentFound

## Usage Example
```html
<button data-controller="pinetwork" data-pinetwork-target="paymentButton">
  Make Payment
</button>
```

When the page loads, Pi Network SDK is initialized and the button is available as a target for further actions.

PI Platform SDK documentation can be found https://github.com/pi-apps/pi-platform-docs/blob/master/SDK_reference.md
