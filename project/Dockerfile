# Use a Ruby base image
FROM ruby:3.3

# Set environment variables
ENV BUNDLE_PATH=/gems

# Install dependencies
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev

# Set working directory
WORKDIR /app

# Copy Gemfile and Gemfile.lock
COPY Gemfile Gemfile.lock ./

# Install gems
RUN bundle install

# Copy the rest of the app code
COPY . .

# Expose the Rails server port
EXPOSE 3000

# Start the Rails server
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]