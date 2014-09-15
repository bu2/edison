Feature: RESTfulness
  The backend provides RESTfull APIs to handle any JSON object

  Scenario: Adding one object
    Given client is authenticated
    When client requests POST /api/buildings with JSON parameter:
      """
        { "label": "Town Hall", "level": 3, "elixir_storage": 398, "elixir_storage_max": 1000, "gold_storage": 236, "gold_storage_max": 1000, "health": 1850, "health_max": 1850 }
      """
    Then response status should be 200
    And the JSON response should have "id"

  Scenario: Getting one object
    Given client is authenticated
    Then TBD
