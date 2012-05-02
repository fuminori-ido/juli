#!/usr/bin/env ruby
#
# = NAME
# tag_dump.rb   - dump tag
#
# = SYNOPSIS
# cd $JULI_REPO
# test/script/tag_dump.rb
#
# = DESCRIPTION

$LOAD_PATH.insert(0, File.join(File.dirname(__FILE__), '../../lib'))

require 'juli'
require 'juli/command'
require 'juli/visitor'
require 'juli/absyn'
require 'juli/visitor/html'

include Juli::Util

t = Juli::Macro::Tag.new
t.dump
