Feature: Credit Card Management System API Testing

  Scenario: Valid Credit Card Detail Verification
  Given the API base URL 'http://localhost:3000' 
  And a valid credit card number as '1234567890' 
  When I send a GET request to '/credit-card-api/details'
  Then the response status should be 200
  And the response should contain 'due date' and 'balance'

  Scenario: Invalid Credit Card Detail Verification
  Given the API base URL 'http://localhost:3000'
  And an invalid credit card number as 'XYZABC'
  When I send a GET request to '/credit-card-api/details'
  Then the response status should be 400
  And the response should contain 'Invalid card number'

  Scenario: Overdue Payment Alert
  Given the API base URL 'http://localhost:3000'
  And a credit card number with overdue payment as '1234567890'
  When I send a POST request to '/credit-card-api/alerts'
  Then the response status should be 200
  And the response should contain 'Call initiated'

  Scenario: Payment Collection and Balance Updating
  Given the API base URL 'http://localhost:3000'
  And the payment information as '{ "CardNumber": "1234567890", "Amount": "1000" }'
  When I send a POST request to '/credit-card-api/payments'
  Then the response status should be 200
  And the response should contain 'Payment successful' and 'Balance updated'

  Scenario: Performance Testing
  Given the API base URL 'http://localhost:3000'
  And a set of 100 valid credit card numbers
  When I send a GET request to '/credit-card-api/details' for each credit card number
  Then the average response time should be less than '2' seconds

  Scenario: Security Testing
  Given the API base URL 'http://localhost:3000'
  And a valid credit card number as '1234567890'
  When I attempt unauthorized access to '/credit-card-api/details'
  Then the response status should be 401
  And the response should contain 'Access denied'

  Scenario: Load Testing
  Given the API base URL 'http://localhost:3000'
  And a set of 1000 valid credit card numbers
  When I send a GET request to '/credit-card-api/details' for each credit card number concurrently
  Then the response status for all requests should be 200
  And none of the requests should timeout

  Scenario: Compatibility Testing
  Given the API base URL 'http://localhost:3000'
  When I send a GET request to '/credit-card-api/details' from various operating systems and web browsers
  Then the response status should be 200
  And the response should contain 'due date' and 'balance'
