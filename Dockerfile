FROM ruby:2.6
RUN apt-get update -qq
RUN gem install bundler
WORKDIR /app
COPY . /app
RUN bundle install

