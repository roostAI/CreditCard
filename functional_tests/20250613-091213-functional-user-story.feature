Feature: Testing API that interacts with File System
  Scenario: Testing HTTP GET method to open a file
  Given the API base URL 'http://localhost:3000' 
  And a file path '/var/tmp/Roost/RoostGPT/functional-user-story/da25d31b-332d-49f7-a93d-204a42db960c/roost_user_input.txt'
  When I send a GET request to '/open-file'
  Then the response status should be 200
  And the response should contain 'File opened successfully'
  But if the file does not exist, the response status should be 404
  And the response should contain 'File not found'

  Scenario: Testing HTTP GET method to read a file
  Given the API base URL 'http://localhost:3000' 
  And a file path '/var/tmp/Roost/RoostGPT/functional-user-story/da25d31b-332d-49f7-a93d-204a42db960c/roost_user_input.txt'
  When I send a GET request to '/read-file'
  Then the response status should be 200
  And the response should contain the content of the file
  But if the file is empty, the response should contain 'File is empty'

  Scenario: Testing HTTP GET method to measure response time when opening a file
  Given the API base URL 'http://localhost:3000' 
  And a file path '/var/tmp/Roost/RoostGPT/functional-user-story/da25d31b-332d-49f7-a93d-204a42db960c/roost_user_input.txt'
  When I send a GET request to '/open-file'
  Then the response time should be less than 2 seconds

  Scenario: Testing HTTP GET method to handle multiple requests
  Given the API base URL 'http://localhost:3000' 
  And a file path '/var/tmp/Roost/RoostGPT/functional-user-story/da25d31b-332d-49f7-a93d-204a42db960c/roost_user_input.txt'
  When multiple users send a GET request to '/open-file' simultaneously
  Then the system should handle all requests without crashing
  And the response time for each request should be less than 2 seconds
