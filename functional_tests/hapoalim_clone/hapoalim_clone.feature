Feature: E-commerce Platform Functional Testing

  # UI Test Scenarios
  @ui
  Scenario Outline: User Registration with Valid Details
    Given I am on the registration page
    When I enter "<name>" as name, "<email>" as email, and "<password>" as password
    And I submit the registration form
    Then I should be redirected to the welcome page
    And I should receive a confirmation email

    Examples:
      | name    | email            | password  |
      | John Doe| john@example.com | password1 |
      | Jane Doe| jane@example.com | password2 |

  @ui
  Scenario Outline: Product Search and Filtering
    Given I am on the product search page
    When I enter "<keyword>" in the search bar
    And I apply filters for "<category>" and "<price_range>"
    Then I should see search results filtered by the applied criteria

    Examples:
      | keyword | category | price_range |
      | laptop  | electronics | $500-$1000 |
      | shoes   | fashion     | $50-$100   |

  @ui
  Scenario Outline: Shopping Cart Management
    Given I am logged in and on a product page
    When I add "<product>" to the cart
    And I view the cart
    Then the cart should contain "<product>"
    When I remove "<product>" from the cart
    Then the cart should not contain "<product>"

    Examples:
      | product    |
      | Laptop     |
      | Running Shoes |

  @ui
  Scenario Outline: Checkout Process with Valid Payment
    Given I have items in my cart
    When I proceed to checkout
    And I enter "<shipping_details>" as shipping details
    And I select "<payment_method>" as payment method
    And I complete the payment
    Then the order should be confirmed successfully

    Examples:
      | shipping_details | payment_method |
      | 123 Main St      | Credit Card    |
      | 456 Elm St       | PayPal         |

  @ui
  Scenario Outline: Order Confirmation and Notification
    Given I have completed an order
    When I check my email
    Then I should receive an order confirmation email
    When I check my order status in the user profile
    Then the order status should be updated

    Examples:
      | order_id |
      | 1001     |
      | 1002     |

  @ui
  Scenario Outline: User Profile Management
    Given I am logged in and on my profile page
    When I update my "<field>" to "<new_value>"
    And I save the changes
    Then my profile should be updated with "<new_value>"

    Examples:
      | field   | new_value        |
      | name    | John Smith       |
      | email   | john.smith@example.com |
      | password| newpassword123   |

  @ui
  Scenario Outline: Role-based Access Control
    Given I am logged in as "<role>"
    When I attempt to access the admin dashboard
    Then I should "<access_result>"

    Examples:
      | role   | access_result         |
      | admin  | be able to access     |
      | user   | not be able to access |

  @ui
  Scenario Outline: Invalid Promotional Code Handling
    Given I have items in my cart
    When I proceed to checkout
    And I enter "<promo_code>" as the promo code
    And I attempt to apply the code
    Then I should see an error message indicating the promo code is "<error_message>"

    Examples:
      | promo_code | error_message          |
      | INVALID123 | invalid or expired     |
      | EXPIRED456 | invalid or expired     |

  @ui
  Scenario Outline: Cross-Device Compatibility
    Given I access the platform on a "<device>"
    When I perform a product search and add items to the cart
    Then the platform should display and function correctly

    Examples:
      | device  |
      | mobile  |
      | tablet  |
      | desktop |

  # API Test Scenarios
  @api
  Scenario Outline: Secure Payment Processing
    Given the API base URL is "<base_url>"
    And the authorization token is set
    When I send a POST request to "<endpoint>" with payload:
      """
      {
        "payment_method": "<payment_method>",
        "amount": "<amount>"
      }
      """
    Then the response status should be 200
    And the response should contain "transaction_id"

    Examples:
      | base_url      | endpoint            | payment_method | amount |
      | https://api.example.com | /api/payments | Credit Card   | 100.00 |
      | https://api.example.com | /api/payments | PayPal        | 50.00  |

  @api
  Scenario Outline: Order Status Transition
    Given the API base URL is "<base_url>"
    And the authorization token is set
    When I send a PUT request to "<endpoint>" with payload:
      """
      {
        "order_id": "<order_id>",
        "status": "<new_status>"
      }
      """
    Then the response status should be 200
    And the response should contain "<new_status>"

    Examples:
      | base_url      | endpoint               | order_id | new_status |
      | https://api.example.com | /api/orders/status | 1001    | Confirmed  |
      | https://api.example.com | /api/orders/status | 1002    | Shipped    |
      | https://api.example.com | /api/orders/status | 1003    | Delivered  |

  @api
  Scenario Outline: Data Privacy and Security Compliance
    Given the API base URL is "<base_url>"
    And the authorization token is set
    When I perform a transaction involving PII
    Then the data should be encrypted during transmission and storage

    Examples:
      | base_url      |
      | https://api.example.com |
