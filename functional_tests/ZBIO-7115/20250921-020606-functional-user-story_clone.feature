Feature: Credit Card Notification Scenarios

Background:
  Given the API base URL 'https://api.example.com'
  And the authorization header is set
  And the content type is 'application/json'

Scenario: Credit Card Due Reminder
  Given a cardholder with an upcoming credit card payment due date
  When the notification system triggers the due reminder
  Then a notification should be sent to the cardholder
  And the notification should include the last 4 digits of the credit card number
  And the response status should be 200

Scenario: Overdue Balance Alert
  Given a cardholder with an overdue credit card balance
  When the notification system triggers the overdue balance alert
  Then a notification should be sent to the cardholder
  And the notification should include the last 4 digits of the credit card number
  And the notification should mention the overdue balance and potential consequences
  And the response status should be 200

Scenario: Collection Notification
  Given a delinquent cardholder account with an outstanding balance
  When the notification system triggers the collection notification
  Then a formal collection notification should be sent to the cardholder
  And the notification should include the last 4 digits of the credit card number
  And the notification should detail the amount owed and any additional charges
  And the response status should be 200

Scenario: Payment Plan Proposal
  Given a cardholder unable to pay the full overdue balance
  When the notification system triggers the payment plan proposal
  Then a proposal for a structured repayment plan should be sent to the cardholder
  And the proposal should include the last 4 digits of the credit card number
  And the proposal should outline reduced interest rates or fees
  And the response status should be 200

Scenario: Collection Agency Involvement
  Given a cardholder who failed to respond to previous notifications
  When the notification system involves a collection agency
  Then the collection agency should be provided with the last 4 digits of the credit card number
  And the response status should be 200

Scenario: Legal Action Initiation
  Given a cardholder in extreme default or non-payment
  When the notification system initiates legal action
  Then any legal documentation should include the last 4 digits of the credit card number
  And the response status should be 200

Scenario: Validate Notification Content
  Given a cardholder with an upcoming credit card payment due date
  When the notification system triggers the due reminder
  Then the notification should not contain the full credit card number
  And the response status should be 200
