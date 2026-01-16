Feature: Credit Card Due Reminder API
  Scenario: Verify due date reminder notification
    Given the API base URL 'http://localhost:3000/notification'
    When I send a POST request to '/due-reminder' with cardholder details and due date
    Then the response status should be 200
    And the response should contain 'Notification is sent'
  
  Scenario: Verify credit card identification in notification
    Given the API base URL 'http://localhost:3000/notification'
    When I send a GET request to '/due-reminder'
    Then the response status should be 200
    And the response should contain the last 4 digits of the credit card number

Feature: Overdue Balance Alert API
  Scenario: Verify overdue balance alert
    Given the API base URL 'http://localhost:3000/alert'
    When I send a POST request to '/overdue-alert' with cardholder details and overdue date
    Then the response status should be 200
    And the response should contain 'Alert is sent'

  Scenario: Verify credit card identification in alert
    Given the API base URL 'http://localhost:3000/alert'
    When I send a GET request to '/overdue-alert'
    Then the response status should be 200
    And the response should contain the last 4 digits of the credit card number

Feature: Collection Notification API
  Scenario: Verify collection notification
    Given the API base URL 'http://localhost:3000/notification'
    When I send a POST request to '/collection-notification' with cardholder details and delinquency status
    Then the response status should be 200
    And the response should contain 'Collection notification is sent'

  Scenario: Verify credit card identification in collection notification
    Given the API base URL 'http://localhost:3000/notification'
    When I send a GET request to '/collection-notification'
    Then the response status should be 200
    And the response should contain the last 4 digits of the credit card number

Feature: Payment Plan Proposal API
  Scenario: Verify payment plan proposal
    Given the API base URL 'http://localhost:3000/proposal'
    When I send a POST request to '/payment-plan' with cardholder details and overdue balance
    Then the response status should be 200
    And the response should contain 'Payment plan proposal is offered'

  Scenario: Verify credit card identification in payment plan proposal
    Given the API base URL 'http://localhost:3000/proposal'
    When I send a GET request to '/payment-plan'
    Then the response status should be 200
    And the response should contain the last 4 digits of the credit card number

Feature: Collection Agency Involvement API
  Scenario: Verify collection agency involvement
    Given the API base URL 'http://localhost:3000/agency'
    When I send a POST request to '/collection-agency' with cardholder details and unresponsiveness status
    Then the response status should be 200
    And the response should contain 'Collection agency is involved'

  Scenario: Verify credit card identification in collection agency involvement
    Given the API base URL 'http://localhost:3000/agency'
    When I send a GET request to '/collection-agency'
    Then the response status should be 200
    And the response should contain the last 4 digits of the credit card number

Feature: Legal Action Initiation API
  Scenario: Verify legal action initiation
    Given the API base URL 'http://localhost:3000/legal'
    When I send a POST request to '/legal-action' with cardholder details and default status
    Then the response status should be 200
    And the response should contain 'Legal action initiated'

  Scenario: Verify credit card identification in legal action
    Given the API base URL 'http://localhost:3000/legal'
    When I send a GET request to '/legal-action'
    Then the response status should be 200
    And the response should contain the last 4 digits of the credit card number

Feature: Security API
  Scenario: Verify credit card number security in communications
    Given the API base URL 'http://localhost:3000/security'
    When I send a GET request to '/credit-card-number'
    Then the response status should be 200
    And the response should contain only the last 4 digits of the credit card number

Feature: Performance API
  Scenario: Verify system performance under load
    Given the API base URL 'http://localhost:3000/performance'
    When I send a POST request to '/load-test' with multiple notifications, alerts, and proposals
    Then the response status should be 200
    And the response should contain 'System is able to handle the load'

Feature: Usability API
  Scenario: Verify usability of notifications
    Given the API base URL 'http://localhost:3000/usability'
    When I send a GET request to '/notifications'
    Then the response status should be 200
    And the response should be easy to understand and actionable

Feature: Reliability API
  Scenario: Verify system reliability
    Given the API base URL 'http://localhost:3000/reliability'
    When I send a GET request to '/notifications'
    Then the response status should be 200
    And the response should contain 'Notifications, alerts, and proposals sent reliably and on time'
