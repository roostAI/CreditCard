Feature: Credit Card Notifications and Alerts

Scenario: Credit Card Due Reminder
Given the API base URL 'http://localhost:3000'
When I send a POST request to '/payment-reminder' with body
    """
    {
        "currentDate": "2022-07-14",
        "paymentDueDate": "2022-07-15",
        "cardLast4": "1234"
    }
    """
Then the response status should be 200
And the response should contain 'Reminder about the payment due date for your card ending in 1234.'

Scenario: Overdue Balance Alert
Given the API base URL 'http://localhost:3000'
When I send a POST request to '/balance-alert' with body
    """
    {
        "paymentDueDate": "2022-07-15",
        "currentDate": "2022-07-16",
        "cardLast4": "1234"
    }
    """
Then the response status should be 200
And the response should contain 'You have overdue balance for your card ending in 1234. Please make payment immediately to avoid charges.'

Scenario: Collection Notification
Given the API base URL 'http://localhost:3000'
When I send a POST request to '/collection-notification' with body
    """
    {
        "delinquencyStatus": "60 days overdue",
        "outstandingBalance": "$350.00",
        "additionalCharges": "$50.00",
        "cardLast4": "1234"
    }
    """
Then the response status should be 200
And the response should contain 'Your account has become significantly delinquent. Please contact us immediately to avoid further charges.'

Scenario: Payment Plan Proposal
Given the API base URL 'http://localhost:3000'
When I send a POST request to '/payment-plan-proposal' with body
    """
    {
        "outstandingBalance": "$350.00",
        "paymentPlan": {
            "installmentAmount": "$50.00",
            "interestRate": "6%",
            "termLength": "6 months"
        },
        "cardLast4": "1234"
    }
    """
Then the response status should be 200
And the response should contain 'We propose a payment plan for your card ending in 1234. Please review it and respond promptly.'

Scenario: Collection Agency Involvement
Given the API base URL 'http://localhost:3000'
When I send a POST request to '/collection-agency' with body
    """
    {
        "previousNotifications": "3",
        "responseStatus": "No response",
        "cardLast4": "1234"
    }
    """
Then the response status should be 200
And the response should contain 'Collection agency now involved for credit card ending with 1234.'

Scenario: Legal Action Initiation
Given the API base URL 'http://localhost:3000'
When I send a POST request to '/legal-action' with body
    """
    {
        "nonPaymentStatus": "90 days overdue",
        "legalStatus": "Notice served",
        "cardLast4": "1234"
    }
    """
Then the response status should be 200
And the response should contain 'Legal action initiated for credit card ending with 1234.'

Scenario: Performance Testing
Given the API base URL 'http://localhost:3000'
When I send multiple simultaneous requests to '/notifications'
Then the response status for each request should be 200

Scenario: Security Testing
Given the API base URL 'http://localhost:3000'
When I send a GET request to '/card-details'
Then the response should not contain the full credit card number

Scenario: Compatibility Testing
Given the API base URL 'http://localhost:3000'
When I send notifications through supported platforms
Then the notifications should display as expected on each platform

Scenario: Usability Testing
Given the API base URL 'http://localhost:3000'
When I send a GET request to '/notifications'
Then the notifications should contain clear and understandable content
