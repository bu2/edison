Feature: Say Hello World!
  Say Hello World!

  Scenario: Say Hello World!
    When client accepts JSON
    And client requests GET /
    Then response status should be 200
    And response body should be JSON:
      """
        {"status": "Hello World!"}
      """