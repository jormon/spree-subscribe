[![Build Status](https://travis-ci.org/jormon/spree-subscribe.svg?branch=spree-2-4)](https://travis-ci.org/jormon/spree-subscribe)
[![Code Climate](https://codeclimate.com/github/onedanshow/spree-subscribe.png)](https://codeclimate.com/github/onedanshow/spree-subscribe)

**This extension is ready for beta testing.**

SpreeSubscribe
==============

A Spree extension for allowing customer to subscribe to a product(s), have it periodically sent to him/her, and manage that subscription.


Installation
-------

Add this to your Gemfile

    gem "spree_subscribe", github: "onedanshow/spree-subscribe", branch: '2-0-beta'

Install the database migrations

    rake spree_subscribe:install:migrations

Setup a cron job to run this rake task every night

    rake spree_subscribe:reorders:create

Future To-Do
-------

* Update Product#show javascript to show subscription price when subscription interval is selected
* Create Spree::SubscriptionsController and views for edit and update actions for the customer
* Email customers when a re-order is shipped?
* Extend Spree API to handle subscriptions?
* Move Intervalable#time_title to a helper so can use time_unit_symbol to pull from localization
* Extend Spree::Admin::SubscriptionsController to include filtering and sorting
* For a reorder, if a shipping method is no longer available, select the cheapest.

Testing
-------

Be sure to bundle your dependencies and then create a dummy test app for the specs to run against.

    $ bundle
    $ bundle exec rake test_app
    $ bundle exec rspec spec

Copyright (c) 2013 Daniel Dixon, released under the New BSD License


Responsible Disclosure of Security Issues
-------

If you find a security issue with this extension, please contact me directly (code@danieldixon.com).  Do NOT post it publicly to the GitHub issues for this repo.  I will be happy to work with you to resolve the issue.  For further information, please see: http://confreaks.com/videos/2430-railsconf2013-security-is-hard-but-we-cant-go-shopping
