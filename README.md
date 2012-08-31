# RefineryCMS & Spree Quick Start

These are the steps I followed to get [RefineryCMS 2.0](http://refinerycms.com/) and [Spree 1.2](http://spreecommerce.com/) playing nicely together.

RefineryCMS and Spree both use Devise for authentication, but they are both completely separate (so you must have
separate user accounts for each). In Spree 1.2, authentication has been moved to a separate gem, allowing you
to use your own authentication. As of Refinery 2.0 it's still quite a lot of work to use your own authentication.

For this reason, it seemed easiest to configure Spreee to use RefineryCMS for authentication.

## Installation

### First steps

Create a new Refinery app:

    gem install refinerycms
    refinerycms refinery_spree

Add Spree 1.2 to the [Gemfile](https://github.com/adrianmacneil/refinery_spree/blob/master/Gemfile):

    gem 'spree', '~> 1.2.0'

Install Spree

    rails g spree:install

Update [config/routes.rb](https://github.com/adrianmacneil/refinery_spree/blob/master/config/routes.rb) to use Refinery for the home page

    root :to => "refinery/pages#home"
    
### Bug fixes

RefineryCMS uses WillPaginage for pagination, while Spree uses Kaminari. Unfortunately, the two don't cooperate,
and you will see the following error when you try to view your Spree products list:

    NoMethodError in Spree::ProductsController#index
    undefined method `per' for #<ActiveRecord::Relation:0x007f800252e6b0>

To fix it, add the following monkey patch to [config/initializers/will_paginate.rb](https://github.com/adrianmacneil/refinery_spree/blob/master/config/initializers/will_paginate.rb):

    if defined?(WillPaginate)
      module WillPaginate
        module ActiveRecord
          module RelationMethods
            alias_method :per, :per_page
            alias_method :num_pages, :total_pages
          end
        end 
      end
    end
    
(see [https://github.com/spree/spree/pull/1512#issuecomment-6028357](https://github.com/spree/spree/pull/1512#issuecomment-6028357))

When you visit a RefineryCMS page, you will see the following unhelpful error message:

    NoMethodError in Refinery/pages#home
    undefined method `refinery_user?' for #<#<Class:0x007f8a2c762bf0>:0x007f8a2f2a42f0>
    
I'm not exactly sure what causes this, but it's easy to fix. Simply add the following line to [app/controllers/application_controller.rb](https://github.com/adrianmacneil/refinery_spree/blob/master/app/controllers/application_controller.rb):

    class ApplicationController < ActionController::Base
      protect_from_forgery
      helper_method :refinery_user?
    end
    
(see [https://github.com/resolve/refinerycms/issues/1804#issuecomment-8038184](https://github.com/resolve/refinerycms/issues/1804#issuecomment-8038184))

### Tell Spree to use RefineryCMS for authentication

Update [config/initializers/spree.rb](https://github.com/adrianmacneil/refinery_spree/blob/master/config/initializers/spree.rb) to use Refinery authentication

    Spree.user_class = "Refinery::User"

Run generator to add Spree support to Refinery's user model (will add 3 new columns to refinery_users table)

    rails g spree:custom_user Refinery::User
    rake db:migrate

Update [lib/spree/authentication_helpers.rb](https://github.com/adrianmacneil/refinery_spree/blob/master/lib/spree/authentication_helpers.rb) to use `current_refinery_user` and Refinery's login/signup routes

    module Spree
      module AuthenticationHelpers
        def self.included(receiver)
          receiver.send :helper_method, :spree_login_path
          receiver.send :helper_method, :spree_signup_path
          receiver.send :helper_method, :spree_logout_path
          receiver.send :helper_method, :spree_current_user
        end
     
        def spree_current_user
          current_refinery_user
        end
     
        def spree_login_path
          refinery.new_refinery_user_session_path
        end
     
        def spree_signup_path
          refinery.new_refinery_user_registration_path
        end
     
        def spree_logout_path
          refinery.destroy_refinery_user_session_path
        end
      end
    end
     
    ApplicationController.send :include, Spree::AuthenticationHelpers

Open http://localhost:3000/refinery and create an admin user for yourself. Then add yourself as a Spree admin:

    rails console
    Refinery::User.first.spree_roles << Spree::Role.find_or_create_by_name("admin")

All done! Now you can access Refinery at http://localhost:3000/refinery and Spree at http://localhost:3000/admin

## Helpful links:

* https://github.com/spree/spree/pull/1512
* http://ryanbigg.com/spree-guides/authentication.html
* https://github.com/resolve/refinerycms/issues/1804
