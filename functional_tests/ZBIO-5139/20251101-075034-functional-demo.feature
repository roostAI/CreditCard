Feature: Credit Card Management System Testing

  Background:
    Given the API base URL is set from environment variable 'BASE_URL'
    And the authorization header is set with token from 'AUTH_TOKEN'
    And the content type is 'application/json'
    And the browser is configured for UI testing

  # API Test Scenarios

  Scenario: Submit valid credit card application via API
    Given the request body:
      '''
      {
        "ssn": "123-45-6789",
        "annualIncome": 50000,
        "email": "test@email.com",
        "phone": "555-1234",
        "firstName": "John",
        "lastName": "Doe",
        "address": {
          "street": "123 Main St",
          "city": "Anytown",
          "state": "CA",
          "zipCode": "12345"
        }
      }
      '''
    When I send a POST request to '/api/credit-card/applications'
    Then the response status should be 201
    And the response body should contain 'applicationId' field
    And the response body should contain 'status' with value 'submitted'
    And the response body 'email' should be 'test@email.com'

  Scenario: Submit invalid credit card application via API
    Given the request body:
      '''
      {
        "ssn": "",
        "annualIncome": -1000,
        "email": "invalid-email",
        "phone": ""
      }
      '''
    When I send a POST request to '/api/credit-card/applications'
    Then the response status should be 400
    And the response body should contain 'errors' field
    And the response body 'errors' should contain 'ssn is required'
    And the response body 'errors' should contain 'invalid email format'
    And the response body 'errors' should contain 'income must be positive'

  Scenario: Process charge waiver via API
    Given the request body:
      '''
      {
        "customerId": "CUST123",
        "chargeId": "CHG456",
        "chargeAmount": 25.00,
        "reason": "good payment history",
        "approvedBy": "REP001"
      }
      '''
    When I send a POST request to '/api/charges/waiver'
    Then the response status should be 200
    And the response body should contain 'waiverApproved' with value true
    And the response body should contain 'newBalance' field
    And the response body should contain 'confirmationNumber' field

  Scenario: Redeem reward points via API
    Given the request body:
      '''
      {
        "customerId": "CUST123",
        "pointsToRedeem": 2000,
        "rewardId": "GIFT20",
        "rewardType": "gift_card"
      }
      '''
    When I send a POST request to '/api/rewards/redeem'
    Then the response status should be 200
    And the response body should contain 'redemptionId' field
    And the response body 'remainingPoints' should be 3000
    And the response body 'status' should be 'processed'

  Scenario: Attempt to redeem insufficient points via API
    Given the request body:
      '''
      {
        "customerId": "CUST456",
        "pointsToRedeem": 2000,
        "rewardId": "GIFT20",
        "rewardType": "gift_card"
      }
      '''
    When I send a POST request to '/api/rewards/redeem'
    Then the response status should be 400
    And the response body should contain 'error' with value 'insufficient points'
    And the response body should contain 'availablePoints' field
    And the response body should contain 'requiredPoints' field

  Scenario: Update credit limit via API
    Given the request body:
      '''
      {
        "customerId": "CUST123",
        "newCreditLimit": 7500,
        "previousLimit": 5000,
        "reason": "creditworthiness improvement",
        "approvedBy": "SYSTEM"
      }
      '''
    When I send a PUT request to '/api/credit-limit/update'
    Then the response status should be 200
    And the response body should contain 'limitUpdated' with value true
    And the response body 'newLimit' should be 7500
    And the response body should contain 'effectiveDate' field

  Scenario: Process balance transfer via API
    Given the request body:
      '''
      {
        "customerId": "CUST123",
        "externalCardLast4": "1234",
        "transferAmount": 2000,
        "promotionalOffer": {
          "aprRate": 0,
          "termMonths": 12
        }
      }
      '''
    When I send a POST request to '/api/balance-transfer'
    Then the response status should be 201
    And the response body should contain 'transferId' field
    And the response body 'status' should be 'approved'
    And the response body should contain 'promotionalTerms' field

  Scenario: Retrieve customer account details via API
    When I send a GET request to '/api/customers/CUST123/account'
    Then the response status should be 200
    And the response body should contain 'customerId' field
    And the response body should contain 'creditLimit' field
    And the response body should contain 'availableCredit' field
    And the response body should contain 'rewardPoints' field

  # UI Test Scenarios

  Scenario: Submit valid credit card application through UI
    Given I am on the credit card application page
    When I enter '123-45-6789' in the SSN field
    And I enter '50000' in the annual income field
    And I enter 'test@email.com' in the email field
    And I enter '555-1234' in the phone field
    And I enter 'John' in the first name field
    And I enter 'Doe' in the last name field
    And I click the 'Submit Application' button
    Then I should see a success message 'Application submitted successfully'
    And I should see an application reference number
    And I should be redirected to the confirmation page

  Scenario: Submit invalid credit card application through UI
    Given I am on the credit card application page
    When I leave the SSN field empty
    And I enter '-1000' in the annual income field
    And I enter 'invalid-email' in the email field
    And I click the 'Submit Application' button
    Then I should see an error message 'SSN is required'
    And I should see an error message 'Please enter a valid email address'
    And I should see an error message 'Income must be a positive number'
    And the application should not be submitted

  Scenario: Customer requests charge waiver through UI
    Given I am logged in as a customer service representative
    And I am on the customer account page for 'CUST123'
    When I navigate to the charges section
    And I select the charge of '$25.00' for waiver
    And I enter 'good payment history' as the reason
    And I click the 'Approve Waiver' button
    Then I should see a confirmation message 'Charge waiver approved'
    And the account balance should be updated
    And I should see the waiver reflected in the transaction history

  Scenario: Redeem reward points through UI
    Given I am logged in as a customer with account 'CUST123'
    And I am on the rewards page
    When I view my available points balance showing '5000 points'
    And I select a '$20 gift card' requiring '2000 points'
    And I click the 'Redeem Points' button
    And I confirm the redemption
    Then I should see a success message 'Points redeemed successfully'
    And my points balance should show '3000 points'
    And I should receive a confirmation with delivery details

  Scenario: Attempt to redeem insufficient points through UI
    Given I am logged in as a customer with account 'CUST456'
    And I am on the rewards page
    When I view my available points balance showing '1000 points'
    And I select a '$20 gift card' requiring '2000 points'
    And I click the 'Redeem Points' button
    Then I should see an error message 'Insufficient points for this reward'
    And I should see 'Available: 1000 points, Required: 2000 points'
    And the redemption should not be processed

  Scenario: View credit limit increase notification through UI
    Given I am logged in as a customer with account 'CUST123'
    And I am on the account dashboard
    When I navigate to the notifications section
    Then I should see a notification 'Your credit limit has been increased'
    And I should see 'New limit: $7,500 (previously $5,000)'
    And I should see the effective date of the change
    And I should be able to view the updated limit in my account summary

  Scenario: Process balance transfer through UI
    Given I am logged in as a customer with available credit
    And I am on the balance transfer page
    When I enter '1234' as the last 4 digits of external card
    And I enter '2000' as the transfer amount
    And I select the promotional offer '0% APR for 12 months'
    And I review the transfer terms and fees
    And I click the 'Submit Transfer Request' button
    Then I should see a confirmation message 'Balance transfer approved'
    And I should see the transfer details with promotional terms
    And I should receive an email confirmation

  Scenario: Cross-browser compatibility test for application form
    Given I am using Chrome browser
    And I am on the credit card application page
    When I fill out the complete application form
    And I submit the application
    Then the form should function properly
    And I switch to Firefox browser
    And I repeat the same application process
    Then the form should function identically
    And the layout should remain consistent across browsers

  Scenario: System recovery after connection loss during application
    Given I am on the credit card application page
    And I have filled 80% of the required fields
    When the network connection is lost
    And I wait for 30 seconds
    And the network connection is restored
    Then I should see an appropriate error message about connection loss
    And my entered data should be preserved
    And I should be able to complete the application without data loss

  Scenario: Email notification delivery validation
    Given I have submitted a credit card application
    When I check my email inbox within 2 minutes
    Then I should receive a confirmation email
    And the email should contain the application reference number
    And the email content should be properly formatted
    And I perform a fee waiver operation
    Then I should receive a fee waiver confirmation email
    And the delivery time should be within 2 minutes
