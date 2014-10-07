Feature: Concurrency
  The backend provides mutual exclusion when accessing shared data.

  Scenario: Bob can acquire the lock to avoid concurrent write accesses
    Given the system only knows those Buildings:
    | _id                      | label     | level | _owner         | _tags                                                                          |
    | 541816f042e7d8204d000001 | Town Hall |     3 | bob@sponge.com | [{ "_targets": ["public"], "_permissions": [{"_read":true},{"_write":true}] }] |
    And client is authenticated as Bob
    When client requests POST /api/buildings/541816f042e7d8204d000001/lock with JSON: {}
    Then response status should be 200
    And response body should be JSON:
    """
    { "_id": "541816f042e7d8204d000001",
      "label": "Town Hall",
      "level": 3,
      "_owner": "bob@sponge.com",
      "_tags": [{ "_targets": ["public"],
                  "_permissions": [{"_read":true}, {"_write":true}]}],
      "_lock": "bob@sponge.com" }
    """
    When client is authenticated as John
    And client requests PATCH /api/buildings/541816f042e7d8204d000001 with JSON:
    """
    { "label": "John's Town Hall",
      "level": 999 }
    """
    Then response status should be 422
    When client is authenticated as Tom
    And client requests PATCH /api/buildings/541816f042e7d8204d000001 with JSON:
    """
    { "label": "Tom's Town Hall",
      "level": 999 }
    """
    Then response status should be 422
    When client is authenticated as Bob
    And client requests GET /api/buildings/541816f042e7d8204d000001
    Then response status should be 200
    And response body should be JSON:
    """
    { "_id": "541816f042e7d8204d000001",
      "label": "Town Hall",
      "level": 3,
      "_owner": "bob@sponge.com",
      "_tags": [{ "_targets": ["public"],
                  "_permissions": [{"_read":true}, {"_write":true}]}],
      "_lock": "bob@sponge.com" }
    """
    When client requests PATCH /api/buildings/541816f042e7d8204d000001 with JSON:
    """
    { "label": "Town Hall is mine! Bob.",
      "level": 999,
      "_lock": false }
    """
    Then response status should be 200
    And response body should be JSON:
    """
    { "status": "ok" }
    """

  Scenario: When Bob has the lock, others can still read
    Given the system only knows those Buildings:
    | _id                      | label     | level | _owner         | _tags                                                                          | _lock          |
    | 541816f042e7d8204d000001 | Town Hall |     3 | bob@sponge.com | [{ "_targets": ["public"], "_permissions": [{"_read":true},{"_write":true}] }] | bob@sponge.com |
    When client is authenticated as John
    And client requests GET /api/buildings/541816f042e7d8204d000001
    Then response status should be 200
    And response body should be JSON:
    """
    { "_id": "541816f042e7d8204d000001",
      "label": "Town Hall",
      "level": 3,
      "_owner": "bob@sponge.com",
      "_tags": [{ "_targets": ["public"],
                    "_permissions": [{"_read":true}, {"_write":true}]}],
      "_lock": true }
    """
    When client is authenticated as Tom
    And client requests GET /api/buildings/541816f042e7d8204d000001
    Then response status should be 200
    And response body should be JSON:
    """
    { "_id": "541816f042e7d8204d000001",
      "label": "Town Hall",
      "level": 3,
      "_owner": "bob@sponge.com",
      "_tags": [{ "_targets": ["public"],
                  "_permissions": [{"_read":true}, {"_write":true}]}],
      "_lock": true }
    """

  Scenario: When he has the lock, Bob can release it
    Given the system only knows those Buildings:
    | _id                      | label     | level | _owner         | _tags                                                                                | _lock          |
    | 541816f042e7d8204d000001 | Town Hall |     3 | bob@sponge.com | [{ "_targets": ["john@doe.com"], "_permissions": [{"_read":true},{"_write":true}] }] | bob@sponge.com |
    When client is authenticated as John
    And client requests PATCH /api/buildings/541816f042e7d8204d000001 with JSON:
    """
    { "label": "John's Town Hall... ?",
      "level": 999 }
    """
    Then response status should be 422
    When client is authenticated as Bob
    And client requests PATCH /api/buildings/541816f042e7d8204d000001 with JSON:
    """
    { "_lock": false }
    """
    Then response status should be 200
    And response body should be JSON:
    """
    { "status": "ok" }
    """
    When client is authenticated as John
    And client requests PATCH /api/buildings/541816f042e7d8204d000001 with JSON:
    """
    { "label": "John's Town Hall... Finally!",
      "level": 999 }
    """
    Then response status should be 200
    And response body should be JSON:
    """
    { "status": "ok" }
    """

  Scenario: John must not be able to release Bob's lock
    Given the system only knows those Buildings:
    | _id                      | label     | level | _owner         | _tags                                                                                | _lock          |
    | 541816f042e7d8204d000001 | Town Hall |     3 | bob@sponge.com | [{ "_targets": ["john@doe.com"], "_permissions": [{"_read":true},{"_write":true}] }] | bob@sponge.com |
    When client is authenticated as John
    And client requests PATCH /api/buildings/541816f042e7d8204d000001 with JSON:
    """
    { "_lock": false }
    """
    Then response status should be 422

  Scenario: Only the owner of the object (Bob) or the owner of the lock (John) can see who has the lock
    Given the system only knows those Buildings:
    | _id                      | label     | level | _owner         | _tags                                                                          | _lock        |
    | 541816f042e7d8204d000001 | Town Hall |     3 | bob@sponge.com | [{ "_targets": ["public"], "_permissions": [{"_read":true},{"_write":true}] }] | john@doe.com |
    When client is authenticated as Bob
    And client requests GET /api/buildings/541816f042e7d8204d000001
    Then response status should be 200
    And response body should be JSON:
    """
    { "_id": "541816f042e7d8204d000001",
      "label": "Town Hall",
      "level": 3,
      "_owner": "bob@sponge.com",
      "_tags": [{ "_targets": ["public"],
                  "_permissions": [{"_read":true}, {"_write":true}]}],
      "_lock": "john@doe.com" }
    """
    When client is authenticated as John
    And client requests GET /api/buildings/541816f042e7d8204d000001
    Then response status should be 200
    And response body should be JSON:
    """
    { "_id": "541816f042e7d8204d000001",
      "label": "Town Hall",
      "level": 3,
      "_owner": "bob@sponge.com",
      "_tags": [{ "_targets": ["public"],
                  "_permissions": [{"_read":true}, {"_write":true}]}],
      "_lock": "john@doe.com" }
    """
    When client is authenticated as Tom
    And client requests GET /api/buildings/541816f042e7d8204d000001
    Then response status should be 200
    And response body should be JSON:
    """
    { "_id": "541816f042e7d8204d000001",
      "label": "Town Hall",
      "level": 3,
      "_owner": "bob@sponge.com",
      "_tags": [{ "_targets": ["public"],
                  "_permissions": [{"_read":true}, {"_write":true}]}],
      "_lock": true }
    """

  Scenario: John and Tom are able to increment safely a shared counter at the same time
    Given the system only knows those Counters:
    | _id                      | count | _owner         | _tags                                                                          |
    | 541816f042e7d8204d000001 |     0 | bob@sponge.com | [{ "_targets": ["public"], "_permissions": [{"_read":true},{"_write":true}] }] |
    When John and Tom increment the counter with id "541816f042e7d8204d000001" by 25 times each at the same time
    Then Counter with id "541816f042e7d8204d000001" should be JSON:
    """
    { "_id": { "$oid": "541816f042e7d8204d000001" },
      "count": 50,
      "_owner": "bob@sponge.com",
      "_tags": [{ "_targets": ["public"], "_permissions": [{"_read":true},{"_write":true}] }],
      "_lock": false }
    """
