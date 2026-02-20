Feature: Credit Card Notification System API Testing

  Scenario: Sending Credit Card Due Reminder Notification
    Given the API base URL 'http://localhost:3000'
    And a cardholder with an upcoming payment due date
    When I send a POST request to '/notifications/due-reminder' with the cardholder's details
    Then the response status should be 200
    And the response should confirm the notification is sent
    And the notification is sent to the cardholder's updated contact information

  Scenario: Sending Overdue Balance Alert
    Given the API base URL 'http://localhost:3000'
    And a cardholder who has missed their payment due date
    When I send a POST request to '/notifications/overdue-alert' with the cardholder's details
    Then the response status should be 200
    And the response should confirm the alert is sent
    And the alert specifies which card's payment is overdue

  Scenario: Sending Collection Notification
    Given the API base URL 'http://localhost:3000'
    And an account that has become significantly delinquent
    When I send a POST request to '/notifications/collection' with the account details
    Then the response status should be 200
    And the response should confirm the collection notification is sent
    And the notification is not sent if the cardholder has initiated a payment plan

  Scenario: Offering Payment Plan Proposal
    Given the API base URL 'http://localhost:3000'
    And a cardholder unable to pay the full overdue balance at once
    When I send a POST request to '/notifications/payment-plan' with the cardholder's details
    Then the response status should be 200
    And the response should offer a payment plan proposal
    And the plan is correctly applied if accepted by the cardholder

  Scenario: Involving Collection Agency
    Given the API base URL 'http://localhost:3000'
    And a cardholder who fails to respond to previous notifications
    When I send a POST request to '/notifications/collection-agency' with the cardholder's details
    Then the response status should be 200
    And the response should confirm the collection agency involvement
    And the cardholder is notified of the involvement before any action is taken

  Scenario: Initiating Legal Action
    Given the API base URL 'http://localhost:3000'
    And extreme cases of non-payment or default
    When I send a POST request to '/notifications/legal-action' with the cardholder's details
    Then the response status should be 200
    And the response should confirm legal action initiation
    And verify all prior notifications have been completed

  Scenario: Performance of Notification System
    Given a trigger event occurs
    When the notification system processes the event
    Then the notification should be sent within 5 minutes

  Scenario: Scalability of Notification System
    Given a large number of notifications to send simultaneously
    When the notification system processes these notifications
    Then the system should handle the load without performance degradation

  Scenario: Security of Sensitive Information
    Given notifications are being sent
    When I review the notification content
    Then the notifications should not expose sensitive information like full card numbers

  Scenario: Usability of Notification Content
    Given a notification is received by a cardholder
    When the cardholder reads the notification
    Then the content should be clear and understandable

  Scenario: Reliability of Notification System
    Given the system is in operation over an extended period
    When the system is tested for reliability
    Then the system should consistently perform its intended functions without failure
