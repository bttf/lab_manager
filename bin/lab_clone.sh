#!/usr/bin/env ruby
# ########################################################################################## 
# lab_clone.rb
#
#     bin/lab_clone.rb "ORG" "WORKSPACE" "CONFIGURATION" "NEW CONFIGURATION"
# ########################################################################################## 

require 'rubygems'
$:.unshift "#{File.dirname(__FILE__)}/../lib"
require "lab_manager"

if (ARGV.size < 4)
  puts "usage: #{File.basename __FILE__} <organization> <workspace> <configuration> <new configuration>"
  Process.exit(1)
end

organization = ARGV[0]
workspace = ARGV[1]
configuration = ARGV[2]
new_configuration = ARGV[3]

lab = LabManager.new(organization)
lab.workspace = workspace
lab.clone(configuration, new_configuration)

puts "Clone complete"

