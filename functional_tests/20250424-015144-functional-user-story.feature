Feature: Testing API for Login Functionality

Scenario: Testing HTTP POST method for valid login
Given the API base URL 'http://localhost:3000' 
When I send a POST request to '/login' with valid 'username' and 'password'
Then the response status should be 200
And the response should contain 'Login Successful'
And the user should be logged in

Scenario: Testing HTTP POST method for invalid login
Given the API base URL 'http://localhost:3000' 
When I send a POST request to '/login' with invalid 'username' and 'password'
Then the response status should be 401
And the response should contain 'Invalid Credentials'
And the user should not be logged in

Scenario: Testing HTTP POST method for login with special characters
Given the API base URL 'http://localhost:3000' 
When I send a POST request to '/login' with 'username' and 'password' containing special characters
Then the response status should be 400
And the response should contain 'Invalid Input'
And the user should not be logged in

Feature: Testing API for System Performance

Scenario: Testing system performance under high load
Given the API base URL 'http://localhost:3000' 
When I simulate high number of users sending POST requests to '/login' at the same time
Then the system should handle the load without crashing
And maintain acceptable response time

Feature: Testing API for System Security

Scenario: Testing system security by attempting SQL injection in the login form
Given the API base URL 'http://localhost:3000' 
When I send a POST request to '/login' with SQL injection strings in the 'username' and 'password' fields
Then the response status should be 400
And the system should not be vulnerable to SQL injection
And the response should contain 'Invalid Input'

Scenario: Testing system security by attempting SQL injection with long strings in the login form
Given the API base URL 'http://localhost:3000' 
When I send a POST request to '/login' with extremely long SQL injection strings in the 'username' and 'password' fields
Then the response status should be 400
And the system should not be vulnerable to SQL injection
And the system should handle it without crashing
