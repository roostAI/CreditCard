Feature: Portfolio Rebalancing API

  Background:
    Given the API server is running
    And I am authenticated as a valid user

  Scenario: Retrieve portfolio composition
    When I send a GET request to "/api/portfolio/composition"
    Then the response status code should be 200
    And the response should contain the following asset types:
      | Asset Type    |
      | Stock         |
      | Liquid funds  |
      | Commodities   |
      | Real Estate   |
    And each asset type should have a percentage value

  Scenario Outline: Detect asset concentration and suggest rebalancing
    Given the current portfolio composition is:
      | Asset Type    | Percentage |
      | Stock         | <Stock>    |
      | Liquid funds  | <Liquid>   |
      | Commodities   | <Commod>   |
      | Real Estate   | <RealEst>  |
    When I send a GET request to "/api/portfolio/rebalance-suggestions"
    Then the response status code should be 200
    And the response should suggest selling "<OverRepresented>" asset
    And the response should suggest buying "<UnderRepresented>" asset

    Examples:
      | Stock | Liquid | Commod | RealEst | OverRepresented | UnderRepresented |
      | 55    | 15     | 15     | 15      | Stock           | Liquid funds     |
      | 40    | 10     | 35     | 15      | Commodities     | Real Estate      |
      | 30    | 10     | 25     | 35      | Real Estate     | Stock            |

  Scenario: Detect poor representation and suggest rebalancing
    Given the current portfolio composition is:
      | Asset Type    | Percentage |
      | Stock         | 45         |
      | Liquid funds  | 8          |
      | Commodities   | 25         |
      | Real Estate   | 22         |
    When I send a GET request to "/api/portfolio/rebalance-suggestions"
    Then the response status code should be 200
    And the response should suggest buying "Liquid funds" asset
    And the response should suggest selling "Stock" asset

  Scenario: Handle multiple rebalancing conditions
    Given the current portfolio composition is:
      | Asset Type    | Percentage |
      | Stock         | 60         |
      | Liquid funds  | 5          |
      | Commodities   | 20         |
      | Real Estate   | 15         |
    When I send a GET request to "/api/portfolio/rebalance-suggestions"
    Then the response status code should be 200
    And the response should suggest selling "Stock" asset
    And the response should suggest buying "Liquid funds" asset

  Scenario: Execute rebalancing transactions
    Given the current portfolio requires rebalancing
    When I send a POST request to "/api/transaction/sell" with the following data:
      | Asset Type | Amount |
      | Stock      | 10000  |
    Then the response status code should be 200
    And the response should confirm the sale of "Stock"
    When I send a POST request to "/api/transaction/buy" with the following data:
      | Asset Type   | Amount |
      | Liquid funds | 10000  |
    Then the response status code should be 200
    And the response should confirm the purchase of "Liquid funds"

  Scenario: Handle edge case with all assets at threshold
    Given the current portfolio composition is:
      | Asset Type    | Percentage |
      | Stock         | 50         |
      | Liquid funds  | 16.67      |
      | Commodities   | 16.67      |
      | Real Estate   | 16.66      |
    When I send a GET request to "/api/portfolio/rebalance-suggestions"
    Then the response status code should be 200
    And the response should not suggest any rebalancing actions

  Scenario: Performance test for portfolio composition retrieval
    When I send 100 concurrent GET requests to "/api/portfolio/composition"
    Then all responses should have a status code of 200
    And the average response time should be less than 500 milliseconds

  Scenario: Security test for authentication
    When I send a GET request to "/api/portfolio/composition" without authentication
    Then the response status code should be 401
