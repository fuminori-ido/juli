# import all of visitor/*.rb files
Dir.glob(File.join(File.dirname(__FILE__), 'visitor/*.rb')){|v|
  require File.join('juli/visitor', File.basename(v))
}
