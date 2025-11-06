Feature: Credit Card Payment Notification and Collection Process

Background:
  Given the API base URL 'https://api.creditcardcompany.com'
  And the authorization header is set to a valid API key

Scenario: Send Credit Card Due Reminder
  When I send a POST request to '/notifications/due-reminder' with the request payload:
    | cardNumber | dueDate    |
    | 1234567890 | 2023-06-30 |
  Then the response status should be 200
  And the response body should contain the last 4 digits of the card number '7890'

Scenario: Send Overdue Balance Alert
  When I send a POST request to '/notifications/overdue-alert' with the request payload:
    | cardNumber | overdueBalance |
    | 9876543210 | 500.00         |
  Then the response status should be 200
  And the response body should contain the last 4 digits of the card number '3210'

Scenario: Send Collection Notification
  When I send a POST request to '/collections/notification' with the request payload:
    | cardNumber | outstandingAmount | additionalCharges |
    | 5678901234 | 1000.00           | 50.00             |
  Then the response status should be 200
  And the response body should contain the last 4 digits of the card number '1234'

Scenario: Propose Payment Plan
  When I send a POST request to '/collections/payment-plan' with the request payload:
    | cardNumber | outstandingAmount | proposedPlan |
    | 2345678901 | 2500.00           | <plan details> |
  Then the response status should be 200
  And the response body should contain the last 4 digits of the card number '8901'

Scenario: Involve Collection Agency
  When I send a POST request to '/collections/agency' with the request payload:
    | cardNumber | outstandingAmount | agencyDetails |
    | 8901234567 | 5000.00           | <agency info> |
  Then the response status should be 200
  And the response body should contain the last 4 digits of the card number '4567'

Scenario: Initiate Legal Action
  When I send a POST request to '/collections/legal-action' with the request payload:
    | cardNumber | outstandingAmount | legalDocuments |
    | 7890123456 | 10000.00          | <legal docs>   |
  Then the response status should be 200
  And the response body should contain the last 4 digits of the card number '3456'
