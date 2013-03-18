class AutocompletesController < ApplicationController
  before_filter :authenticate_user!

  autocomplete :group, :uname
  autocomplete :user, :uname
end
