FROM ruby:2.4.9-alpine3.11 as rosa-build-gems

WORKDIR /rosa-build
RUN apk add --no-cache libpq tzdata ca-certificates git icu rpm nodejs python2 redis && \
    apk add --virtual .ruby-builddeps --no-cache postgresql-dev build-base cmake icu-dev
RUN gem install bundler:1.17.3
COPY vendor ./vendor
COPY Gemfile Gemfile.lock ./
RUN bundle install --without development test --jobs 16 --clean --deployment --no-cache --verbose
RUN apk add --no-cache file imagemagick curl gnupg openssh-keygen
RUN apk del .ruby-builddeps && rm -rf /root/.bundle && rm -rf /proxy/vendor/bundle/ruby/2.4.0/cache
RUN mkdir -p /root/.gnupg && chmod 700 /root/.gnupg
RUN git clone -b 2.2.0 https://github.com/pygments/pygments.git && cd pygments && python setup.py install && cd .. && rm -rf pygments

FROM scratch
COPY --from=rosa-build-gems / /

RUN touch /MIGRATE
ENV RAILS_ENV production

ENV GEM_HOME /usr/local/bundle
ENV BUNDLE_APP_CONFIG /usr/local/bundle
ENV REDIS_URL redis://redis:6379/0
ENV REDIS_CACHE_URL redis://redis:6379/1
ENV DATABASE_URL postgresql://postgres@postgres/rosa-build?pool=20&statement_limit=0

WORKDIR /rosa-build
COPY bin ./bin
COPY lib ./lib
COPY config ./config
COPY db ./db
COPY app/ ./app
COPY script ./script
COPY vendor ./vendor
COPY Rakefile config.ru entrypoint.sh entrypoint_resque.sh entrypoint_resque_scheduler.sh ./
RUN git config --global user.email "abf@rosalinux.ru"
RUN git config --global user.name "ABF"
ENTRYPOINT ["/rosa-build/entrypoint.sh"]
