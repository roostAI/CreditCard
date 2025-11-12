Feature: Credit Card Collection Lifecycle Management System Testing

  Background:
    Given the API base URL is set from environment variable 'BASE_URL'
    And the authorization header is set with token from 'AUTH_TOKEN'
    And the content type is 'application/json'
    And the browser is configured for UI testing
    And the collection management system is accessible

  # API Test Scenarios

  Scenario: Retrieve credit card accounts due for reminder notifications via API
    When I send a GET request to '/api/collections/due-reminders'
    Then the response status should be 200
    And the response body should be a JSON array
    And each account object should contain 'accountId', 'maskedCardNumber', 'dueDate', and 'reminderThreshold' fields
    And the 'maskedCardNumber' field should match pattern '****[0-9]{4}'
    And no full credit card numbers should be present in the response

  Scenario: Create due reminder notification via API
    Given the request body:
      '''
      {
        "accountId": "ACC123456",
        "cardNumber": "4532123456789012",
        "dueDate": "2024-02-15",
        "reminderType": "due_reminder",
        "contactMethod": "email"
      }
      '''
    When I send a POST request to '/api/collections/notifications'
    Then the response status should be 201
    And the response body should contain 'notificationId' field
    And the response body 'maskedCardNumber' should be '****9012'
    And the response body should not contain the full card number '4532123456789012'

  Scenario: Generate overdue balance alert via API
    Given the request body:
      '''
      {
        "accountId": "ACC789012",
        "cardNumber": "5555444433332222",
        "overdueAmount": 1250.75,
        "daysPastDue": 5,
        "alertType": "overdue_balance"
      }
      '''
    When I send a POST request to '/api/collections/alerts'
    Then the response status should be 201
    And the response body should contain 'alertId' field
    And the response body 'maskedCardNumber' should be '****2222'
    And the response body 'overdueAmount' should be 1250.75
    And the response body should not expose the full card number

  Scenario: Create formal collection notification via API
    Given the request body:
      '''
      {
        "accountId": "ACC345678",
        "cardNumber": "4111111111111111",
        "totalAmountOwed": 3500.00,
        "daysPastDue": 65,
        "additionalCharges": {
          "lateFees": 150.00,
          "interestCharges": 275.50
        },
        "notificationType": "formal_collection"
      }
      '''
    When I send a POST request to '/api/collections/formal-notifications'
    Then the response status should be 201
    And the response body should contain 'formalNotificationId' field
    And the response body 'maskedCardNumber' should be '****1111'
    And the response body 'totalAmountOwed' should be 3500.00
    And the response body should contain 'additionalCharges' object
    And no full credit card number should be present in the response

  Scenario: Generate payment plan proposal via API
    Given the request body:
      '''
      {
        "accountId": "ACC567890",
        "cardNumber": "3782822463100005",
        "overdueBalance": 2800.00,
        "proposedMonthlyPayment": 350.00,
        "planDuration": 8,
        "reducedInterestRate": 5.5
      }
      '''
    When I send a POST request to '/api/collections/payment-plans'
    Then the response status should be 201
    And the response body should contain 'paymentPlanId' field
    And the response body 'maskedCardNumber' should be '****0005'
    And the response body 'proposedMonthlyPayment' should be 350.00
    And the response body 'planDuration' should be 8
    And the full card number should not be exposed

  Scenario: Initiate collection agency handover via API
    Given the request body:
      '''
      {
        "accountId": "ACC901234",
        "cardNumber": "6011111111111117",
        "agencyId": "AGENCY001",
        "handoverReason": "no_response_to_notifications",
        "accountBalance": 4200.00
      }
      '''
    When I send a POST request to '/api/collections/agency-handover'
    Then the response status should be 201
    And the response body should contain 'handoverId' field
    And the response body 'maskedCardNumber' should be '****1117'
    And the response body 'agencyId' should be 'AGENCY001'
    And the response body should not contain the full card number

  Scenario: Prepare legal action documentation via API
    Given the request body:
      '''
      {
        "accountId": "ACC112233",
        "cardNumber": "5105105105105100",
        "legalActionType": "debt_recovery",
        "totalDebt": 8500.00,
        "defaultPeriod": 120
      }
      '''
    When I send a POST request to '/api/collections/legal-documentation'
    Then the response status should be 201
    And the response body should contain 'legalDocumentId' field
    And the response body 'maskedCardNumber' should be '****5100'
    And the response body 'totalDebt' should be 8500.00
    And the full card number should be protected and not included

  Scenario: Validate card number security in all collection communications via API
    When I send a GET request to '/api/collections/communications/security-audit'
    Then the response status should be 200
    And the response body should contain 'auditResults' array
    And each audit result should have 'communicationType' and 'securityStatus' fields
    And all 'securityStatus' values should be 'SECURE'
    And the response should confirm no full card numbers are exposed

  Scenario: Handle invalid collection notification request via API
    Given the request body:
      '''
      {
        "accountId": "",
        "cardNumber": "invalid_card",
        "dueDate": "invalid_date"
      }
      '''
    When I send a POST request to '/api/collections/notifications'
    Then the response status should be 400
    And the response body should contain 'error' field
    And the response body 'error' should contain 'Invalid request parameters'

  Scenario: Test unauthorized access to collection data via API
    Given the authorization header is not set
    When I send a GET request to '/api/collections/due-reminders'
    Then the response status should be 401
    And the response body should contain 'error' field
    And the response body 'error' should be 'Unauthorized access'

  # UI Test Scenarios

  Scenario: View due reminder notifications dashboard
    Given I am on the collection management dashboard
    When I click on the 'Due Reminders' tab
    Then I should see a list of accounts with upcoming due dates
    And each account entry should display masked card numbers in format '****XXXX'
    And I should see due dates and reminder status for each account
    And no full credit card numbers should be visible on the page

  Scenario: Create due reminder notification through UI
    Given I am on the collection notifications page
    When I click the 'Create Reminder' button
    And I enter 'ACC123456' in the account ID field
    And I enter '4532123456789012' in the card number field
    And I select 'Email' from the contact method dropdown
    And I click the 'Generate Reminder' button
    Then I should see a success message 'Due reminder notification created successfully'
    And the notification preview should show '****9012' as the card number
    And the full card number should not be displayed anywhere

  Scenario: Generate overdue balance alert through UI
    Given I am on the overdue accounts page
    When I select an account with ID 'ACC789012'
    And I click the 'Generate Alert' button
    And I verify the overdue amount shows '$1,250.75'
    And I confirm the masked card number displays '****2222'
    And I click the 'Send Alert' button
    Then I should see a confirmation message 'Overdue balance alert sent successfully'
    And the alert should be logged in the account history

  Scenario: Create formal collection notification through UI
    Given I am on the formal collections page
    When I search for account 'ACC345678'
    And I click on the account to open details
    And I click the 'Create Formal Notice' button
    And I verify the total amount owed shows '$3,500.00'
    And I confirm additional charges are displayed correctly
    And I ensure the card number shows as '****1111'
    And I click the 'Generate Notice' button
    Then I should see 'Formal collection notice generated successfully'
    And the notice should appear in the account's collection history

  Scenario: Generate payment plan proposal through UI
    Given I am on the payment plans page
    When I enter 'ACC567890' in the account search field
    And I click the 'Search' button
    And I click the 'Create Payment Plan' button
    And I enter '350' in the monthly payment field
    And I select '8 months' from the duration dropdown
    And I verify the masked card number shows '****0005'
    And I click the 'Generate Proposal' button
    Then I should see 'Payment plan proposal created successfully'
    And the proposal details should be saved to the account

  Scenario: Initiate collection agency handover through UI
    Given I am on the agency handover page
    When I select account 'ACC901234' from the account list
    And I choose 'AGENCY001' from the collection agency dropdown
    And I select 'No response to notifications' as the handover reason
    And I verify the account balance shows '$4,200.00'
    And I confirm the card number displays as '****1117'
    And I click the 'Initiate Handover' button
    Then I should see 'Account successfully handed over to collection agency'
    And the account status should update to 'With Collection Agency'

  Scenario: Prepare legal action documentation through UI
    Given I am on the legal actions page
    When I search for account 'ACC112233'
    And I select 'Debt Recovery' as the legal action type
    And I verify the total debt amount shows '$8,500.00'
    And I confirm the card number is masked as '****5100'
    And I click the 'Prepare Legal Documentation' button
    Then I should see 'Legal documentation prepared successfully'
    And the documentation should be available for download
    And no full card numbers should appear in the generated documents

  Scenario: Validate card number masking across all UI screens
    Given I am on the collection management dashboard
    When I navigate through all collection-related pages
    And I check the due reminders page
    And I check the overdue accounts page
    And I check the formal collections page
    And I check the payment plans page
    And I check the agency handover page
    And I check the legal actions page
    Then all card numbers should be displayed in masked format '****XXXX'
    And no full credit card numbers should be visible on any page
    And all account identification should use only the last 4 digits

  Scenario: Handle error when creating notification with invalid data through UI
    Given I am on the collection notifications page
    When I click the 'Create Reminder' button
    And I leave the account ID field empty
    And I enter 'invalid_card_number' in the card number field
    And I click the 'Generate Reminder' button
    Then I should see an error message 'Please provide valid account and card information'
    And the form should highlight the invalid fields in red
    And no notification should be created

  Scenario: Search and filter collection accounts through UI
    Given I am on the collection accounts page
    When I enter '****1234' in the card number search field
    And I select 'Overdue' from the status filter dropdown
    And I click the 'Search' button
    Then I should see a filtered list of accounts matching the criteria
    And each result should show the masked card number format
    And the account status should be 'Overdue' for all results
    And I should be able to click on any account to view details

  Scenario: Generate collection reports through UI
    Given I am on the collection reports page
    When I select 'Monthly Collection Summary' from the report type dropdown
    And I choose the current month from the date range picker
    And I click the 'Generate Report' button
    Then I should see a comprehensive collection report
    And all card numbers in the report should be masked as '****XXXX'
    And the report should include statistics for reminders, alerts, and formal notices
    And I should be able to export the report as PDF or Excel
    And the exported report should maintain card number masking
