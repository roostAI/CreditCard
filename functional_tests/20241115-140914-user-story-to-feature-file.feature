Feature: Portfolio Rebalancing API

  Background:
    Given the API server is running
    And I am an authenticated user

  Scenario: Retrieve portfolio composition
    When I send a GET request to "/api/portfolio/composition"
    Then the response status code should be 200
    And the response should contain asset types "Stock", "Liquid funds", "Commodities", and "Real Estate"
    And each asset type should have a "percentage" field

  Scenario Outline: Detect asset concentration exceeding limits
    When I send a GET request to "/api/portfolio/composition"
    Then the response status code should be 200
    And the "<asset_type>" percentage should be greater than <limit>
    And the response should include a suggestion to rebalance the portfolio
    And the suggestion should recommend selling "<asset_type>"

    Examples:
      | asset_type  | limit |
      | Stock       | 50    |
      | Commodities | 30    |
      | Real Estate | 30    |

  Scenario: Detect poor representation of an asset
    When I send a GET request to "/api/portfolio/composition"
    Then the response status code should be 200
    And at least one asset type should have a percentage less than 10
    And the response should include a suggestion to rebalance the portfolio
    And the suggestion should recommend buying the underrepresented asset

  Scenario: Suggest rebalancing for multiple imbalanced assets
    When I send a GET request to "/api/portfolio/composition"
    Then the response status code should be 200
    And multiple asset types should be out of balance
    And the response should include suggestions to rebalance the portfolio
    And the suggestions should recommend selling overrepresented assets
    And the suggestions should recommend buying underrepresented assets

  Scenario: No rebalancing needed for balanced portfolio
    When I send a GET request to "/api/portfolio/composition"
    Then the response status code should be 200
    And all asset types should be within their designated limits
    And the response should not include any rebalancing suggestions

  Scenario: Sell overrepresented asset
    Given the portfolio has an overrepresented asset "Stock"
    When I send a POST request to "/api/transaction/sell" with the following payload:
      """
      {
        "asset_type": "Stock",
        "amount": 1000
      }
      """
    Then the response status code should be 200
    And the response should confirm the sale of "Stock"
    And the updated portfolio composition should show a reduced percentage for "Stock"

  Scenario: Buy underrepresented asset
    Given the portfolio has an underrepresented asset "Liquid funds"
    When I send a POST request to "/api/transaction/buy" with the following payload:
      """
      {
        "asset_type": "Liquid funds",
        "amount": 1000
      }
      """
    Then the response status code should be 200
    And the response should confirm the purchase of "Liquid funds"
    And the updated portfolio composition should show an increased percentage for "Liquid funds"

  Scenario: Performance test for portfolio composition retrieval
    When I send 100 concurrent GET requests to "/api/portfolio/composition"
    Then all responses should have a status code of 200
    And the average response time should be less than 500 milliseconds

  Scenario: Security test for authentication
    When I send a GET request to "/api/portfolio/composition" without authentication
    Then the response status code should be 401

  Scenario: Verify transaction logging
    When I send a POST request to "/api/transaction/sell" with a valid payload
    Then the response status code should be 200
    And the transaction should be logged in the system for auditing purposes

  Scenario: Test API server unavailability
    Given the API server is temporarily unavailable
    When I send a GET request to "/api/portfolio/composition"
    Then the response status code should be 503
    And the response should include a meaningful error message

  Scenario: Verify precision of percentage calculations
    When I send a GET request to "/api/portfolio/composition"
    Then the response status code should be 200
    And the sum of all asset percentages should be exactly 100%
    And each percentage should be rounded to 2 decimal places
