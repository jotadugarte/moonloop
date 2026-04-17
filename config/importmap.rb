# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js" # @8.0.23
pin "@hotwired/stimulus", to: "stimulus.min.js" # @3.2.2
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js" # not on npm; vendored with stimulus-rails
pin_all_from "app/javascript/controllers", under: "controllers"
