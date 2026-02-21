Feature: Testing API that interacts with the application

Scenario: Testing HTTP GET method
Given the API base URL 'http://localhost:3000'
When I send a GET request to '/endpoint'
Then the response status should be 200
And the response should contain 'expected details'

Scenario: Testing HTTP POST method
Given the API base URL 'http://localhost:3000'
And a payload 'payload details'
When I send a POST request to '/endpoint'
Then the response status should be 201
And the response should contain 'expected details'

Scenario: Testing HTTP PUT method
Given the API base URL 'http://localhost:3000'
And a payload 'payload details'
When I send a PUT request to '/endpoint'
Then the response status should be 200
And the response should contain 'expected details'

Scenario: Testing HTTP DELETE method
Given the API base URL 'http://localhost:3000'
When I send a DELETE request to '/endpoint'
Then the response status should be 204

Scenario: Testing HTTP GET method with incorrect endpoint
Given the API base URL 'http://localhost:3000'
When I send a GET request to '/incorrect-endpoint'
Then the response status should be 404

Scenario: Testing HTTP POST method with incorrect payload
Given the API base URL 'http://localhost:3000'
And an incorrect payload 'incorrect payload details'
When I send a POST request to '/endpoint'
Then the response status should be 400
