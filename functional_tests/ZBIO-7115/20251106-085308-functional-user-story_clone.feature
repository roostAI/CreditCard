Feature: Credit Card Collection Process
  As a card issuer, I want to ensure proper communication and handling of delinquent accounts while maintaining data privacy and security standards.

Background:
  Given the API base URL 'https://api.cardissuer.com'
  And the authorization header is set
  And the content type is 'application/json'

Scenario: Credit Card Due Reminder
  Given a valid credit card account exists in the system
  And the credit card payment due date is approaching
  When the credit card due reminder notification process is triggered
  Then a notification should be sent to the cardholder
  And the notification should include the last 4 digits of the credit card number

Scenario: Overdue Balance Alert
  Given a valid credit card account exists in the system
  And the credit card payment due date has passed
  And the balance is overdue
  When the overdue balance alert process is triggered
  Then an alert should be sent to the cardholder
  And the alert should include the last 4 digits of the credit card number
  And the alert should mention potential consequences of non-payment

Scenario: Collection Notification
  Given a valid credit card account exists in the system
  And the account is significantly delinquent
  And the overdue balance is high
  When the collection notification process is triggered
  Then a formal collection notification should be sent to the cardholder
  And the notification should include the last 4 digits of the credit card number
  And the notification should detail the amount owed and additional charges

Scenario: Payment Plan Proposal
  Given a valid credit card account exists in the system
  And the account has an overdue balance
  And the cardholder is unable to pay the full overdue balance at once
  When the payment plan proposal process is triggered
  Then a payment plan proposal should be sent to the cardholder
  And the proposal should include the last 4 digits of the credit card number
  And the proposal should outline a structured repayment schedule with reduced interest rates or fees

Scenario: Collection Agency Involvement
  Given a valid credit card account exists in the system
  And the account is significantly delinquent
  And previous collection efforts have failed
  When the collection agency involvement process is triggered
  Then the collection agency should be provided with the last 4 digits of the credit card number

Scenario: Legal Action Initiation
  Given a valid credit card account exists in the system
  And the account is in extreme delinquency
  And legal action is warranted
  When the legal action initiation process is triggered
  Then any legal documentation should include the last 4 digits of the credit card number

Scenario: Data Privacy and Security
  Given a valid credit card account exists in the system
  And the system is configured to handle sensitive data securely
  When various collection processes are triggered
  Then all communications and documentation should only include the last 4 digits of the credit card number
  And the full credit card number should never be shared or displayed in plain text
