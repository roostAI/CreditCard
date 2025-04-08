Feature: Credit Card Due Reminder API
  Scenario: Send credit card due reminder
    Given the API base URL 'http://localhost:3000'
    When I send a POST request to '/credit-card-reminder' with due date and last 4 digits of credit card number
    Then the response status should be 200
    And the response should contain 'Automated notification sent to the cardholder with the due date and last 4 digits of the credit card number'
    But when I send a POST request with due date being the current date
    Then the response status should be 400
    And the response should contain 'Due date cannot be the current date'

Feature: Overdue Balance Alert API
  Scenario: Send overdue balance alert
    Given the API base URL 'http://localhost:3000'
    When I send a POST request to '/overdue-balance-alert' with missed due date, overdue balance, and last 4 digits of credit card number
    Then the response status should be 200
    And the response should contain 'Alert sent to the cardholder with overdue balance, potential consequences, and last 4 digits of the credit card number'
    But when I send a POST request with overdue balance being zero
    Then the response status should be 400
    And the response should contain 'Overdue balance cannot be zero'

Feature: Collection Notification API
  Scenario: Send collection notification
    Given the API base URL 'http://localhost:3000'
    When I send a POST request to '/collection-notification' with delinquent account status, amount owed, additional charges, and last 4 digits of credit card number
    Then the response status should be 200
    And the response should contain 'Collection notification sent to the cardholder with amount owed, additional charges, and last 4 digits of the credit card number'
    But when I send a POST request with amount owed being zero
    Then the response status should be 400
    And the response should contain 'Amount owed cannot be zero'

Feature: Payment Plan Proposal API
  Scenario: Send payment plan proposal
    Given the API base URL 'http://localhost:3000'
    When I send a POST request to '/payment-plan-proposal' with inability to pay full overdue balance, and last 4 digits of credit card number
    Then the response status should be 200
    And the response should contain 'Payment plan proposal sent to the cardholder with repayment schedule, reduced interest rates or fees, and last 4 digits of the credit card number'
    But when I send a POST request with full overdue balance being payable at once
    Then the response status should be 400
    And the response should contain 'Full overdue balance cannot be payable at once'

Feature: Collection Agency Involvement API
  Scenario: Send collection agency involvement notification
    Given the API base URL 'http://localhost:3000'
    When I send a POST request to '/collection-agency-involvement' with failure to respond to notifications and reminders, and last 4 digits of credit card number
    Then the response status should be 200
    And the response should contain 'Collection agency involved with last 4 digits of the credit card number'
    But when I send a POST request with cardholder responding to notifications and reminders
    Then the response status should be 400
    And the response should contain 'Cardholder cannot respond to notifications and reminders'

Feature: Legal Action Initiation API
  Scenario: Send legal action initiation notification
    Given the API base URL 'http://localhost:3000'
    When I send a POST request to '/legal-action-initiation' with extreme cases of non-payment or default, and last 4 digits of credit card number
    Then the response status should be 200
    And the response should contain 'Legal action initiated with legal documentation including last 4 digits of the credit card number'
    But when I send a POST request with minor cases of non-payment or default
    Then the response status should be 400
    And the response should contain 'Minor cases of non-payment or default cannot initiate legal action'

Feature: Security API
  Scenario: Test security
    Given the API base URL 'http://localhost:3000'
    When I send a POST request to '/security' with full credit card number
    Then the response status should be 200
    And the response should contain only the last 4 digits of the credit card number
    But when I send a POST request with the first 4 digits of the credit card number
    Then the response status should be 400
    And the response should contain 'Only the last 4 digits of the credit card number should be displayed'

Feature: Performance API
  Scenario: Test performance
    Given the API base URL 'http://localhost:3000'
    When I send a POST request to '/performance' with large number of cardholders
    Then the response status should be 200
    And the system should be able to handle and send notifications to a large number of cardholders without performance degradation
    But when I send a POST request with a single cardholder
    Then the response status should be 200
    And the system should be able to handle and send notifications to a single cardholder without performance degradation

Feature: Usability API
  Scenario: Test usability
    Given the API base URL 'http://localhost:3000'
    When I send a POST request to '/usability' with notification content
    Then the response status should be 200
    And the content of the notifications should be clear, concise, and easy to understand
    But when I send a POST request with complex and technical notification content
    Then the response status should be 400
    And the response should contain 'Content of the notifications should be clear, concise, and easy to understand'

Feature: Reliability API
  Scenario: Test reliability
    Given the API base URL 'http://localhost:3000'
    When I send a POST request to '/reliability' with continuous operation
    Then the response status should be 200
    And the system should be able to operate continuously without failure
    But when I send a POST request with intermittent operation
    Then the response status should be 400
    And the response should contain 'System should be able to operate continuously without failure'

Feature: Scalability API
  Scenario: Test scalability
    Given the API base URL 'http://localhost:3000'
    When I send a POST request to '/scalability' with increasing number of cardholders
    Then the response status should be 200
    And the system should be able to scale and handle an increasing number of cardholders
    But when I send a POST request with decreasing number of cardholders
    Then the response status should be 400
    And the response should contain 'System should be able to scale and handle an increasing number of cardholders'
