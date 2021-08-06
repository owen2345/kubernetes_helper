# STEP 1: Base Docker Image
FROM ruby:2.7.1-slim AS builder
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
RUN apt-get update && apt-get install -qq -y git build-essential nodejs libpq-dev libcurl4-openssl-dev curl libsqlite3-dev

# Yarn installation
RUN curl https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update && apt-get install -y yarn

RUN mkdir /app
WORKDIR /app
COPY Gemfile /app/Gemfile
COPY Gemfile Gemfile.lock /app/
RUN bundle install
COPY . /app

EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
