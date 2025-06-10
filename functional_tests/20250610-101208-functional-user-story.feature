Feature: Testing API for Login, Search, Signup, Load Time, Peak Load and Security

  Scenario: Testing Login functionality
    Given the API base URL 'http://localhost:3000'
    When I send a POST request to '/login' with body '{"username": "validUsername", "password": "validPassword"}'
    Then the response status should be 200
    And the response should contain 'User logged in successfully'
    But when I send a POST request to '/login' with body '{"username": "invalidUsername", "password": "invalidPassword"}'
    Then the response status should be 401
    And the response should contain 'Invalid credentials'

  Scenario: Testing Search functionality
    Given the API base URL 'http://localhost:3000'
    When I send a GET request to '/search?keyword=validKeyword'
    Then the response status should be 200
    And the response should contain 'Relevant results'
    But when I send a GET request to '/search?keyword=invalidKeyword'
    Then the response status should be 404
    And the response should contain 'No results found'

  Scenario: Testing Signup functionality
    Given the API base URL 'http://localhost:3000'
    When I send a POST request to '/signup' with body '{"email": "newEmail", "password": "newPassword"}'
    Then the response status should be 201
    And the response should contain 'User registered successfully'
    But when I send a POST request to '/signup' with body '{"email": "existingEmail", "password": "anyPassword"}'
    Then the response status should be 409
    And the response should contain 'Email already registered'

  Scenario: Testing Load Time
    Given the API base URL 'http://localhost:3000'
    When I send a GET request to '/'
    Then the response time should be less than 2000 milliseconds

  Scenario: Testing Peak Load
    Given the API base URL 'http://localhost:3000'
    When I simulate peak load using a load testing tool
    Then the application should function properly without any crashes or slowdowns

  Scenario: Testing Security
    Given the API base URL 'http://localhost:3000'
    When I send a GET request to '/restrictedArea' without proper authentication
    Then the response status should be 403
    And the response should contain 'Access denied'
