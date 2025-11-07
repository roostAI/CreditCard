Feature: Credit Card Collection Lifecycle Management System

  Background:
    Given the API base URL is set from environment variable 'BASE_URL'
    And the authorization header is set with token from environment variable 'AUTH_TOKEN'
    And the content type is 'application/json'
    And the browser is configured for testing
    And I navigate to the credit card management portal

  # API Test Scenarios
  Scenario: Send payment due reminder notification via API
    Given the request body:
      """
      {
        "currentDate": "2024-01-10",
        "paymentDueDate": "2024-01-15",
        "cardLast4": "1234",
        "amountDue": 250.00,
        "cardholderEmail": "john.doe@example.com",
        "cardholderPhone": "+1234567890"
      }
      """
    When I send a POST request to '/payment-reminder'
    Then the response status should be 200
    And the response body should contain 'notificationId'
    And the response body 'deliveryStatus' should be 'sent'
    And the response body 'cardLast4' should be '1234'
    And the response body 'amountDue' should be 250.00
    And the response body should contain 'deliveryMethod' array

  Scenario: Generate overdue balance alert via API
    Given the request body:
      """
      {
        "paymentDueDate": "2024-01-10",
        "currentDate": "2024-01-15",
        "cardLast4": "5678",
        "overdueAmount": 500.00,
        "lateFees": 35.00,
        "interestCharges": 25.50
      }
      """
    When I send a POST request to '/balance-alert'
    Then the response status should be 200
    And the response body should contain 'alertId'
    And the response body 'overdueAmount' should be 500.00
    And the response body 'consequences' should contain 'lateFees'
    And the response body 'consequences' should contain 'interestCharges'
    And the response body 'cardLast4' should be '5678'
    And the response body should contain 'paymentInstructions'

  Scenario: Create collection notification for delinquent account via API
    Given the request body:
      """
      {
        "delinquencyStatus": "60+ days overdue",
        "outstandingBalance": "1500.00",
        "additionalCharges": "150.00",
        "cardLast4": "9012",
        "paymentDeadline": "2024-02-01"
      }
      """
    When I send a POST request to '/collection-notification'
    Then the response status should be 200
    And the response body should contain 'notificationId'
    And the response body should contain 'totalAmountOwed'
    And the response body 'chargeBreakdown' should contain 'principalAmount'
    And the response body 'chargeBreakdown' should contain 'lateFees'
    And the response body 'cardLast4' should be '9012'
    And the response body 'paymentDeadline' should be '2024-02-01'

  Scenario: Generate payment plan proposal via API
    Given the request body:
      """
      {
        "outstandingBalance": "2000.00",
        "paymentPlan": {
          "installmentAmount": "200.00",
          "interestRate": "5.0",
          "termLength": "12 months",
          "feeWaivers": {
            "lateFeeWaiver": true,
            "interestReduction": 2.5
          }
        },
        "cardLast4": "3456",
        "hardshipStatus": true
      }
      """
    When I send a POST request to '/payment-plan-proposal'
    Then the response status should be 200
    And the response body should contain 'proposalId'
    And the response body should contain 'repaymentSchedule' array
    And the response body should contain 'termsAndConditions'
    And the response body 'cardLast4' should be '3456'

  Scenario: Transfer account data to collection agency via API
    Given the request body:
      """
      {
        "previousNotifications": "Multiple reminders sent",
        "responseStatus": "No response",
        "cardLast4": "7890",
        "accountData": {
          "cardholderName": "Jane Smith",
          "cardholderAddress": "123 Main St, City, State",
          "overdueAmount": 3000.00,
          "paymentHistory": [
            {
              "date": "2023-12-01",
              "amount": 100.00,
              "status": "paid"
            }
          ]
        }
      }
      """
    When I send a POST request to '/collection-agency'
    Then the response status should be 200
    And the response body should contain 'transferId'
    And the response body 'transferStatus' should be 'completed'
    And the response body 'securityValidation.fullCardNumberExcluded' should be true
    And the response body 'cardLast4' should be '7890'

  Scenario: Initiate legal action documentation via API
    Given the request body:
      """
      {
        "nonPaymentStatus": "Default",
        "legalStatus": "Authorized for legal action",
        "cardLast4": "2468",
        "accountHistory": {
          "collectionAttempts": [
            {
              "date": "2024-01-01",
              "method": "Phone call",
              "outcome": "No response"
            }
          ],
          "paymentHistory": [
            {
              "date": "2023-11-01",
              "amount": 50.00,
              "status": "paid"
            }
          ]
        }
      }
      """
    When I send a POST request to '/legal-action'
    Then the response status should be 200
    And the response body should contain 'documentId'
    And the response body should contain 'legalDocuments' array
    And the response body 'securityCompliance.fullCardNumberExcluded' should be true
    And the response body 'securityCompliance.onlyLast4Included' should be true
    And the response body 'cardLast4' should be '2468'

  Scenario: Validate card number security across system via API
    Given the request body:
      """
      {
        "validationType": "full_system"
      }
      """
    When I send a POST request to '/security/validate'
    Then the response status should be 200
    And the response body should contain 'validationId'
    And the response body 'securityStatus' should be 'compliant'
    And the response body should contain 'findings' array

  Scenario: Retrieve performance metrics for notification delivery via API
    When I send a GET request to '/performance/monitoring?timeRange=24h&notificationType=all'
    Then the response status should be 200
    And the response body should contain 'deliveryMetrics'
    And the response body 'deliveryMetrics.successRate' should be greater than 0.95
    And the response body should contain 'systemPerformance'
    And the response body 'systemPerformance.averageResponseTime' should be less than 2000

  Scenario: Retrieve audit logs for security compliance via API
    When I send a GET request to '/audit/logs?logType=card_access&startDate=2024-01-01&endDate=2024-01-31'
    Then the response status should be 200
    And the response body should contain 'logs' array
    And each log entry should contain 'cardDataAccess' field
    And each log entry 'securityCompliant' should be true

  # UI Test Scenarios
  Scenario: View payment reminder notification in UI
    Given I am logged in as a cardholder
    And I have a credit card ending in '1234' with upcoming payment due
    When I navigate to the notifications page
    Then I should see a payment reminder notification
    And the notification should display 'Payment due on January 15, 2024'
    And the notification should show 'Card ending in 1234'
    And the notification should display the amount due
    And I should not see the full credit card number

  Scenario: Acknowledge overdue balance alert in UI
    Given I am logged in as a cardholder
    And I have an overdue balance on card ending in '5678'
    When I navigate to the alerts section
    Then I should see an overdue balance alert
    And the alert should display 'Overdue amount: $500.00'
    And the alert should show 'Late fees: $35.00'
    And the alert should display 'Card ending in 5678'
    When I click the 'Acknowledge' button
    Then I should see a confirmation message
    And the alert status should change to 'Acknowledged'

  Scenario: Review collection notification details in UI
    Given I am logged in as a cardholder
    And I have received a collection notification for card ending in '9012'
    When I navigate to the collection notices section
    Then I should see the formal collection notification
    And the notice should display 'Total amount owed: $1,650.00'
    And the notice should show 'Payment deadline: February 1, 2024'
    And the notice should display 'Card ending in 9012'
    And I should see a detailed breakdown of charges
    When I click 'View Full Details'
    Then I should see the complete charge breakdown
    And I should not see the full credit card number anywhere

  Scenario: Accept payment plan proposal in UI
    Given I am logged in as a cardholder
    And I have a payment plan proposal for card ending in '3456'
    When I navigate to the payment plans section
    Then I should see the proposed payment plan
    And the plan should show '12 monthly payments of $200.00'
    And the plan should display 'Reduced interest rate: 5.0%'
    And the plan should show 'Card ending in 3456'
    When I click 'Accept Payment Plan'
    And I confirm my acceptance
    Then I should see a success message 'Payment plan accepted'
    And I should be redirected to the payment schedule page

  Scenario: View account transfer notification in UI
    Given I am logged in as a cardholder
    And my account ending in '7890' has been transferred to collection agency
    When I navigate to the account status page
    Then I should see a notice 'Account transferred to collection agency'
    And the notice should display 'Card ending in 7890'
    And I should see collection agency contact information
    And I should not see my full credit card number
    When I click 'View Transfer Details'
    Then I should see the transfer date and reason
    And I should see instructions for contacting the collection agency

  Scenario: Access legal action documentation in UI
    Given I am logged in as a cardholder
    And legal action has been initiated for card ending in '2468'
    When I navigate to the legal notices section
    Then I should see a legal action notice
    And the notice should display 'Legal proceedings initiated'
    And the notice should show 'Card ending in 2468'
    When I click 'View Legal Documents'
    Then I should see a list of legal documents
    And each document should show only the last 4 digits of my card
    And I should not see my full credit card number in any document

  Scenario: Monitor notification delivery status in admin UI
    Given I am logged in as an administrator
    When I navigate to the notification monitoring dashboard
    Then I should see delivery statistics for the last 24 hours
    And I should see 'Success rate: 99.5%'
    And I should see 'Average delivery time: 45 seconds'
    When I filter by notification type 'Payment Reminders'
    Then I should see specific metrics for payment reminders
    And I should see a list of recent notifications
    And each notification should show only masked card numbers

  Scenario: Perform security audit in admin UI
    Given I am logged in as a security administrator
    When I navigate to the security audit section
    And I click 'Run Security Scan'
    Then I should see 'Security scan initiated'
    When the scan completes
    Then I should see 'Security Status: Compliant'
    And I should see 'Full card numbers: 0 exposures found'
    And I should see 'Last 4 digits only: Verified'
    When I click 'View Detailed Report'
    Then I should see a comprehensive security report
    And the report should confirm no full card number exposures
