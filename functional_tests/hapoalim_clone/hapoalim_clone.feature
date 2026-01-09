Feature: E-commerce Platform Functional Testing

  # UI Test Scenarios
  @ui
  Scenario Outline: User Registration and Account Creation
    Given I am on the registration page
    When I enter a valid email "<email>", password "<password>", and personal details "<details>"
    And I agree to the terms and conditions
    And I click the 'Register' button
    Then I should be redirected to the welcome page
    And I should receive a confirmation email

    Examples:
      | email           | password | details                |
      | user1@test.com  | Pass123! | John Doe, 123 Street   |
      | user2@test.com  | Pass456! | Jane Smith, 456 Avenue |

  @ui
  Scenario Outline: Product Search and Filtering
    Given I am on the homepage
    When I enter "<keyword>" in the search bar
    And I apply filters: category "<category>", price range "<price_range>", brand "<brand>"
    And I click the 'Search' button
    Then I should see search results filtered by the applied criteria

    Examples:
      | keyword  | category | price_range | brand    |
      | laptop   | electronics | 500-1000  | Dell     |
      | sneakers | footwear    | 50-100    | Nike     |

  @ui
  Scenario Outline: Checkout Process including Payment Gateway Integration
    Given I have items in my shopping cart
    When I click 'Proceed to Checkout'
    And I enter shipping details "<shipping_details>"
    And I select a payment method "<payment_method>" and enter payment details "<payment_details>"
    And I confirm the order
    Then the order should be processed successfully
    And I should receive a payment confirmation

    Examples:
      | shipping_details       | payment_method | payment_details       |
      | 123 Street, City       | Credit Card    | 4111 1111 1111 1111   |
      | 456 Avenue, Town       | PayPal         | user@paypal.com       |

  @ui
  Scenario Outline: Shopping Cart Management
    Given I am browsing products
    When I add a product "<product>" to the cart
    And I update the quantity to "<quantity>"
    And I remove the product from the cart
    Then the cart should reflect the correct total and updates

    Examples:
      | product  | quantity |
      | Laptop   | 2        |
      | Sneakers | 1        |

  @ui
  Scenario Outline: User Profile Management
    Given I am logged in and on the profile page
    When I update my personal details "<details>"
    And I save the changes
    Then my profile information should be updated successfully

    Examples:
      | details                  |
      | John Doe, 123 Street     |
      | Jane Smith, 456 Avenue   |

  # API Test Scenarios
  @api
  Scenario Outline: Role-based Access Control
    Given the API base URL is '<base_url>'
    And the authorization token is set for '<role>'
    When I attempt to access the admin dashboard
    Then the response status should be '<status>'
    And the response should indicate '<access>'

    Examples:
      | base_url       | role    | status | access         |
      | /api/dashboard | admin   | 200    | access granted |
      | /api/dashboard | regular | 403    | access denied  |

  @api
  Scenario Outline: Data Privacy and Security Compliance
    Given the API base URL is '<base_url>'
    And the system is configured with privacy compliance settings
    When I register a new user with "<user_data>"
    And attempt unauthorized access to another user's data
    Then the response status should be '<status>'
    And the response should indicate '<access>'

    Examples:
      | base_url       | user_data                        | status | access         |
      | /api/register  | {"email":"user1@test.com"}       | 403    | access denied  |

  @api
  Scenario Outline: Handling Payment Processing Failures
    Given the API base URL is '<base_url>'
    And I have items in my cart
    When I proceed to checkout with invalid payment details "<payment_details>"
    Then the response status should be '<status>'
    And the response should include an error message '<error_message>'

    Examples:
      | base_url       | payment_details      | status | error_message                  |
      | /api/checkout  | {"card":"invalid"}   | 400    | Invalid payment details        |

  @api
  Scenario Outline: Integration with External Systems
    Given the API base URL is '<base_url>'
    And the system is configured with external service integrations
    When I complete a transaction with "<transaction_data>"
    Then the response status should be '<status>'
    And the transaction logs should capture all interactions

    Examples:
      | base_url       | transaction_data                  | status |
      | /api/checkout  | {"items":["item1","item2"]}       | 200    |

  @api
  Scenario Outline: Boundary Value Analysis for Discounts
    Given the API base URL is '<base_url>'
    And I have items in my cart with a total "<total>"
    When I apply a discount code "<discount_code>"
    Then the response status should be '<status>'
    And the discount should be '<applied>'

    Examples:
      | base_url       | total | discount_code | status | applied          |
      | /api/discount  | 49.99 | SAVE10        | 200    | not applied      |
      | /api/discount  | 50.00 | SAVE10        | 200    | applied correctly |
