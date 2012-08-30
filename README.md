# RefineryCMS & Spree Quick Start

Install Refinery:

    gem install refinerycms
    refinerycms refinery_spree

Add Spree gem:

    gem 'spree', git: 'git://github.com/spree/spree.git', branch: '1-2-stable'

Install Spree

    rails g spree:install

Update [config/routes.rb](https://github.com/adrianmacneil/refinery_spree/blob/master/config/routes.rb) to use Refinery for the home page

    root :to => "refinery/pages#home"

Add WillPaginate initializer monkey patch to [config/initializers/will_paginate.rb](https://github.com/adrianmacneil/refinery_spree/blob/master/config/initializers/will_paginate.rb)

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

Fix refinery_user? error message:

    class ApplicationController < ActionController::Base
      protect_from_forgery
      helper_method :refinery_user?
    end

Update [config/initializers/spree.rb](https://github.com/adrianmacneil/refinery_spree/blob/master/config/initializers/spree.rb) to use Refinery authentication

    Spree.user_class = "Refinery::User"

Run generator to add Spree support to Refinery user model (will add 3 new columns to refinery_users table)

    rails g spree:custom_user Refinery::User
    rake db:migrate

Update [lib/spree/authentication_helpers.rb](https://github.com/adrianmacneil/refinery_spree/blob/master/lib/spree/authentication_helpers.rb) to use current_refinery_user and Refinery login/signup routes

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

    rails c
    Refinery::User.first.spree_roles << Spree::Role.find_or_create_by_name("admin")

All done! Now you can access Refinery at http://localhost:3000/refinery and Spree at http://localhost:3000/admin
