rake db:drop RAILS_ENV=test
rake db:create RAILS_ENV=test
rake db:migrate RAILS_ENV=test
rake db:fixtures:load RAILS_ENV=test
rake permissions:load RAILS_ENV=test
rspec
rspec --only-failures
git checkout db
git status
git