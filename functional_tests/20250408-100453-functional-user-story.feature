Feature: Credit Card Due Reminder API
  Scenario: Send due reminder
    Given the API base URL 'http://localhost:3000'
    When I send a POST request to '/due-reminder' with due date and last 4 digits of credit card number
    Then the response status should be 200
    And the response should contain 'Automated notification sent'

  Scenario: Test with due date being the current date
    Given the API base URL 'http://localhost:3000'
    When I send a POST request to '/due-reminder' with due date as current date and last 4 digits of credit card number
    Then the response status should be 200
    And the response should contain 'Automated notification sent'

Feature: Overdue Balance Alert API
  Scenario: Send overdue balance alert
    Given the API base URL 'http://localhost:3000'
    When I send a POST request to '/overdue-alert' with missed due date, overdue balance and last 4 digits of credit card number
    Then the response status should be 200
    And the response should contain 'Alert sent'

  Scenario: Test with overdue balance being zero
    Given the API base URL 'http://localhost:3000'
    When I send a POST request to '/overdue-alert' with missed due date, overdue balance as zero and last 4 digits of credit card number
    Then the response status should be 200
    And the response should contain 'No overdue balance'

Feature: Collection Notification API
  Scenario: Send collection notification
    Given the API base URL 'http://localhost:3000'
    When I send a POST request to '/collection-notification' with delinquent account status, amount owed, additional charges and last 4 digits of credit card number
    Then the response status should be 200
    And the response should contain 'Collection notification sent'

  Scenario: Test with amount owed being zero
    Given the API base URL 'http://localhost:3000'
    When I send a POST request to '/collection-notification' with delinquent account status, amount owed as zero, additional charges and last 4 digits of credit card number
    Then the response status should be 200
    And the response should contain 'No amount owed'

Feature: Payment Plan Proposal API
  Scenario: Send payment plan proposal
    Given the API base URL 'http://localhost:3000'
    When I send a POST request to '/payment-plan-proposal' with inability to pay full overdue balance and last 4 digits of credit card number
    Then the response status should be 200
    And the response should contain 'Payment plan proposal sent'

  Scenario: Test with full overdue balance being payable at once
    Given the API base URL 'http://localhost:3000'
    When I send a POST request to '/payment-plan-proposal' with full overdue balance being payable at once and last 4 digits of credit card number
    Then the response status should be 200
    And the response should contain 'Full balance payable'

Feature: Collection Agency Involvement API
  Scenario: Involve collection agency
    Given the API base URL 'http://localhost:3000'
    When I send a POST request to '/collection-agency' with failure to respond to notifications and reminders and last 4 digits of credit card number
    Then the response status should be 200
    And the response should contain 'Collection agency involved'

  Scenario: Test with cardholder responding to notifications and reminders
    Given the API base URL 'http://localhost:3000'
    When I send a POST request to '/collection-agency' with cardholder responding to notifications and reminders and last 4 digits of credit card number
    Then the response status should be 200
    And the response should contain 'No need for collection agency'

Feature: Legal Action Initiation API
  Scenario: Initiate legal action
    Given the API base URL 'http://localhost:3000'
    When I send a POST request to '/legal-action' with extreme cases of non-payment or default and last 4 digits of credit card number
    Then the response status should be 200
    And the response should contain 'Legal action initiated'

  Scenario: Test with minor cases of non-payment or default
    Given the API base URL 'http://localhost:3000'
    When I send a POST request to '/legal-action' with minor cases of non-payment or default and last 4 digits of credit card number
    Then the response status should be 200
    And the response should contain 'No need for legal action'
