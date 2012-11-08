#!/usr/bin/env ruby
# ########################################################################################## 
# lab_machines.rb
#
#     bin/lab_machines.rb "ORG" "WORKSPACE" "CONFIGURATION" 
#     bin/lab_machines.rb "ORG" "WORKSPACE" "CONFIGURATION" "excludeMachine1" "excludeMachine2"
# ########################################################################################## 

require 'rubygems'
$:.unshift "#{File.dirname(__FILE__)}/../lib"
require "lab_manager"

if (ARGV.size < 3)
  puts "usage: #{File.basename __FILE__} <organization> <workspace> <configuration> [<machine to exclude> ...]"
  Process.exit(1)
end

organization = ARGV[0]
workspace = ARGV[1]
configuration = ARGV[2]
excludeMachines = ARGV[3..-1]

lab = LabManager.new(organization)
lab.workspace = workspace
machines = lab.machines(configuration, :exclude => excludeMachines)

Machine.to_csv(machines)

