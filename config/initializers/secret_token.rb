# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
Rosa::Application.config.secret_token = APP_CONFIG['keys']['secret_token']
Rosa::Application.config.secret_key_base = APP_CONFIG['keys']['secret_key_base']

Rosa::Application.config.active_record.encryption.primary_key = APP_CONFIG['keys']['active_record']['primary_key']
Rosa::Application.config.active_record.encryption.deterministic_key = APP_CONFIG['keys']['active_record']['deterministic_key']
Rosa::Application.config.active_record.encryption.key_derivation_salt = APP_CONFIG['keys']['active_record']['key_derivation_salt']
