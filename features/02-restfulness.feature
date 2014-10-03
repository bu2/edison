Feature: RESTfulness
  The backend provides RESTfull APIs to handle any JSON object

  Background:
    Given client is authenticated
    And client accepts JSON

  Scenario: Adding one object
    When client requests POST /api/buildings with JSON:
    """
    { "label": "Town Hall",
    "level": 3,
    "elixir_storage": 398,
    "elixir_storage_max": 1000,
    "gold_storage": 236,
    "gold_storage_max": 1000,
    "health": 1850,
    "health_max": 1850 }
    """
    Then response status should be 200
    And the JSON response should have "id"

  Scenario: Getting one object
    Given the system knows this Building JSON:
    """
    { "_id" : "541816f042e7d8204d000001",
    "label" : "Town Hall",
    "level" : 3,
    "elixir_storage" : 398,
    "elixir_storage_max" : 1000,
    "gold_storage" : 236,
    "gold_storage_max" : 1000,
    "health" : 1850,
    "health_max" : 1850,
    "_owner" : "bob@sponge.com" }
    """
    When client requests GET /api/buildings/541816f042e7d8204d000001
    Then response status should be 200
    And response body should be JSON:
    """
    { "_id" : "541816f042e7d8204d000001",
    "label" : "Town Hall",
    "level" : 3,
    "elixir_storage" : 398,
    "elixir_storage_max" : 1000,
    "gold_storage" : 236,
    "gold_storage_max" : 1000,
    "health" : 1850,
    "health_max" : 1850,
    "_owner" : "bob@sponge.com" }
    """

  Scenario: Overriding an object (replacing while keeping the '_id')
    Given the system knows those Buildings:
    | _id                      | label     | level | _owner         |
    | 541816f042e7d8204d000001 | Town Hall |     3 | bob@sponge.com |
    | 541816f042e7d8204d000002 | Army Camp |     3 | bob@sponge.com |
    | 541816f042e7d8204d000003 | Gold Mine |     3 | bob@sponge.com |
    When client requests PUT /api/buildings/541816f042e7d8204d000001 with JSON:
    """
    { "label": "Clan Castle",
    "level": 1 }
    """
    Then response status should be 200
    And response body should be JSON:
    """
    { "status": "ok" }
    """
    And Building with id "541816f042e7d8204d000001" should be JSON:
    """
    { "_id": { "$oid": "541816f042e7d8204d000001" },
    "label": "Clan Castle",
    "level": 1,
    "_owner": "bob@sponge.com" }
    """

  Scenario: Mutating an object
    Given the system knows those Buildings:
    | _id                      | label     | level | _owner         |
    | 541816f042e7d8204d000001 | Town Hall |     3 | bob@sponge.com |
    | 541816f042e7d8204d000002 | Army Camp |     3 | bob@sponge.com |
    | 541816f042e7d8204d000003 | Gold Mine |     3 | bob@sponge.com |
    When client requests PATCH /api/buildings/541816f042e7d8204d000001 with JSON:
    """
    { "level": 5,
    "elixir_storage" : 9999,
    "elixir_storage_max" : 9999,
    "gold_storage" : 9999,
    "gold_storage_max" : 9999,
    "health" : 9999,
    "health_max" : 9999}
    """
    Then response status should be 200
    And response body should be JSON:
    """
    { "status": "ok" }
    """
    And Building with id "541816f042e7d8204d000001" should be JSON:
    """
    { "_id": { "$oid": "541816f042e7d8204d000001" },
    "label": "Town Hall",
    "level": 5,
    "elixir_storage" : 9999,
    "elixir_storage_max" : 9999,
    "gold_storage" : 9999,
    "gold_storage_max" : 9999,
    "health" : 9999,
    "health_max" : 9999,
    "_owner": "bob@sponge.com" }
    """

  Scenario: Deleting one object
    Given the system knows this Building JSON:
    """
    { "_id" : "541816f042e7d8204d000001",
    "label" : "Town Hall",
    "level" : 3,
    "elixir_storage" : 398,
    "elixir_storage_max" : 1000,
    "gold_storage" : 236,
    "gold_storage_max" : 1000,
    "health" : 1850,
    "health_max" : 1850,
    "_owner" : "bob@sponge.com" }
    """
    When client requests DELETE /api/buildings/541816f042e7d8204d000001
    Then response status should be 200
    And response body should be JSON:
    """
    { "status": "ok" }
    """
    When client requests GET /api/buildings/541816f042e7d8204d000001
    Then response status should be 422
    And response body should be JSON:
    """
    { "status": "Unprocessable Entity",
      "message": "Object with _id 541816f042e7d8204d000001 not found." }
    """

  Scenario: Getting the list of objects
    Given the system only knows those Buildings:
    | _id                      | label     | level | _owner         |
    | 541816f042e7d8204d000001 | Town Hall |     3 | bob@sponge.com |
    | 541816f042e7d8204d000002 | Army Camp |     3 | bob@sponge.com |
    | 541816f042e7d8204d000003 | Gold Mine |     3 | bob@sponge.com |
    When client requests GET /api/buildings
    Then response status should be 200
    And response body should be JSON:
    """
    [ { "_id" : "541816f042e7d8204d000001", "label" : "Town Hall", "level" : 3, "_owner" : "bob@sponge.com" },
    { "_id" : "541816f042e7d8204d000002", "label" : "Army Camp", "level" : 3, "_owner" : "bob@sponge.com" },
    { "_id" : "541816f042e7d8204d000003", "label" : "Gold Mine", "level" : 3, "_owner" : "bob@sponge.com" } ]
    """
