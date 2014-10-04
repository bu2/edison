Feature: Sharing
  The backend provides sharing management based on Public/Private/Role-based/ACL access control

  Background:
    Given client accepts JSON

  Scenario: Bob can grant read access to everyone (public object)
    Given the system only knows those Buildings:
    | _id                      | label     | level | _owner         |
    | 541816f042e7d8204d000001 | Town Hall |     3 | bob@sponge.com |
    | 541816f042e7d8204d000002 | Army Camp |     3 | john@doe.com   |
    | 541816f042e7d8204d000003 | Gold Mine |     3 | tom@cat.com    |
    And client is authenticated as Bob
    When client requests POST /api/buildings/541816f042e7d8204d000001/share with JSON:
    """
    [ { "_targets": ["public"],
        "_permissions": [ {"_read":true} ] } ]
    """
    Then response status should be 200
    And response body should be JSON:
    """
    { "status": "ok" }
    """
    When client is authenticated as John
    And client requests GET /api/buildings/541816f042e7d8204d000001
    Then response status should be 200
    And response body should be JSON:
    """
    { "_id" : "541816f042e7d8204d000001",
      "label" : "Town Hall",
      "level" : 3,
      "_owner" : "bob@sponge.com",
      "_tags": [{ "_targets": ["public"], "_permissions": [{"_read": true}]}] }
    """
    When client requests GET /api/buildings
    Then response status should be 200
    And response body should be JSON:
    """
    [ { "_id" : "541816f042e7d8204d000002", "label" : "Army Camp", "level" : 3, "_owner" : "john@doe.com" }, 
      { "_id" : "541816f042e7d8204d000001", "label" : "Town Hall", "level" : 3, "_owner" : "bob@sponge.com", "_tags": [{ "_targets": ["public"], "_permissions": [{"_read": true}]}] } ]
    """
    When client is authenticated as Tom
    And client requests GET /api/buildings/541816f042e7d8204d000001
    Then response status should be 200
    And response body should be JSON:
    """
    { "_id" : "541816f042e7d8204d000001",
      "label" : "Town Hall",
      "level" : 3,
      "_owner" : "bob@sponge.com",
      "_tags": [{ "_targets": ["public"], "_permissions": [{"_read": true}]}] }
    """
    When client requests GET /api/buildings
    Then response status should be 200
    And response body should be JSON:
    """
    [ { "_id" : "541816f042e7d8204d000003", "label" : "Gold Mine", "level" : 3, "_owner" : "tom@cat.com"},
      { "_id" : "541816f042e7d8204d000001", "label" : "Town Hall", "level" : 3, "_owner" : "bob@sponge.com", "_tags": [{ "_targets": ["public"], "_permissions": [{"_read": true}]}] } ]
    """
    When client is authenticated as Nobody
    And client requests GET /api/buildings/541816f042e7d8204d000001
    Then response status should be 200
    And response body should be JSON:
    """
    { "_id" : "541816f042e7d8204d000001",
      "label" : "Town Hall",
      "level" : 3,
      "_owner" : "bob@sponge.com",
      "_tags": [{ "_targets": ["public"], "_permissions": [{"_read": true}]}] }
    """
    When client requests GET /api/buildings
    Then response status should be 200
    And response body should be JSON:
    """
    [ { "_id" : "541816f042e7d8204d000001", "label" : "Town Hall", "level" : 3, "_owner" : "bob@sponge.com", "_tags": [{ "_targets": ["public"], "_permissions": [{"_read": true}]}] } ]
    """

  Scenario: Bob can grant read/write access to everyone (public object)
    Given the system only knows those Buildings:
    | _id                      | label     | level | _owner         |
    | 541816f042e7d8204d000001 | Town Hall |     3 | bob@sponge.com |
    | 541816f042e7d8204d000002 | Army Camp |     3 | john@doe.com   |
    | 541816f042e7d8204d000003 | Gold Mine |     3 | tom@cat.com    |
    And client is authenticated as Bob
    When client requests POST /api/buildings/541816f042e7d8204d000001/share with JSON:
    """
    [ { "_targets": ["public"],
        "_permissions": [ {"_read":true}, {"_write":true} ] } ]
    """
    Then response status should be 200
    And response body should be JSON:
    """
    { "status": "ok" }
    """
    And client is authenticated as John
    When client requests PUT /api/buildings/541816f042e7d8204d000001 with JSON:
    """
    { "label": "John's Town Hall",
      "level": 999 }
    """
    Then response status should be 200
    And response body should be JSON:
    """
    { "status": "ok" }
    """
    When client requests PATCH /api/buildings/541816f042e7d8204d000001 with JSON:
    """
    { "label": "John's Town Hall",
      "level": 999 }
    """
    Then response status should be 200
    And response body should be JSON:
    """
    { "status": "ok" }
    """
    When client requests DELETE /api/buildings/541816f042e7d8204d000001
    Then response status should be 200
    And response body should be JSON:
    """
    { "status": "ok" }
    """
    
    When client requests PATCH /api/buildings/541816f042e7d8204d000001 with JSON:
    """
    { "label": "John's Town Hall",
      "level": 999 }
    """
    Then response status should be 422
    When client requests DELETE /api/buildings/541816f042e7d8204d000001
    Then response status should be 422

  Scenario: John must not be able to grant access to objects it does not own
    Given the system only knows those Buildings:
    | _id                      | label     | level | _owner         | _tags                                                          |
    | 541816f042e7d8204d000001 | Town Hall |     3 | bob@sponge.com | [{ "_targets": ["public"], "_permissions": [{"_read": true}]}] |
    | 541816f042e7d8204d000002 | Army Camp |     3 | john@doe.com   | []                                                             |
    | 541816f042e7d8204d000003 | Gold Mine |     3 | tom@cat.com    | []                                                             |
    And client is authenticated as John
    When client requests POST /api/buildings/541816f042e7d8204d000003/share with JSON:
    """
    [ { "_targets": ["public"],
        "_permissions": [ {"_read":true} ] } ]
    """
    Then response status should be 422
    When client requests POST /api/buildings/541816f042e7d8204d000001/share with JSON:
    """
    [ { "_targets": ["john@doe.com"],
        "_permissions": [ {"_read": true}, {"_write":true} ] } ]
    """
    Then response status should be 422
    
