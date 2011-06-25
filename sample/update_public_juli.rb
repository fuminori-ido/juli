#!/usr/bin/env ruby
#
# = NAME
# update_public_juli.rb   - update juli public site document
#
# = SYNOPSIS
# Following is an example to set up at cron.  Please replace YOUR_ACCOUNT,
# /PATH/TO/YOUR/RUBY/BIN, and /PATH/TO/THIS to your environment:
#
#  55 * * * * YOUR_ACCOUNT export PATH=/PATH/TO/YOUR/RUBY/BIN:$PATH; /PATH/TO/THIS/update_public_juli.rb >/var/log/update_public_juli.log 2>&1
#
#
# = DESCRIPTION
# This script does the followings:
#
# 1. git pull
# 1. update timestamp
# 1. generate HTML by juli
# 1. generate sitemap and recent_update
#
# If new file exists, whole text pages will be re-generated to HTML
# to support wiki-link to the new file which may be in the pages.


#----------------------------------------------------------
# Config
#----------------------------------------------------------

# Juli repository directory at web server for staging to
# generate HTML from juli text files:
#JULI_STAGE_DIR          = '/home/wells/nogit/juli_doc/html_stage'
JULI_STAGE_DIR          = '/home/wells/nogit/juli/public_doc'

# Command path to set commit-timestamp to each juli text file.
# git(1) doesn't keep file timestamp, but it is important for
# this kind of purpose.
#
# See https://git.wiki.kernel.org/index.php/ExampleScripts for more
# details.
GIT_SET_FILE_TIMES_CMD  = '/opt/nike/bin/git-set-file-times'


#----------------------------------------------------------
# Sub
#----------------------------------------------------------
def gather_wiki_entries
  result = []
  Dir.glob('*.txt') do |entry|
    result.push(entry)
  end
  result.sort
end

#----------------------------------------------------------
# Main
#----------------------------------------------------------
  Dir.chdir(JULI_STAGE_DIR) do
    before = gather_wiki_entries
    system 'git pull'
    system 'GIT_SET_FILE_TIMES_CMD'
    after  = gather_wiki_entries
    if before != after
      # new entry -> regenerate whole pages
      system 'juli gen -f'
    else
      system 'juli'
    end
    system 'juli sitemap'
    system 'juli recent_update'
  end
