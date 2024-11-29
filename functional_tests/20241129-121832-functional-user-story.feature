Feature: Credit Card Notification System
  Scenario: Credit Card Due Reminder
    Given the API base URL 'http://localhost:3000' and the due date is in 5 days
    When I send a POST request to '/credit-card-due-reminder' with credit card number '1234567812345678'
    Then the response status should be 200
    And the response should contain 'An automated notification is sent'
    And the response should include the last 4 digits '5678'

  Scenario: Overdue Balance Alert
    Given the API base URL 'http://localhost:3000' and the due date has passed
    When I send a POST request to '/overdue-balance-alert' with credit card number '1234567812345678'
    Then the response status should be 200
    And the response should contain 'An alert is sent'
    And the response should include the last 4 digits '5678'

  Scenario: Collection Notification
    Given the API base URL 'http://localhost:3000' and the account is significantly delinquent
    When I send a POST request to '/collection-notification' with credit card number '1234567812345678'
    Then the response status should be 200
    And the response should contain 'A collection notification is sent'
    And the response should include the last 4 digits '5678'

  Scenario: Payment Plan Proposal
    Given the API base URL 'http://localhost:3000' and the cardholder is unable to pay full overdue balance
    When I send a POST request to '/payment-plan-proposal' with credit card number '1234567812345678'
    Then the response status should be 200
    And the response should contain 'A payment plan proposal is offered'
    And the response should include the last 4 digits '5678'

  Scenario: Collection Agency Involvement
    Given the API base URL 'http://localhost:3000' and the cardholder fails to respond to notifications and reminders
    When I send a POST request to '/collection-agency-involvement' with credit card number '1234567812345678'
    Then the response status should be 200
    And the response should contain 'A collection agency is involved'
    And the response should include the last 4 digits '5678'

  Scenario: Legal Action Initiation
    Given the API base URL 'http://localhost:3000' and there are extreme cases of non-payment or default
    When I send a POST request to '/legal-action-initiation' with credit card number '1234567812345678'
    Then the response status should be 200
    And the response should contain 'Legal action is initiated'
    And the response should include the last 4 digits '5678'

  Scenario: Performance
    Given the API base URL 'http://localhost:3000' and there are 10000 cardholders
    When I send a GET request to '/performance'
    Then the response status should be 200
    And the response should contain 'All notifications are sent without system failure'

  Scenario: Security
    Given the API base URL 'http://localhost:3000' and the full credit card number is '1234567812345678'
    When I send a GET request to '/security'
    Then the response status should be 200
    And the response should contain 'Only the last 4 digits (5678) are included in the communication or documentation'
    And the response should not contain the full credit card number in plain text

  Scenario: Usability
    Given the API base URL 'http://localhost:3000'
    When I send a GET request to '/usability'
    Then the response status should be 200
    And the response should contain 'All communications are clear and understandable'

  Scenario: Compatibility
    Given the API base URL 'http://localhost:3000'
    When I send a GET request to '/compatibility'
    Then the response status should be 200
    And the response should contain 'Notifications are correctly displayed'

  Scenario: Reliability
    Given the API base URL 'http://localhost:3000' and the due dates and overdue dates
    When I send a GET request to '/reliability'
    Then the response status should be 200
    And the response should contain 'Notifications are sent on time consistently'
