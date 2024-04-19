# ********RoostGPT********

# Test generated by RoostGPT for test CrediCard-Karate using AI Type Claude AI and AI Model claude-3-opus-20240229
# 
# Feature file generated for /notifications_get for http method type GET 
# RoostTestHash=31e4f43d4d
# 
# 

# ********RoostGPT********
Feature: Notifications API

Background:
    * def urlBase = karate.properties['url.base'] || karate.get('urlBase', 'http://localhost:8080')
    * url urlBase
    * configure headers = { 'Authorization': #(karate.properties['AUTH_TOKEN']) }

Scenario: Get notifications
    Given path '/notifications'
    When method GET
    Then status 200
    And match response == 
        """
        {
            type: 'object'
        }
        """
    And match responseHeaders['Content-Type'] contains 'application/json'
