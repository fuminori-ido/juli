#!/usr/bin/env ruby
#
# = NAME
# integration   - integration test
#
# = SYNOPSIS
# test/integration.rb
#
# = DESCRIPTION
# Run 'juli' for all of /usr/share/doc/*/**.txt to see any error/warning.
#
# This is not under 'rake test' so that it should be invoked manually.
#
# = FILES
# /usr/share/doc/*/**.txt:: test sources
# test/repo/t999.txt::      working file for this test.

require 'fileutils'

system 'rake'
#ENV['YYDEBUG'] = '1'
FileUtils.chdir('test/repo') do
  for file in Dir.glob('/usr/share/doc/*/**.txt') do
    print file, "\n"
    system 'cp', file, 't999.txt'
    system '../../bin/juli gen -g html t999.txt'
  end
  FileUtils.rm('t999.txt')
end
