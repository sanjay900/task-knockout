require 'rubygems'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])

require 'pry'

require 'thor'
require 'yaml'
require 'rest-client'
require 'base64'
require 'json'
require 'table_print'
require 'logger'

$LOAD_PATH << File.expand_path('../../lib', __FILE__)

require_relative '../lib/task_knockout'

TaskKnockout.config = YAML.load_file(File.expand_path('../environments.yml', __FILE__))
