Feature: Credit Card Collection Lifecycle Management System Testing

  Background:
    Given the API base URL is set from environment variable 'BASE_URL'
    And the authorization header is set with token from 'AUTH_TOKEN'
    And the content type is 'application/json'
    And the browser is configured for UI testing
    And the collection system is operational

  # API Test Scenarios

  Scenario: Retrieve credit card account details via API
    Given a credit card account with ID "12345" exists
    When I send a GET request to '/api/accounts/12345'
    Then the response status should be 200
    And the response body should contain 'accountId', 'balance', 'dueDate', and 'lastFourDigits' fields
    And the response body should not contain 'fullCardNumber' field
    And the 'lastFourDigits' field should match pattern "^\d{4}$"

  Scenario: Create due reminder notification via API
    Given a credit card account with upcoming due date
    And the request body:
      '''
      {
        "accountId": "12345",
        "notificationType": "dueReminder",
        "dueDate": "2024-01-15",
        "amountDue": 250.00,
        "lastFourDigits": "1234"
      }
      '''
    When I send a POST request to '/api/notifications/due-reminder'
    Then the response status should be 201
    And the response body should contain 'notificationId' field
    And the response body 'status' should be 'scheduled'
    And the response body should not contain 'fullCardNumber'

  Scenario: Generate overdue balance alert via API
    Given a credit card account with missed payment
    And the request body:
      '''
      {
        "accountId": "12345",
        "overdueAmount": 500.00,
        "daysPastDue": 15,
        "lastFourDigits": "1234",
        "consequences": ["late fees", "interest charges"]
      }
      '''
    When I send a POST request to '/api/notifications/overdue-alert'
    Then the response status should be 201
    And the response body should contain 'alertId' and 'scheduledDate' fields
    And the response body 'notificationType' should be 'overdueAlert'
    And the response body should include 'consequences' array

  Scenario: Create collection notification via API
    Given a significantly delinquent credit card account
    And the request body:
      '''
      {
        "accountId": "12345",
        "totalAmountOwed": 1500.00,
        "additionalCharges": 75.00,
        "daysPastDue": 65,
        "lastFourDigits": "1234",
        "collectionStage": "formal"
      }
      '''
    When I send a POST request to '/api/collections/notification'
    Then the response status should be 201
    And the response body should contain 'collectionId' and 'notificationDate' fields
    And the response body 'stage' should be 'formal'
    And the response body should contain breakdown of charges

  Scenario: Generate payment plan proposal via API
    Given an overdue account eligible for payment plan
    And the request body:
      '''
      {
        "accountId": "12345",
        "totalBalance": 2000.00,
        "proposedMonthlyPayment": 200.00,
        "planDuration": 12,
        "reducedInterestRate": 5.5,
        "lastFourDigits": "1234"
      }
      '''
    When I send a POST request to '/api/payment-plans/proposal'
    Then the response status should be 201
    And the response body should contain 'proposalId' and 'terms' fields
    And the response body 'monthlyPayment' should be 200.00
    And the response body should include 'reducedInterestRate'

  Scenario: Transfer account to collection agency via API
    Given a severely delinquent account ready for escalation
    And the request body:
      '''
      {
        "accountId": "12345",
        "agencyId": "AGENCY001",
        "transferReason": "failed_collection_attempts",
        "accountData": {
          "overdueAmount": 3000.00,
          "lastFourDigits": "1234",
          "paymentHistory": []
        }
      }
      '''
    When I send a POST request to '/api/collections/agency-transfer'
    Then the response status should be 201
    And the response body should contain 'transferId' and 'transferDate' fields
    And the response body should not contain 'fullCardNumber'
    And the response body 'status' should be 'transferred'

  Scenario: Generate legal documentation via API
    Given an account in default status requiring legal action
    And the request body:
      '''
      {
        "accountId": "12345",
        "documentType": "legal_notice",
        "totalAmountOwed": 5000.00,
        "lastFourDigits": "1234",
        "collectionAttempts": 5
      }
      '''
    When I send a POST request to '/api/legal/documentation'
    Then the response status should be 201
    And the response body should contain 'documentId' and 'generatedDate' fields
    And the response body should not contain 'fullCardNumber'
    And the response body 'documentType' should be 'legal_notice'

  Scenario: Validate card number security in API responses
    When I send a GET request to '/api/accounts/12345/notifications'
    Then the response status should be 200
    And the response body should not contain any field matching pattern "^\d{16}$"
    And all card references should only show last 4 digits
    And the response should comply with PCI DSS standards

  Scenario: Test notification delivery performance via API
    Given 100 test accounts with various collection stages
    When I send a POST request to '/api/notifications/bulk-trigger'
    Then the response status should be 202
    And the response body should contain 'batchId' field
    When I send a GET request to '/api/notifications/batch-status/{batchId}'
    Then 95% of notifications should be processed within 5 minutes
    And the delivery success rate should be above 99%

  # UI Test Scenarios

  Scenario: View credit card account details through UI
    Given I am logged into the collection management system
    And I am on the account search page
    When I enter account ID "12345" in the search field
    And I click the 'Search' button
    Then I should see the account details page
    And I should see the last 4 digits of the card number displayed as "****1234"
    And I should not see the full credit card number anywhere on the page
    And I should see the current balance and due date

  Scenario: Create due reminder notification through UI
    Given I am on the account details page for account "12345"
    And the account has an upcoming due date
    When I click the 'Send Due Reminder' button
    And I select 'Email' as the notification method
    And I click the 'Send Notification' button
    Then I should see a success message "Due reminder notification scheduled successfully"
    And I should see the notification in the account activity log
    And the notification preview should show "****1234" for card identification

  Scenario: Generate overdue balance alert through UI
    Given I am on the collections dashboard
    And I navigate to the overdue accounts section
    When I select account "12345" from the overdue list
    And I click the 'Generate Overdue Alert' button
    And I review the alert content
    And I click the 'Send Alert' button
    Then I should see a confirmation message "Overdue alert sent successfully"
    And the alert should include consequences like "late fees" and "interest charges"
    And the card should be identified by "****1234" only

  Scenario: Create formal collection notification through UI
    Given I am on the collections management page
    And account "12345" is marked as significantly delinquent
    When I select the account from the delinquent accounts list
    And I click the 'Generate Collection Notice' button
    And I review the total amount owed and additional charges
    And I click the 'Send Collection Notice' button
    Then I should see "Collection notice generated and sent successfully"
    And the notice should display the breakdown of charges
    And the card identification should show "****1234"

  Scenario: Generate payment plan proposal through UI
    Given I am on the account management page for account "12345"
    And the account is eligible for a payment plan
    When I click the 'Create Payment Plan' button
    And I enter "200" in the monthly payment field
    And I select "12 months" from the duration dropdown
    And I set the reduced interest rate to "5.5%"
    And I click the 'Generate Proposal' button
    Then I should see "Payment plan proposal created successfully"
    And the proposal should show monthly payment of "$200.00"
    And the card should be identified as "****1234"

  Scenario: Transfer account to collection agency through UI
    Given I am on the collections escalation page
    And account "12345" has failed multiple collection attempts
    When I select the account from the escalation queue
    And I choose "AGENCY001" from the collection agency dropdown
    And I click the 'Transfer to Agency' button
    And I confirm the transfer in the popup dialog
    Then I should see "Account successfully transferred to collection agency"
    And the account status should change to "Transferred"
    And the transfer record should show "****1234" for card identification

  Scenario: Generate legal documentation through UI
    Given I am on the legal actions page
    And account "12345" is in default status
    When I select the account from the default accounts list
    And I click the 'Generate Legal Documents' button
    And I select "Legal Notice" from the document type dropdown
    And I click the 'Generate Documents' button
    Then I should see "Legal documentation generated successfully"
    And the documents should be available for download
    And all documents should show "****1234" for card identification
    And no full card numbers should be visible in any document

  Scenario: Validate card number security across UI pages
    Given I am logged into the collection management system
    When I navigate through all collection lifecycle pages
    And I view account details, notifications, and documents
    Then I should never see full credit card numbers displayed
    And all card references should show only "****" followed by 4 digits
    And the UI should comply with security standards

  Scenario: Monitor notification delivery status through UI
    Given I am on the notifications dashboard
    And I have triggered multiple notifications
    When I view the notification delivery status page
    Then I should see real-time delivery statistics
    And I should see delivery success rates above 99%
    And I should see average delivery times under 5 minutes
    And I should be able to filter notifications by delivery status

  Scenario: Handle invalid account access through UI
    Given I am on the account search page
    When I enter an invalid account ID "99999"
    And I click the 'Search' button
    Then I should see an error message "Account not found"
    And I should not see any sensitive information displayed
    And I should be redirected back to the search page

  Scenario: Test system performance during peak load through UI
    Given the system is under peak load conditions
    And I am logged into the collection management system
    When I navigate between different collection pages
    And I perform various collection actions
    Then all pages should load within 3 seconds
    And all actions should complete successfully
    And the system should remain responsive throughout the session
