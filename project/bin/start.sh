#!/bin/bash

# Ensure dependencies are installed
bundle check || bundle install

# Remove any old server PID file
if [ -f tmp/pids/server.pid ]; then
  rm -f tmp/pids/server.pid
fi

# Run database setup if migrations are missing
(bundle exec rails db:migrate:status > /dev/null 2>&1 || bundle exec rails db:setup) && bundle exec rails db:migrate && bundle exec rails db:schema:dump

# Start the Rails server
bundle exec rails server -b 0.0.0.0
