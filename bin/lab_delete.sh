#!/usr/bin/env ruby
# ########################################################################################## 
# lab_delete.rb
#
#     bin/lab_delete.rb "ORG" "WORKSPACE" "CONFIGURATION"
# ########################################################################################## 

require 'rubygems'
$:.unshift "#{File.dirname(__FILE__)}/../lib"
require "lab_manager"

if (ARGV.size < 3)
  puts "usage: #{File.basename __FILE__} <organization> <workspace> <configuration>"
  Process.exit(1)
end

organization = ARGV[0]
workspace = ARGV[1]
configuration = ARGV[2]

lab = LabManager.new(organization)
lab.workspace = workspace
lab.delete(configuration)

puts "Delete complete"

