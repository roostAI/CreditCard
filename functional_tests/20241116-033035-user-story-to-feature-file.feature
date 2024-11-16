Feature: Portfolio Rebalancing Suggestion System

  Background:
    Given the API server is running
    And I am an authenticated user

  Scenario: Retrieve portfolio composition
    When I send a GET request to "/api/portfolio/composition"
    Then the response status code should be 200
    And the response should contain asset types "Stock, Liquid funds, Commodities, Real Estate"
    And each asset type should have a percentage value

  Scenario Outline: Detect asset concentration and suggest rebalancing
    Given the portfolio composition is:
      | Asset         | Percentage |
      | Stock         | <stock>    |
      | Liquid funds  | <liquid>   |
      | Commodities   | <comm>     |
      | Real Estate   | <real>     |
    When I send a GET request to "/api/portfolio/analyze"
    Then the response status code should be 200
    And the response should suggest rebalancing
    And the response should suggest selling "<sell_asset>"
    And the response should suggest buying "<buy_asset>"

    Examples:
      | stock | liquid | comm  | real  | sell_asset | buy_asset    |
      | 55    | 15     | 15    | 15    | Stock      | Liquid funds |
      | 40    | 10     | 35    | 15    | Commodities| Liquid funds |
      | 40    | 10     | 15    | 35    | Real Estate| Liquid funds |

  Scenario: Detect poor representation and suggest rebalancing
    Given the portfolio composition is:
      | Asset         | Percentage |
      | Stock         | 45         |
      | Liquid funds  | 5          |
      | Commodities   | 25         |
      | Real Estate   | 25         |
    When I send a GET request to "/api/portfolio/analyze"
    Then the response status code should be 200
    And the response should suggest rebalancing
    And the response should suggest buying "Liquid funds"
    And the response should suggest selling "Stock"

  Scenario: No rebalancing needed for a balanced portfolio
    Given the portfolio composition is:
      | Asset         | Percentage |
      | Stock         | 40         |
      | Liquid funds  | 20         |
      | Commodities   | 20         |
      | Real Estate   | 20         |
    When I send a GET request to "/api/portfolio/analyze"
    Then the response status code should be 200
    And the response should not suggest rebalancing

  Scenario: Sell overrepresented asset
    Given the portfolio composition shows Stock at 60%
    When I send a POST request to "/api/transaction/sell" with payload:
      """
      {
        "asset": "Stock",
        "amount": 100000
      }
      """
    Then the response status code should be 200
    And the response should confirm the transaction
    And the updated portfolio composition should show Stock below 50%

  Scenario: Buy underrepresented asset
    Given the portfolio composition shows Liquid funds at 5%
    When I send a POST request to "/api/transaction/buy" with payload:
      """
      {
        "asset": "Liquid funds",
        "amount": 50000
      }
      """
    Then the response status code should be 200
    And the response should confirm the transaction
    And the updated portfolio composition should show Liquid funds above 10%

  Scenario: Handle multiple overrepresented assets
    Given the portfolio composition is:
      | Asset         | Percentage |
      | Stock         | 55         |
      | Liquid funds  | 5          |
      | Commodities   | 35         |
      | Real Estate   | 5          |
    When I send a GET request to "/api/portfolio/analyze"
    Then the response status code should be 200
    And the response should suggest rebalancing
    And the response should suggest selling "Stock" and "Commodities"
    And the response should suggest buying "Liquid funds" and "Real Estate"

  Scenario: Performance test for portfolio composition API
    Given the system has 1000 concurrent users
    When each user sends a GET request to "/api/portfolio/composition"
    Then all responses should be received within 2 seconds
    And the response status code should be 200 for all requests

  Scenario: Security test for authentication
    When I send a GET request to "/api/portfolio/composition" without authentication
    Then the response status code should be 401

  Scenario: Test for large portfolio values
    Given I have a portfolio with total value of 100000000
    When I send a GET request to "/api/portfolio/composition"
    Then the response status code should be 200
    And the response should contain accurate percentage calculations
