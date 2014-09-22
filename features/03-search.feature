Feature: Search
  The backend provide a search APIs to query objects based on specified criteria

  Background:
    Given client is authenticated
    And client accepts JSON

  Scenario: Finding any Buildings
    Given the system only knows those Buildings:
    | _id                      | _owner         | type     | label       | level |  gold | troop |
    | 541816f042e7d8204d000001 | bob@sponge.com | other    | Clan Castle |     1 | 50000 |     5 |
    | 541816f042e7d8204d000002 | bob@sponge.com | army     | Army Camp   |     3 |   999 |       |
    | 541816f042e7d8204d000003 | bob@sponge.com | resource | Gold Mine   |     3 |       |    30 |
    When client requests POST /api/buildings/find with JSON: {}
    Then response status should be 200
    And response body should be JSON:
    """
    [ { "_id" : "541816f042e7d8204d000001", "_owner" : "bob@sponge.com", "type" : "other", "label" : "Clan Castle", "level" : 1, "gold" : 50000, "troop" : 5 },
      { "_id" : "541816f042e7d8204d000002", "_owner" : "bob@sponge.com", "type" : "army", "label" : "Army Camp", "level" : 3, "gold" : 999, "troop" : null },
      { "_id" : "541816f042e7d8204d000003", "_owner" : "bob@sponge.com", "type" : "resource", "label" : "Gold Mine", "level" : 3, "gold" : null, "troop" : 30 } ]
    """
    
  Scenario: Finding Buildings of type 'army'
    Given the system only knows those Buildings:
    | _id                      | _owner         | type     | label       | level |  gold | troop |
    | 541816f042e7d8204d000001 | bob@sponge.com | other    | Clan Castle |     1 | 50000 |     5 |
    | 541816f042e7d8204d000002 | bob@sponge.com | army     | Army Camp   |     3 |   999 |       |
    | 541816f042e7d8204d000003 | bob@sponge.com | resource | Gold Mine   |     3 |       |    30 |
    When client requests POST /api/buildings/find with JSON: { "type": "army" }
    Then response status should be 200
    And response body should be JSON:
    """
    [ { "_id" : "541816f042e7d8204d000002", "_owner" : "bob@sponge.com", "type" : "army", "label" : "Army Camp", "level" : 3, "gold" : 999, "troop" : null } ]
    """

  Scenario: Finding Buildings of level 3
    Given the system only knows those Buildings:
    | _id                      | _owner         | type     | label       | level |  gold | troop |
    | 541816f042e7d8204d000001 | bob@sponge.com | other    | Clan Castle |     1 | 50000 |     5 |
    | 541816f042e7d8204d000002 | bob@sponge.com | army     | Army Camp   |     3 |   999 |       |
    | 541816f042e7d8204d000003 | bob@sponge.com | resource | Gold Mine   |     3 |       |    30 |
    When client requests POST /api/buildings/find with JSON: { "level": 3 }
    Then response status should be 200
    And response body should be JSON:
    """
    [ { "_id" : "541816f042e7d8204d000002", "_owner" : "bob@sponge.com", "type" : "army", "label" : "Army Camp", "level" : 3, "gold" : 999, "troop" : null },
      { "_id" : "541816f042e7d8204d000003", "_owner" : "bob@sponge.com", "type" : "resource", "label" : "Gold Mine", "level" : 3, "gold" : null, "troop" : 30 } ]
    """

  Scenario: Finding Buildings with gold greater than 10000
    Given the system only knows those Buildings:
    | _id                      | _owner         | type     | label       | level |  gold | troop |
    | 541816f042e7d8204d000001 | bob@sponge.com | other    | Clan Castle |     1 | 50000 |     5 |
    | 541816f042e7d8204d000002 | bob@sponge.com | army     | Army Camp   |     3 |   999 |       |
    | 541816f042e7d8204d000003 | bob@sponge.com | resource | Gold Mine   |     3 |       |    30 |
    When client requests POST /api/buildings/find with JSON: { "gold": { "$gt": 10000 } }
    Then response status should be 200
    And response body should be JSON:
    """
    [ { "_id" : "541816f042e7d8204d000001", "_owner" : "bob@sponge.com", "type" : "other", "label" : "Clan Castle", "level" : 1, "gold" : 50000, "troop" : 5 } ]
    """

  Scenario: Finding Buildings with gold = null OR troop = nul
    Given the system only knows those Buildings:
    | _id                      | _owner         | type     | label       | level |  gold | troop |
    | 541816f042e7d8204d000001 | bob@sponge.com | other    | Clan Castle |     1 | 50000 |     5 |
    | 541816f042e7d8204d000002 | bob@sponge.com | army     | Army Camp   |     3 |   999 |       |
    | 541816f042e7d8204d000003 | bob@sponge.com | resource | Gold Mine   |     3 |       |    30 |
    When client requests POST /api/buildings/find with JSON: { "$or": [ { "gold": null }, { "troop": null } ] }
    Then response status should be 200
    And response body should be JSON:
    """
    [ { "_id" : "541816f042e7d8204d000002", "_owner" : "bob@sponge.com", "type" : "army", "label" : "Army Camp", "level" : 3, "gold" : 999, "troop" : null },
      { "_id" : "541816f042e7d8204d000003", "_owner" : "bob@sponge.com", "type" : "resource", "label" : "Gold Mine", "level" : 3, "gold" : null, "troop" : 30 } ]
    """
