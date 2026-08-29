require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module App
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # "Due by end of today" (brief item 6) is evaluated in the app's local
    # wall-clock time; the database keeps storing UTC. Overridable so a reviewer
    # in another region sees the boundary in their own day rather than mine.
    config.time_zone = ENV.fetch("APP_TIME_ZONE", "UTC")
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
