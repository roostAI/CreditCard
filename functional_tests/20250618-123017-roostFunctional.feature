Feature: API Testing for User Management System

Scenario: Successful User Registration
  Given the API base URL 'http://localhost:3000'
  And the endpoint '/register'
  And the request payload is
    """
    {
      "username": "newuser",
      "password": "securepassword",
      "email": "newuser@example.com"
    }
    """
  When I send a POST request to '/register' with the payload
  Then the response status should be 201
  And the response body should contain 'User registered successfully'

Scenario: User Registration with Existing Email
  Given the API base URL 'http://localhost:3000'
  And the endpoint '/register'
  And the request payload is
    """
    {
      "username": "anotheruser",
      "password": "anotherpassword",
      "email": "existinguser@example.com"
    }
    """
  When I send a POST request to '/register' with the payload
  Then the response status should be 409
  And the response body should contain 'Email already exists'

Scenario: Successful User Login
  Given the API base URL 'http://localhost:3000'
  And the endpoint '/login'
  And the request payload is
    """
    {
      "username": "existinguser",
      "password": "correctpassword"
    }
    """
  When I send a POST request to '/login' with the payload
  Then the response status should be 200
  And the response body should contain 'Login successful'

Scenario: User Login with Incorrect Password
  Given the API base URL 'http://localhost:3000'
  And the endpoint '/login'
  And the request payload is
    """
    {
      "username": "existinguser",
      "password": "wrongpassword"
    }
    """
  When I send a POST request to '/login' with the payload
  Then the response status should be 401
  And the response body should contain 'Invalid credentials'

Scenario: Fetch User Profile
  Given the API base URL 'http://localhost:3000'
  And the endpoint '/user/profile'
  And the user is authenticated with token 'validtoken'
  When I send a GET request to '/user/profile' with the token
  Then the response status should be 200
  And the response body should contain 'user profile details'

Scenario: Update User Profile
  Given the API base URL 'http://localhost:3000'
  And the endpoint '/user/profile'
  And the user is authenticated with token 'validtoken'
  And the request payload is
    """
    {
      "email": "updateduser@example.com",
      "name": "Updated User"
    }
    """
  When I send a PUT request to '/user/profile' with the payload and token
  Then the response status should be 200
  And the response body should contain 'Profile updated successfully'

Scenario: Delete User Account
  Given the API base URL 'http://localhost:3000'
  And the endpoint '/user/delete'
  And the user is authenticated with token 'validtoken'
  When I send a DELETE request to '/user/delete' with the token
  Then the response status should be 200
  And the response body should contain 'User account deleted successfully'
