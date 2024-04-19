# ********RoostGPT********

# Test generated by RoostGPT for test CrediCard-Karate using AI Type Claude AI and AI Model claude-3-opus-20240229
# 
# Feature file generated for /balance-alert_post for http method type POST 
# RoostTestHash=a82c31e55f
# 
# 

# ********RoostGPT********
Feature: Balance Alert API

Background:
    * def urlBase = karate.properties['url.base'] || karate.get('urlBase', 'http://localhost:8080')
    * url urlBase
    * configure headers = { 'Authorization': 'Bearer ' + karate.properties['AUTH_TOKEN'] }

Scenario Outline: Test Balance Alert API with valid request
    Given path '/balance-alert'
    And request
        """
        {
            "paymentDueDate": "<paymentDueDate>",
            "currentDate": "<currentDate>",
            "cardLast4": "<cardLast4>"
        }
        """
    When method POST
    Then status 200
    And match response == "<expectedResponse>"

    Examples:
        | paymentDueDate | currentDate | cardLast4 | expectedResponse                                   |
        | 2023-06-30     | 2023-06-15  | 1234      | "Payment due in 15 days for card ending in 1234"  |
        | 2023-07-01     | 2023-06-30  | 5678      | "Payment due tomorrow for card ending in 5678"    |
        | 2023-06-15     | 2023-06-15  | 9012      | "Payment due today for card ending in 9012"       |

Scenario: Test Balance Alert API with missing required fields
    Given path '/balance-alert'
    And request
        """
        {
            "paymentDueDate": "2023-06-30"
        }
        """
    When method POST
    Then status 400
    And match response contains "Missing required fields"

Scenario: Test Balance Alert API with invalid date format
    Given path '/balance-alert'
    And request
        """
        {
            "paymentDueDate": "2023/06/30",
            "currentDate": "2023-06-15",
            "cardLast4": "1234"
        }
        """
    When method POST
    Then status 400
    And match response contains "Invalid date format"

Scenario: Test Balance Alert API with invalid card last 4 digits
    Given path '/balance-alert'
    And request
        """
        {
            "paymentDueDate": "2023-06-30",
            "currentDate": "2023-06-15",
            "cardLast4": "123"
        }
        """
    When method POST
    Then status 400
    And match response contains "Invalid card last 4 digits"
