# See: https://github.com/activerecord-hackery/ransack/commit/5c7bb9eaf315a85246a0087c76dff9e5847072a3
Ransack::Adapters::ActiveRecord::Base.class_eval('remove_method :search')