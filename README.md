The Edison "[MBaaS](http://en.wikipedia.org/wiki/Mobile_Backend_as_a_service)" Framework
========================================================================================

Welcome!
--------

Edison is the quickest and easiest way to setup your own mobile backend [![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy).

It is open source (BSD-style license) and under active development.

Current features:
-----------------
  * Generic [RESTful](http://en.wikipedia.org/wiki/Representational_state_transfer) controller to store and retrieve semi-structured data ([JSON](http://en.wikipedia.org/wiki/JSON))
  * Search query using powerful predicates (from [MongoDB](http://docs.mongodb.org/manual/reference/operator/query/))
  * Authentication
  * Private data
  * Shared data with [RBAC](http://en.wikipedia.org/wiki/Role-based_access_control) and [ACL](http://en.wikipedia.org/wiki/Access_control_list)
  * Public data
  * Concurrency & Mutual Exclusion

Coming features:
----------------

**(very soon)** Readying for Beta launch:

  * CORE:
    - Simple Authentication (email+password)
    - Third-party Authentication 

  * ADDONS (find cool external providers):
    - Assets
    - Push Notifications

**(long-term)** Roadmap:

Server:

  * tierce authentication
  * assets
  * push notifications
  * error handling

  Future:
    * web-based admin
    * mobile-base admin
    * analytics	    
    * public-key end-to-end encryption
    * nested resources
  
Cient:

  * sample apps:
    - social
    - e-commerce
    - media (music/photo/video)

  * client libraries for seamless integration:
    - REST API calls
    - json2object mapper (iOS/Android...)

What next?
----------

* See INSTALL or just [![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy)
* Run `$ bundle exec cucumber --format html >cucumber.html` and open cucumber.html
* See TODO

Contact:
--------

  * Twitter: [@bu2aeon](https://twitter.com/bu2aeon)
  * Email: bu2gihtub@gmail.com
