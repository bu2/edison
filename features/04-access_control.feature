Feature: Access Control
  The backend provides Public/Private/Role-based access control for APIs

  Background:
    Given client accepts JSON

  Scenario: Bob can access his data only
    Given the system only knows those Buildings:
    | _id                      | label     | level | _owner         |
    | 541816f042e7d8204d000001 | Town Hall |     3 | bob@sponge.com |
    | 541816f042e7d8204d000002 | Army Camp |     3 | john@doe.com   |
    | 541816f042e7d8204d000003 | Gold Mine |     3 | bob@sponge.com |
    And client is authenticated as Bob
    When client requests GET /api/buildings
    Then response status should be 200
    And response body should be JSON:
    """
    [ { "_id" : "541816f042e7d8204d000001", "label" : "Town Hall", "level" : 3, "_owner" : "bob@sponge.com" },
    { "_id" : "541816f042e7d8204d000003", "label" : "Gold Mine", "level" : 3, "_owner" : "bob@sponge.com" } ]
    """

  Scenario: John can not list private objects from Bob
    Given the system only knows those Buildings:
    | _id                      | label     | level | _owner         |
    | 541816f042e7d8204d000001 | Town Hall |     3 | bob@sponge.com |
    | 541816f042e7d8204d000002 | Army Camp |     3 | bob@sponge.com |
    | 541816f042e7d8204d000003 | Gold Mine |     3 | bob@sponge.com |
    And client is authenticated as John
    When client requests GET /api/buildings
    Then response status should be 200
    And response body should be JSON:
    """
    [ ] 
    """

  Scenario: John can not get a private object from Bob
    Given the system knows this Building JSON:
    """
    { "_id": "541816f042e7d8204d000001",
      "label": "Town Hall",
      "level": 3,
      "_owner": "bob@sponge.com" }
    """
    And client is authenticated as John
    When client requests GET /api/buildings/541816f042e7d8204d000001
    Then response status should be 200
    And response body should be JSON:
    """
    null
    """

  Scenario: John can not insert and override a private object from Bob
    Given the system knows this Building JSON:
    """
    { "_id": "541816f042e7d8204d000001",
      "label": "Town Hall",
      "level": 3,
      "_owner": "bob@sponge.com" }
    """
    And client is authenticated as John
    When client requests POST /api/buildings with JSON:
    """
    { "_id": "541816f042e7d8204d000001",
      "label": "John's Town Hall",
      "level": 999 }
    """
    Then response status should be 422
    When client requests POST /api/buildings with JSON:
    """
    { "label": "John's Town Hall",
      "level": 999,
      "_owner": "john@doe.com" }
    """
    Then response status should be 422

  Scenario: John can not modify and override a private object from Bob
    Given the system knows this Building JSON:
    """
    { "_id": "541816f042e7d8204d000001",
      "label": "Town Hall",
      "level": 3,
      "_owner": "bob@sponge.com" }
    """
    And client is authenticated as John
    When client requests PUT /api/buildings/541816f042e7d8204d000001 with JSON:
    """
    { "_id": "541816f042e7d8204d000001",
      "label": "John's Town Hall",
      "level": 999 }
    """
    Then response status should be 422
    When client requests PUT /api/buildings/541816f042e7d8204d000001 with JSON:
    """
    { "label": "John's Town Hall",
      "level": 999,
      "_owner": "john@doe.com" }
    """
    Then response status should be 422
    When client requests PUT /api/buildings/541816f042e7d8204d000001 with JSON:
    """
    { "label": "John's Town Hall",
      "level": 999 }
    """
    Then response status should be 422

  Scenario: John can not mutate and override a private object from Bob
    Given the system knows this Building JSON:
    """
    { "_id": "541816f042e7d8204d000001",
      "label": "Town Hall",
      "level": 3,
      "_owner": "bob@sponge.com" }
    """
    And client is authenticated as John
    When client requests PATCH /api/buildings/541816f042e7d8204d000001 with JSON:
    """
    { "_id": "541816f042e7d8204d000001",
      "label": "John's Town Hall",
      "level": 999 }
    """
    Then response status should be 422
    When client requests PATCH /api/buildings/541816f042e7d8204d000001 with JSON:
    """
    { "label": "John's Town Hall",
      "level": 999,
      "_owner": "john@doe.com" }
    """
    Then response status should be 422
    When client requests PATCH /api/buildings/541816f042e7d8204d000001 with JSON:
    """
    { "label": "John's Town Hall",
      "level": 999 }
    """
    Then response status should be 422

  Scenario: John can not delete a private object from Bob
    Given the system knows this Building JSON:
    """
    { "_id": "541816f042e7d8204d000001",
      "label": "Town Hall",
      "level": 3,
      "_owner": "bob@sponge.com" }
    """
    And client is authenticated as John
    When client requests DELETE /api/buildings/541816f042e7d8204d000001
    Then response status should be 422

  Scenario: John can not find private objects from Bob
    Given the system only knows those Buildings:
    | _id                      | label     | level | _owner         |
    | 541816f042e7d8204d000001 | Town Hall |     3 | bob@sponge.com |
    | 541816f042e7d8204d000002 | Army Camp |     3 | bob@sponge.com |
    | 541816f042e7d8204d000003 | Gold Mine |     3 | bob@sponge.com |
    And client is authenticated as John
    When client requests POST /api/buildings/find with JSON:
    """
    { }
    """
    Then response status should be 200
    And response body should be JSON:
    """
    [ ] 
    """
    When client requests POST /api/buildings/find with JSON:
    """
    { "level": 3 }
    """
    Then response status should be 200
    And response body should be JSON:
    """
    [ ] 
    """
    When client requests POST /api/buildings/find with JSON:
    """
    { "_id": "541816f042e7d8204d000001" }
    """
    Then response status should be 422
    When client requests POST /api/buildings/find with JSON:
    """
    { "_owner": "bob@sponge.com" }
    """
    Then response status should be 422
