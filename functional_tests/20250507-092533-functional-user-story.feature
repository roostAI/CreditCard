Feature: Testing API for a Web Application

Scenario: Testing HTTP POST method for login functionality
Given the API base URL 'http://localhost:3000' 
When I send a POST request to '/login' with valid 'username' and 'password'
Then the response status should be 200
And the response should contain 'login successful'
But when I send a POST request to '/login' with invalid 'username' and 'password'
Then the response status should be 401
And the response should contain 'login failed'

Scenario: Testing HTTP GET method for search functionality
Given the API base URL 'http://localhost:3000' 
When I send a GET request to '/search' with valid 'keyword'
Then the response status should be 200
And the response should contain 'relevant search results'
But when I send a GET request to '/search' with invalid 'keyword'
Then the response status should be 404
And the response should contain 'no results found'

Scenario: Testing HTTP POST method for sign-up functionality
Given the API base URL 'http://localhost:3000' 
When I send a POST request to '/signup' with valid 'user details'
Then the response status should be 200
And the response should contain 'signup successful'
But when I send a POST request to '/signup' with already existing 'user details'
Then the response status should be 409
And the response should contain 'user already exists'

Scenario: Testing system performance under load
Given the API base URL 'http://localhost:3000' 
When I simulate 1000 concurrent users
Then the system should handle the load without any downtime or significant performance degradation

Scenario: Testing system security
Given the API base URL 'http://localhost:3000' 
When I try to access the system without login
Then the response status should be 401
And the response should contain 'unauthorized access'

Scenario: Testing system usability
Given the API base URL 'http://localhost:3000' 
When I navigate through different pages of the system
Then the system should be user-friendly and easy to navigate
