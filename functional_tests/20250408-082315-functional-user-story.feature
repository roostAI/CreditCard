Feature: Credit Card Collection Process API

  Scenario: Credit Card Due Reminder
    Given the API endpoint '/credit-card-due-reminder'
    When I send a POST request with due date and last 4 digits of credit card number
    Then the response status should be 200
    And the response should contain 'Automated notification sent to cardholder with due date and last 4 digits of credit card number'
    But when I send a POST request with due date set to today, tomorrow, and a past date
    Then the response status should be 400

  Scenario: Overdue Balance Alert
    Given the API endpoint '/overdue-balance-alert'
    When I send a POST request with missed payment due date and last 4 digits of credit card number
    Then the response status should be 200
    And the response should contain 'Alert sent to cardholder with overdue balance details and last 4 digits of credit card number'
    But when I send a POST request with due date set to today, tomorrow, and a past date
    Then the response status should be 400

  Scenario: Collection Notification
    Given the API endpoint '/collection-notification'
    When I send a POST request with delinquent account and last 4 digits of credit card number
    Then the response status should be 200
    And the response should contain 'Collection notification sent to cardholder with amount owed, additional charges, and last 4 digits of credit card number'
    But when I send a POST request with different amounts owed and additional charges
    Then the response status should be 400

  Scenario: Payment Plan Proposal
    Given the API endpoint '/payment-plan-proposal'
    When I send a POST request with overdue balance and last 4 digits of credit card number
    Then the response status should be 200
    And the response should contain 'Payment plan proposal sent to cardholder with repayment schedule, reduced interest rates or fees, and last 4 digits of credit card number'
    But when I send a POST request with different overdue balances and repayment schedules
    Then the response status should be 400

  Scenario: Collection Agency Involvement
    Given the API endpoint '/collection-agency-involvement'
    When I send a POST request with non-responsive cardholder and last 4 digits of credit card number
    Then the response status should be 200
    And the response should contain 'Collection agency receives last 4 digits of credit card number'
    But when I send a POST request with different collection agencies
    Then the response status should be 400

  Scenario: Legal Action Initiation
    Given the API endpoint '/legal-action-initiation'
    When I send a POST request with non-payment or default and last 4 digits of credit card number
    Then the response status should be 200
    And the response should contain 'Legal documentation includes last 4 digits of credit card number'
    But when I send a POST request with different legal actions
    Then the response status should be 400

  Scenario: Security
    Given the API endpoint '/security'
    When I send a POST request with any communication or documentation related to the collection process
    Then the response status should be 200
    And the response should contain 'Only the last 4 digits of the credit card number are included'
    But when I send a POST request with full credit card number
    Then the response status should be 400

  Scenario: Performance
    Given the API endpoint '/performance'
    When I send a POST request with high volume of notifications or alerts
    Then the response status should be 200
    And the response should contain 'System should handle high volume without performance degradation'
    But when I send a POST request with varying volumes of notifications or alerts
    Then the response status should be 400

  Scenario: Usability
    Given the API endpoint '/usability'
    When I send a POST request with any communication or documentation related to the collection process
    Then the response status should be 200
    And the response should contain 'Information should be clear, concise, and easy to understand'
    But when I send a POST request with different levels of complexity in the information
    Then the response status should be 400

  Scenario: Reliability
    Given the API endpoint '/reliability'
    When I send a POST request with continuous operation of the system
    Then the response status should be 200
    And the response should contain 'System should operate without failure under specified conditions'
    But when I send a POST request with different operating conditions
    Then the response status should be 400

  Scenario: Scalability
    Given the API endpoint '/scalability'
    When I send a POST request with increase in the number of cardholders
    Then the response status should be 200
    And the response should contain 'System should be able to handle increased load'
    But when I send a POST request with varying numbers of cardholders
    Then the response status should be 400
