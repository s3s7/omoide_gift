# Ensure sidekiq-scheduler loads schedules from config/sidekiq.yml
begin
  require "sidekiq-scheduler"
rescue LoadError
  Rails.logger.warn "sidekiq-scheduler gem not found; schedules will not be loaded." if defined?(Rails)
end

Sidekiq.configure_server do |_config|
  schedule_file = Rails.root.join("config", "sidekiq.yml")
  next unless File.exist?(schedule_file)

  # Evaluate ERB in the YAML before loading and allow Symbols if used in YAML
  yaml = YAML.safe_load(
    ERB.new(File.read(schedule_file)).result,
    permitted_classes: [ Symbol ],
    aliases: true
  )
  schedule = yaml["schedule"] || yaml[:schedule] || yaml[":schedule"]

  if schedule.present?
    Sidekiq.schedule = schedule
    Sidekiq::Scheduler.reload_schedule!
    Rails.logger.info("Sidekiq Scheduler: loaded #{schedule.keys.size} schedules")
  else
    Rails.logger.warn("Sidekiq Scheduler: schedule section not found in config/sidekiq.yml")
  end
end

# redis_url = ENV["REDIS_URL"]

# Sidekiq.configure_server do |config|
#   config.redis = { url: redis_url }
# end

# Sidekiq.configure_client do |config|
#   config.redis = { url: redis_url }
# end

# require "sidekiq-scheduler/web"

# redis_url = ENV["REDIS_URL"] || "redis://redis:6379/1"

# Sidekiq.configure_server do |config|
#   config.redis = { url: redis_url }

#   config.on(:startup) do
#     Sidekiq::Scheduler.reload_schedule!
#   end
# end

# Sidekiq.configure_client do |config|
#   config.redis = { url: redis_url }
# end

# require "sidekiq-scheduler/web"
