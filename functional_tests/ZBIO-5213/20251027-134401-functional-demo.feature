Feature: Credit Card Collection Lifecycle API Testing

Background:
  Given the API base URL is set from environment variable "API_BASE_URL"
  And the authorization header is set with bearer token from environment variable "AUTH_TOKEN"
  And the content type is "application/json"

Scenario: Send Credit Card Due Reminder Notification
  Given a credit card account with card number ending in "1234" exists
  And the payment due date is 3 days from current date
  And the system is configured to send reminders 5 days before due date
  When I send a POST request to "/notifications/due-reminder" with payload:
    """
    {
      "accountId": "ACC123456",
      "cardLastFour": "1234",
      "dueDate": "2024-01-15",
      "amountDue": 250.00,
      "contactMethod": "email"
    }
    """
  Then the response status should be 201
  And the response should contain:
    """
    {
      "notificationId": "string",
      "status": "sent",
      "cardLastFour": "1234",
      "message": "Due reminder sent successfully"
    }
    """
  And the response should not contain full card number
  And the notification should be delivered within 5 minutes

Scenario: Generate Overdue Balance Alert
  Given a credit card account with overdue balance exists
  And the payment due date has passed
  When I send a POST request to "/notifications/overdue-alert" with payload:
    """
    {
      "accountId": "ACC123457",
      "cardLastFour": "5678",
      "overdueAmount": 500.00,
      "daysPastDue": 15,
      "contactMethod": "sms"
    }
    """
  Then the response status should be 201
  And the response should contain:
    """
    {
      "alertId": "string",
      "status": "generated",
      "cardLastFour": "5678",
      "overdueAmount": 500.00,
      "consequences": "Late fees and interest charges may apply"
    }
    """
  And the full card number should not be present in response

Scenario: Create Collection Notification for Delinquent Account
  Given a credit card account is 60+ days overdue
  And multiple payment attempts have failed
  When I send a POST request to "/collections/formal-notice" with payload:
    """
    {
      "accountId": "ACC123458",
      "cardLastFour": "9012",
      "totalAmountOwed": 1500.00,
      "additionalCharges": 75.00,
      "delinquencyDays": 65
    }
    """
  Then the response status should be 201
  And the response should contain:
    """
    {
      "noticeId": "string",
      "status": "created",
      "cardLastFour": "9012",
      "totalAmount": 1575.00,
      "paymentDeadline": "string"
    }
    """
  And the response should include detailed charge breakdown
  And full card number should remain secure

Scenario: Generate Payment Plan Proposal
  Given an overdue credit card account exists
  And the cardholder has financial hardship status
  When I send a POST request to "/collections/payment-plan" with payload:
    """
    {
      "accountId": "ACC123459",
      "cardLastFour": "3456",
      "totalBalance": 2000.00,
      "hardshipStatus": true,
      "proposedMonthlyPayment": 200.00
    }
    """
  Then the response status should be 201
  And the response should contain:
    """
    {
      "planId": "string",
      "cardLastFour": "3456",
      "monthlyPayment": 200.00,
      "reducedInterestRate": 5.99,
      "paymentSchedule": "array"
    }
    """
  And the payment plan terms should be included
  And full card number should not be exposed

Scenario: Transfer Account Data to Collection Agency
  Given a severely delinquent credit card account exists
  And previous collection attempts have failed
  When I send a POST request to "/collections/agency-transfer" with payload:
    """
    {
      "accountId": "ACC123460",
      "cardLastFour": "7890",
      "agencyId": "AGENCY001",
      "transferReason": "failed_internal_collection"
    }
    """
  Then the response status should be 200
  And the response should contain:
    """
    {
      "transferId": "string",
      "status": "transferred",
      "cardLastFour": "7890",
      "agencyId": "AGENCY001",
      "transferDate": "string"
    }
    """
  And the full card number should not be included in transfer data
  And secure transfer protocols should be validated

Scenario: Prepare Legal Action Documentation
  Given a credit card account is in default status
  And all collection attempts have been exhausted
  When I send a POST request to "/legal/documentation" with payload:
    """
    {
      "accountId": "ACC123461",
      "cardLastFour": "2468",
      "defaultAmount": 5000.00,
      "legalActionType": "court_filing"
    }
    """
  Then the response status should be 201
  And the response should contain:
    """
    {
      "documentId": "string",
      "status": "prepared",
      "cardLastFour": "2468",
      "documentType": "court_filing",
      "createdDate": "string"
    }
    """
  And legal documentation should be complete and accurate
  And full card number should not be present in documents

Scenario: Validate Card Number Security - Negative Test
  Given any collection lifecycle endpoint
  When I send a GET request to "/collections/account/ACC123456"
  Then the response status should be 200
  And the response should contain only last 4 digits of card number
  And the response should not contain full card number in any field
  And all card number fields should be properly masked

Scenario: Test Notification Delivery Performance
  Given 100 test accounts are configured for notifications
  When I send a POST request to "/notifications/bulk-trigger" with payload:
    """
    {
      "accounts": ["ACC001", "ACC002", "ACC003"],
      "notificationType": "due_reminder",
      "triggerTime": "immediate"
    }
    """
  Then the response status should be 202
  And the response should contain:
    """
    {
      "batchId": "string",
      "totalAccounts": 100,
      "status": "processing"
    }
    """
  And 95% of notifications should be delivered within 5 minutes
  And delivery success rate should be above 99.9%

Scenario: Invalid Card Account - Error Handling
  Given an invalid account ID
  When I send a POST request to "/notifications/due-reminder" with payload:
    """
    {
      "accountId": "INVALID123",
      "cardLastFour": "0000",
      "dueDate": "2024-01-15",
      "amountDue": 250.00
    }
    """
  Then the response status should be 404
  And the response should contain:
    """
    {
      "error": "Account not found",
      "code": "ACCOUNT_NOT_FOUND",
      "message": "The specified account ID does not exist"
    }
    """

Scenario: Unauthorized Access - Security Test
  Given no authorization header is provided
  When I send a GET request to "/collections/account/ACC123456"
  Then the response status should be 401
  And the response should contain:
    """
    {
      "error": "Unauthorized",
      "message": "Valid authorization token required"
    }
    """
