Feature: Credit Card Collection Process

Background:
  Given the API base URL 'https://api.mybank.com'
  And the authorization header is set with a valid API key
  And the content type is 'application/json'

Scenario: Send Credit Card Due Reminder
  Given a cardholder with an upcoming credit card payment due date
  When the credit card due reminder process is triggered
  Then a notification should be sent to the cardholder
  And the notification should include the last 4 digits of the credit card number

Scenario: Send Overdue Balance Alert
  Given a cardholder has missed their credit card payment due date
  When the overdue balance alert process is triggered
  Then an alert should be sent to the cardholder
  And the alert should include the last 4 digits of the credit card number
  And the alert should mention the potential consequences of non-payment

Scenario: Send Collection Notification for Delinquent Account
  Given a cardholder's account is significantly delinquent
  When the collection notification process is triggered
  Then a formal collection notification should be sent to the cardholder
  And the notification should include the amount owed and additional charges
  And the notification should include the last 4 digits of the credit card number

Scenario: Propose Payment Plan for Partial Payment
  Given a cardholder is unable to pay the full overdue balance
  When the payment plan proposal process is triggered
  Then a payment plan proposal should be sent to the cardholder
  And the proposal should outline a structured repayment schedule
  And the proposal should include reduced interest rates or fees
  And the proposal should include the last 4 digits of the credit card number

Scenario: Involve Collection Agency for Non-Responsive Cardholder
  Given a cardholder has failed to respond to previous notifications and reminders
  When the collection agency involvement process is triggered
  Then the collection agency should be provided with the account information
  And the account information should include the last 4 digits of the credit card number

Scenario: Initiate Legal Action for Non-Payment or Default
  Given a cardholder is in an extreme case of non-payment or default
  When the legal action initiation process is triggered
  Then legal documentation should be generated
  And the legal documentation should include the last 4 digits of the credit card number

Scenario: Verify Data Privacy and Security
  Given a cardholder's account information
  When any communication or documentation is generated
  Then the full credit card number should never be exposed in plain text
  And only the last 4 digits of the credit card number should be included

Scenario: Ensure Compliance with Regulations
  Given a set of relevant regulations and industry standards
  When the credit card collection processes are executed
  Then the processes should comply with the regulations and standards
  And any instances of non-compliance should be identified and addressed

Scenario: Test System Scalability and Performance
  Given a performance testing environment
  And expected load and usage patterns
  When high volumes of credit card accounts and collection processes are simulated
  Then the system should handle the load without performance degradation
  And system performance metrics should be monitored for any issues

Scenario: Verify Auditability and Traceability
  Given a set of collection-related activities and communications
  When the activities and communications are executed
  Then audit logs should be generated for each activity and communication
  And the audit logs should be accessible for auditing and reporting purposes
