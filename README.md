**WARNING: This project is no longer active or maintained. Please contact stix@mitre.org with any questions or feedback.**

stix-profile-crudbox
====================

A Ruby-on-Rails web-based CRUD utility for STIX profiles.


Installation
------------

Start off by cloning this repository.

CRUDbox is a Ruby-on-Rails web application. To get started, install Ruby 2.x and Rails. [Ruby Version Manager](http://rvm.io) is a good means to this end.

Once you have done this, `cd` into the root of your clone of this repository. Run the following command to install the RubyGems that CRUDbox uses:

    bundle install

Next, set up `secrets.yml` by following steps 1 and 4 found in the Rails documentation [(here)](http://edgeguides.rubyonrails.org/upgrading_ruby_on_rails.html#config-secrets-yml) -- the application will not run without this being done properly.

Running CRUDbox
---------------

Start your development server by running the following from your repository root:

    rails s

This will start the rails development server running at `localhost:3000`. Full documentation on running the development server can be found [here](http://guides.rubyonrails.org/command_line.html#rails-server).

**Running a production instance is outside the scope of this README.**

Copyright Information
---------------------

Copyright (c) 2015 - The MITRE Corporation

For license information, see the LICENSE.txt file
