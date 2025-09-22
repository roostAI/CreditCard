Feature: Credit Card Collection Process

Background: 
  Given the API base URL 'https://api.example.com'
  And the authorization header is set
  And the content type is 'application/json'

# Credit Card Due Reminder
Scenario: Send credit card due reminder
  Given a cardholder has an active credit card account
  And the cardholder's payment due date is approaching
  When the credit card due reminder notification process is triggered
  Then a notification should be sent to the cardholder
  And the notification should include the last 4 digits of the credit card number

# Overdue Balance Alert
Scenario: Send overdue balance alert
  Given a cardholder has an active credit card account
  And the cardholder has missed their payment due date
  When the overdue balance alert process is triggered
  Then an alert should be sent to the cardholder
  And the alert should include the last 4 digits of the credit card number

# Collection Notification
Scenario: Send collection notification
  Given a cardholder has an active credit card account
  And the cardholder's account is significantly delinquent
  When the collection notification process is triggered
  Then a collection notification should be sent to the cardholder
  And the notification should include the last 4 digits of the credit card number

# Payment Plan Proposal
Scenario: Send payment plan proposal
  Given a cardholder has an active credit card account
  And the cardholder has an overdue balance and is unable to pay the full amount
  When the payment plan proposal process is triggered
  Then a payment plan proposal should be sent to the cardholder
  And the proposal should include the last 4 digits of the credit card number

# Collection Agency Involvement
Scenario: Involve collection agency
  Given a cardholder has an active credit card account
  And the cardholder has failed to respond to previous notifications and reminders
  When the collection agency involvement process is triggered
  Then the collection agency should be provided with the account information
  And the account information should include the last 4 digits of the credit card number

# Legal Action Initiation
Scenario: Initiate legal action
  Given a cardholder has an active credit card account
  And the cardholder has defaulted on payments or is in an extreme case of non-payment
  When the legal action initiation process is triggered
  Then legal documentation should be generated
  And the legal documentation should include the last 4 digits of the credit card number

# Data Privacy and Security
Scenario: Verify data privacy and security
  Given a cardholder has an active credit card account
  When the collection process is triggered for the account
  Then the full credit card number should never be exposed in plain text
  And only the last 4 digits of the credit card number should be included for identification purposes

# Compliance with Regulations
Scenario: Verify compliance with regulations
  Given a list of relevant regulations and industry standards
  When the collection process is triggered for any account
  Then the system should comply with all relevant regulations and industry standards
  And any instances of non-compliance should be documented and addressed

# Scalability and Performance
Scenario: Verify scalability and performance
  Given a performance testing environment
  And expected load and usage patterns
  When high volumes of credit card accounts and collection processes are simulated
  Then the system should handle the load without performance degradation
  And any performance issues should be identified and addressed

# Auditability and Traceability
Scenario: Verify auditability and traceability
  Given access to the system's logging and auditing mechanisms
  When the collection process is triggered for any account
  Then all collection-related activities and communications should be properly logged
  And the audit logs should be accessible for auditing and reporting purposes
