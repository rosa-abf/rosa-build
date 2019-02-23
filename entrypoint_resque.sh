#!/bin/sh
set -ex

bundle exec rake resque:workers
