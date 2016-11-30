require 'rubygems'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])

require 'yaml'
require 'rest-client'
require 'base64'
require 'json'
require 'pry'

$LOAD_PATH << File.expand_path('../../lib', __FILE__)

require_relative '../lib/jira_integration'

JiraIntegration.config = YAML.load_file(File.expand_path('../environments.yml', __FILE__))
