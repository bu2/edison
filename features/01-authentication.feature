Feature: Authentication
  Client applications need authentication before accessing APIs

  Scenario: Unauthenticated API access is forbidden
    Given client is not authenticated
    When client accepts JSON
    And client requests GET /api/*
    And client follows redirection
    Then response status should be 403
    And response body should be JSON:
      """
        { "status": "forbidden" }
      """

  Scenario: Authentication success
    When client requests POST /auth/developer/callback with form parameters: { name: 'Bob', email: 'bob@sponge.com' }
    Then response status should be 200
    And response body should be JSON:
      """
        { "status": "ok" }
      """

  Scenario: Authenticated API access success
    Given client is authenticated
    When client requests GET /api/*
    Then response status should be 200
