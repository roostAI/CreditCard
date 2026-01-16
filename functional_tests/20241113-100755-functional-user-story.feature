Feature: Credit Card Due Reminder API
  Scenario: Sending automated notification to cardholder
    Given the API endpoint '/credit_card_due_reminder'
    When I send a POST request with 'due_date' and 'credit_card_number'
    Then the response status should be 200
    And the response should contain 'Automated notification sent to cardholder'
    And the response should contain last 4 digits of the 'credit_card_number'

Feature: Overdue Balance Alert API
  Scenario: Sending alert to cardholder for missed payment
    Given the API endpoint '/overdue_balance_alert'
    When I send a POST request with 'missed_due_date' and 'credit_card_number'
    Then the response status should be 200
    And the response should contain 'Alert sent to cardholder'
    And the response should contain last 4 digits of the 'credit_card_number'

Feature: Collection Notification API
  Scenario: Sending collection notification to delinquent account
    Given the API endpoint '/collection_notification'
    When I send a POST request with 'delinquent_account' and 'credit_card_number'
    Then the response status should be 200
    And the response should contain 'Collection notification sent to cardholder'
    And the response should contain last 4 digits of the 'credit_card_number'

Feature: Payment Plan Proposal API
  Scenario: Sending payment plan proposal to cardholder
    Given the API endpoint '/payment_plan_proposal'
    When I send a POST request with 'unable_to_pay' and 'credit_card_number'
    Then the response status should be 200
    And the response should contain 'Payment plan proposal offered to cardholder'
    And the response should contain last 4 digits of the 'credit_card_number'

Feature: Collection Agency Involvement API
  Scenario: Involving collection agency for non-responsive cardholder
    Given the API endpoint '/collection_agency_involvement'
    When I send a POST request with 'non_responsive' and 'credit_card_number'
    Then the response status should be 200
    And the response should contain 'Collection agency is involved'
    And the response should contain last 4 digits of the 'credit_card_number'

Feature: Legal Action Initiation API
  Scenario: Initiating legal action against cardholder
    Given the API endpoint '/legal_action_initiation'
    When I send a POST request with 'non_payment' and 'credit_card_number'
    Then the response status should be 200
    And the response should contain 'Legal action initiated'
    And the response should contain last 4 digits of the 'credit_card_number'

Feature: Security API
  Scenario: Ensuring only last 4 digits of credit card number are included in communication
    Given the API endpoint '/security'
    When I send a POST request with 'communication' and 'credit_card_number'
    Then the response status should be 200
    And the response should not contain full 'credit_card_number'

Feature: Performance API
  Scenario: Testing system performance under peak load conditions
    Given the API endpoint '/performance'
    When I send a POST request with 'peak_load_conditions'
    Then the response status should be 200
    And the response time should be within acceptable limits

Feature: Usability API
  Scenario: Ensuring notifications and alerts are user-friendly
    Given the API endpoint '/usability'
    When I send a POST request with 'notification'
    Then the response status should be 200
    And the response should contain 'user-friendly'

Feature: Reliability API
  Scenario: Ensuring system can recover from failures and maintain logs
    Given the API endpoint '/reliability'
    When I send a POST request with 'failure_scenario'
    Then the response status should be 200
    And the response should contain 'recover from failure'
    And the system should maintain a log of all 'notifications'
