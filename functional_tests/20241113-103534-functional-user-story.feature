Feature: Credit Card Collection Process

  Scenario: Credit Card Due Reminder
    Given the API base URL 'http://localhost:3000'
    When I send a POST request to '/reminders' with the payload '{"due_date": "2022-12-12", "credit_card_number": "1234567812345678"}'
    Then the response status should be 200
    And the response should contain 'Automated notification sent'
    And the response should contain the last 4 digits of the credit card number

  Scenario: Overdue Balance Alert
    Given the API base URL 'http://localhost:3000'
    When I send a POST request to '/alerts' with the payload '{"due_date": "2022-12-12", "payment_date": "2022-12-13", "credit_card_number": "1234567812345678"}'
    Then the response status should be 200
    And the response should contain 'Alert is sent'
    And the response should contain the last 4 digits of the credit card number

  Scenario: Collection Notification
    Given the API base URL 'http://localhost:3000'
    When I send a POST request to '/notifications' with the payload '{"account_status": "delinquent", "credit_card_number": "1234567812345678"}'
    Then the response status should be 200
    And the response should contain 'Collection notification is sent'
    And the response should contain the last 4 digits of the credit card number

  Scenario: Payment Plan Proposal
    Given the API base URL 'http://localhost:3000'
    When I send a POST request to '/payment-plans' with the payload '{"overdue_balance": "5000", "payment_ability": "partial", "credit_card_number": "1234567812345678"}'
    Then the response status should be 200
    And the response should contain 'Payment plan proposal is offered'
    And the response should contain the last 4 digits of the credit card number

  Scenario: Collection Agency Involvement
    Given the API base URL 'http://localhost:3000'
    When I send a POST request to '/collection-agency' with the payload '{"response_status": "no response", "credit_card_number": "1234567812345678"}'
    Then the response status should be 200
    And the response should contain 'Collection agency is involved'
    And the response should contain the last 4 digits of the credit card number

  Scenario: Legal Action Initiation
    Given the API base URL 'http://localhost:3000'
    When I send a POST request to '/legal-action' with the payload '{"payment_status": "default", "credit_card_number": "1234567812345678"}'
    Then the response status should be 200
    And the response should contain 'Legal action is initiated'
    And the response should contain the last 4 digits of the credit card number

  Scenario: Performance Test
    Given the API base URL 'http://localhost:3000'
    When I send a GET request to '/notifications'
    Then the response status should be 200
    And the response time should be less than 500 milliseconds

  Scenario: Security Test
    Given the API base URL 'http://localhost:3000'
    When I send a GET request to '/notifications'
    Then the response should not contain the full credit card number

  Scenario: Usability Test
    Given the API base URL 'http://localhost:3000'
    When I send a GET request to '/notifications'
    Then the response should be clear and understandable

  Scenario: Compatibility Test
    Given the API base URL 'http://localhost:3000'
    And different platforms and devices
    When I send a GET request to '/notifications'
    Then the system should work correctly
