FROM ruby:2.3.8-alpine3.8 as rosa-build-gems

WORKDIR /rosa-build
RUN apk add --no-cache libpq nodejs tzdata ca-certificates libgit2 icu python2 py2-pygments git && \
    apk add --virtual .ruby-builddeps --no-cache libgit2-dev postgresql-dev build-base cmake icu-dev
RUN gem install bundler:1.17.3
COPY Gemfile Gemfile.lock ./
RUN bundle install --without development test --jobs 16 --clean --deployment --no-cache --verbose
RUN apk add --no-cache rpm
RUN apk del .ruby-builddeps && rm -rf /root/.bundle && rm -rf /proxy/vendor/bundle/ruby/2.3.0/cache

FROM scratch
COPY --from=rosa-build-gems / /

RUN touch /MIGRATE
ENV RAILS_ENV production

ENV GEM_HOME /usr/local/bundle
ENV BUNDLE_APP_CONFIG /usr/local/bundle

WORKDIR /rosa-build
COPY bin ./bin
COPY lib ./lib
COPY config ./config
COPY db ./db
COPY app/ ./app
COPY script ./script
COPY vendor ./vendor
COPY Rakefile config.ru entrypoint.sh entrypoint_resque.sh entrypoint_resque_scheduler.sh ./
ENTRYPOINT ["/rosa-build/entrypoint.sh"]
