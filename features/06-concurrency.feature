Feature: Concurrency
  The backend provides mutual exclusion when accessing shared data.

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
