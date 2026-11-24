source "https://rubygems.org"

gem "rails", "~> 8.1.4"
gem "propshaft"
gem "sqlite3", ">= 2.1"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tzinfo-data", platforms: %i[ windows jruby ]

# json 3 made JSON.parse's options keyword-only; released Rails still passes
# them positionally (see the framework's own Gemfile).
gem "json", "< 4"

# The framework and its dashboard. ACTIVEAGENT_PATH=../activeagent runs the
# app against a checkout of the framework instead of the released gems.
if (framework = ENV["ACTIVEAGENT_PATH"])
  gem "activeagent", path: framework
  gem "actionagent", path: File.join(framework, "actionagent")
else
  gem "activeagent", "~> 1.9", ">= 1.9.9"
  gem "actionagent", "~> 1.9", ">= 1.9.9"
end

# Provider clients. The demo runs on Anthropic by default; the mock provider
# (DEMO_PROVIDER=mock) needs neither.
gem "anthropic", ">= 1.12", "< 3"
gem "openai", "~> 0.34"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "dotenv"
end
