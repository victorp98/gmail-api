FROM ruby:3.4.3-slim
RUN apt-get update -qq && apt-get install --no-install-recommends -y build-essential libsqlite3-dev && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN bundle install
COPY . .
RUN bin/rails assets:precompile
EXPOSE 4567
CMD ["sh", "-c", "bin/rails db:prepare && bin/rails server -b 0.0.0.0 -p ${PORT:-4567}"]
