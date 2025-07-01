Feature: Credit Card Management System API Testing

Background:
  Given the API base URL is set as 'http://api.creditcardmanagement.com'
  And the authorization header is set with a valid token
  And the content type is 'application/json'

Scenario: Sending Credit Card Due Reminder
  Given the Credit Card Due Date is '01/12/2022'
  When I send a POST request to '/send-reminder' with the due date in the payload
  Then the response status should be 200
  And the response should confirm that the reminder is scheduled for '30/11/2022'
  And if the due date falls on a holiday, the reminder should still be scheduled correctly

Scenario: Sending Overdue Balance Alert
  Given the current date is '02/12/2022' and the due date was '01/12/2022'
  When I send a POST request to '/send-overdue-alert' with the overdue status in the payload
  Then the response status should be 200
  And the response should confirm that the alert was sent on '02/12/2022'

Scenario: Sending Collection Notification
  Given the account status is significantly delinquent
  When I send a POST request to '/send-collection-notification' with account details in the payload
  Then the response status should be 200
  And the response should include the amount owed and additional charges
  And ensure no notices are sent to accounts just days past due

Scenario: Offering Payment Plan Proposal
  Given the user has informed about inability to pay
  When I send a POST request to '/offer-payment-plan' with user status in the payload
  Then the response status should be 200
  And the response should include a payment plan proposal with reduced interest rates or fees
  And ensure the feature is not triggered for users in good standing or with minor delinquency

Scenario: Involving Collection Agency
  Given the cardholder has failed to respond to previous notifications and reminders
  When I send a POST request to '/involve-collection-agency' with cardholder details in the payload
  Then the response status should be 200
  And the response should confirm collection agency involvement
  And ensure the involvement threshold is accurate

Scenario: Initiating Legal Action
  Given there are extreme cases of non-payment or default
  When I send a POST request to '/initiate-legal-action' with case details in the payload
  Then the response status should be 200
  And the response should confirm the initiation of legal action
  And ensure a rigorous confirmation procedure before initiation

Scenario: Performance Testing for Notification Load
  When I simulate sending notifications to all users
  Then the system should handle the load efficiently
  And the alert system should work swiftly even with thousands of cardholders

Scenario: Usability Testing for Notification Clarity
  When a notification message is sent
  Then the message should be clear and understandable to the cardholders

Scenario: Security Testing for Data Protection
  When interacting with the system
  Then sensitive cardholder data should be protected

Scenario: Compatibility Testing for Device Delivery
  When notifications are sent
  Then they should be effectively delivered across all device types (PCs, mobile phones, tablets)

Scenario: Recovery Testing from System Failures
  When the system experiences crashes or hardware failures
  Then it should recover without losing any critical data

Scenario: Reliability Testing for Continuous Operation
  When the system is in operation for a long period
  Then it should perform its functions continuously without disruption
