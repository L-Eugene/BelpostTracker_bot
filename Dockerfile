FROM ruby:3.1.2-bullseye

RUN apt-get update && apt-get -y install git

RUN mkdir /bot
WORKDIR /bot

RUN git clone https://github.com/L-Eugene/BOTServer.git && rm -rf /bot/BOTServer/.git
RUN git clone https://github.com/L-Eugene/BelpostTracker_bot.git && rm -rf /bot/BelpostTracker_bot/.git

RUN bundle config set --local without 'development test'
RUN bundle install --gemfile /bot/BOTServer/Gemfile --no-cache
RUN bundle install --gemfile /bot/BelpostTracker_bot/Gemfile --no-cache

FROM ruby:3.1.2-slim-bullseye

RUN apt-get update && apt-get -y install cron && apt-get clean

COPY --from=0 /bot/BOTServer /BOTServer/
COPY --from=0 /bot/BelpostTracker_bot /BOTServer/app/
COPY --from=0 /usr/local/bundle/ /usr/local/bundle/