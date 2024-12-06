FROM ruby:3.2-slim

WORKDIR /app

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY Gemfile* ./

RUN bundle install

COPY . .

EXPOSE 4567

CMD ["ruby", "flaky_app.rb", "-o", "0.0.0.0"] 