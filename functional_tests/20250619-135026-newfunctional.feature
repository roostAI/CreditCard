Feature: Credit Card Management API Testing

Scenario: Credit Card Due Reminder
  Given the API base URL 'http://api.creditcard.com'
  And the credit card due date is '01/12/2022'
  When I send a GET request to '/reminders?dueDate=01/12/2022'
  Then the response status should be 200
  And the response should contain a reminder date of '30/11/2022'
  And the reminder should be sent even if '01/12/2022' is a holiday

Scenario: Overdue Balance Alert
  Given the API base URL 'http://api.creditcard.com'
  And the current date is '02/12/2022'
  And the payment due date was '01/12/2022'
  When I send a GET request to '/alerts?currentDate=02/12/2022'
  Then the response status should be 200
  And the response should contain an alert sent on '02/12/2022'

Scenario: Collection Notification
  Given the API base URL 'http://api.creditcard.com'
  And the account is significantly delinquent
  When I send a GET request to '/notifications?accountStatus=delinquent'
  Then the response status should be 200
  And the response should contain a collection notification with the amount owed and additional charges
  And ensure no notices are sent to accounts just days past due

Scenario: Payment Plan Proposal
  Given the API base URL 'http://api.creditcard.com'
  And the user informs about inability to pay
  When I send a POST request to '/payment-plan' with payload '{ "userStatus": "unable to pay" }'
  Then the response status should be 200
  And the response should contain a payment plan proposal with reduced interest rates or fees
  And ensure this feature is not triggered for users in good standing or with minor delinquency

Scenario: Collection Agency Involvement
  Given the API base URL 'http://api.creditcard.com'
  And the cardholder fails to respond to previous notifications and reminders
  When I send a GET request to '/collection-agency?responseStatus=unresponsive'
  Then the response status should be 200
  And the response should indicate collection agency involvement
  And ensure the involvement threshold is accurate, not just a few days after the payment due date

Scenario: Legal Action Initiation
  Given the API base URL 'http://api.creditcard.com'
  And there are extreme cases of non-payment or default
  When I send a GET request to '/legal-action?caseStatus=extreme'
  Then the response status should be 200
  And the response should indicate legal action initiation
  And ensure a rigorous confirmation procedure is followed before initiating legal action

Scenario: Performance Testing
  Given the API base URL 'http://api.creditcard.com'
  When I simulate sending notifications to all users
  Then the system should handle the load efficiently
  And the alert system should work swiftly and promptly even with thousands of cardholders

Scenario: Usability Testing
  Given the API base URL 'http://api.creditcard.com'
  When I review the notification messages
  Then the messages should be clear and understandable to the cardholders

Scenario: Security Testing
  Given the API base URL 'http://api.creditcard.com'
  When I interact with the system
  Then sensitive cardholder data should be protected

Scenario: Compatibility Testing
  Given the API base URL 'http://api.creditcard.com'
  When I send notifications across different device types
  Then the notifications should be delivered effectively to PCs, mobile phones, and tablets

Scenario: Recovery Testing
  Given the API base URL 'http://api.creditcard.com'
  When the system experiences crashes or hardware failures
  Then the system should recover without losing any critical data

Scenario: Reliability Testing
  Given the API base URL 'http://api.creditcard.com'
  When the system performs its functions continuously
  Then it should do so without any disruption for a long period of time
