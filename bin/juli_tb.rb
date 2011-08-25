#!/usr/bin/env ruby
#
# = NAME
# juil_tb.rb    - track back to external site
#
# = SYNOPSIS
# juli_tb.rb trackback-url juli-url [title [exerpt [blog_name]]]
#
# = DESCRIPTION
# Send 'trackback ping' to the requesting trackback-url.
# Response XML body, which is sent back from the target trackback,
# is printed to stdout.  If the value in <error>...</error>
# is 0 then it means successful.

$LOAD_PATH.insert(0, File.join(File.dirname(__FILE__), '../lib'))

require 'optparse'
require 'cgi'
require 'net/http'
require 'juli'


#------------------------------------------------------------------
# Global variable
#------------------------------------------------------------------
Version = Juli::VERSION
USAGE   = "USAGE: juli_tb.rb trackback-url juli-url [title [exerpt [blog_name]]]"


Net::HTTP.version_1_2

#------------------------------------------------------------------
# Subroutines
#------------------------------------------------------------------
# print usage and exit with errno==2
def usage(msg)
  STDERR.printf("%s\n\n%s\n", msg, USAGE)
  exit(2)
end

# check required arg and return if exists
def check_arg(arg, msg)
  usage(msg) if !arg
  arg
end

# generate url-encoded from hash.  skip if value is nil
def to_query(hash)
  a = []
  for k, v in hash do
    a << "#{k}=#{CGI.escape(v)}" if v
  end
  a.join('&')
end


#-------------------------------------------------------------------
# Main
#-------------------------------------------------------------------
  opt = OptionParser.new(USAGE)
  opt.parse!(ARGV)

  tb_url    = check_arg(ARGV[0], 'no trackback-url')
  juli_url  = check_arg(ARGV[1], 'no juli-url')
  form      = to_query(
                'url'       => juli_url,
                'title'     => ARGV[2],
                'exerpt'    => ARGV[3],
                'blog_name' => ARGV[4])
  usage('too much arguments') if ARGV[5]

  uri = URI.parse(tb_url)
  Net::HTTP.start(uri.host, uri.port) do |http|
    res = http.post(uri.path, form)
    print res.body.to_s
  end
