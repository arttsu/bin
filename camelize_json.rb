#!/usr/bin/env ruby

# This script reads a JSON input file line by line where each line
# is its own JSON object. It converts the snake_case keys of the
# JSON object to camelCase (except for keys specified to be ignored) 
# and writes the resulting JSON object line by line to an output file.
#
# Usage: ./script_name.rb input_file output_file [keys_to_ignore]
# keys_to_ignore is optional and should be a comma-separated list of keys
#
# Dependencies:
# This script requires the `json` and `active_support` gems. 
# You can add these to your Ruby environment with `gem install json activesupport`
# if they are not already installed.

require 'json'
require 'active_support/core_ext/string'

def deep_transform_keys_in_object(object, keys_to_ignore, &block)
  case object
  when Hash
    object.each_with_object({}) do |(key, value), result|
      result[keys_to_ignore.include?(key) ? key : yield(key)] = deep_transform_keys_in_object(value, keys_to_ignore, &block)
    end
  when Array
    object.map {|e| deep_transform_keys_in_object(e, keys_to_ignore, &block) }
  else
    object
  end
end

def convert_snake_case_keys_to_camel_case(json_string, keys_to_ignore)
  json_obj = JSON.parse(json_string)
  json_obj = deep_transform_keys_in_object(json_obj, keys_to_ignore) do |key|
    key.to_s.camelize(:lower)
  end
  JSON.dump(json_obj)
end

# Check that at least two arguments have been provided
if ARGV.length < 2
  puts "Usage: #{$0} input_file output_file [keys_to_ignore]"
  exit 1
end

input_file, output_file, keys_to_ignore = ARGV

keys_to_ignore = keys_to_ignore.to_s.split(',')

begin
  File.open(output_file, 'w') do |out_file|
    File.foreach(input_file) do |line|
      result = convert_snake_case_keys_to_camel_case(line, keys_to_ignore)
      out_file.puts(result)
    end
  end
rescue Errno::ENOENT
  puts "Could not open file: #{input_file}"
  exit 1
rescue JSON::ParserError
  puts "Could not parse JSON in file: #{input_file}"
  exit 1
end

puts "Converted JSON written to: #{output_file}"
