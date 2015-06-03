# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
Rails.application.config.assets.precompile += %w(
  login.css login.js reg_session.css tour.css tour.js gollum/editor/langs/*.js
  moment/ru.js codemirror_editor.js codemirror_editor.css new_application.css
  new_application.js angular-locale_ru-ru.js
)
