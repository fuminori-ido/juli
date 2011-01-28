class Juli::Visitor::Html
  # This provides methods used in HTML Erb; called 'helper'.
  #
  # Any method here can be used at ERB template under LIB/juli/template/.
  # Where, LIB is 'lib/' directory in package environment, or
  # one of $LOAD_PATH in installed environment.
  #
  # === How to add new helper(1)
  # If new method is added in this module, it can be used as helper at
  # template ERB file.  This is the simplest case.
  #
  # === How to add new helper(2)
  # If some preparation is required before calling helper, above way is not
  # enough.  For example, recent_update() helper requires file list
  # which is sorted by descendant order of mtime timestamp.
  # It is time-consuming task to prepare such a file list on every
  # recent_update() calling.  It is enough to do that only once when juli(1)
  # is executed.
  #
  # Another example: if the same helper is called more than once in one
  # template, it could be effective to reduce the CPU resource to
  # prepare some data and store it in the helper class instance then
  # each helper uses it just to print the result.
  #
  # Juli supports such a case.  Let me assume here to write 
  # 'weather_forecast' helper, which draws some local area's
  # one week weather forecast (juli(1) is offline wiki so that
  # this kind of realtime information is not a good example though...).
  # Follow the steps below:
  # 1. Write WeatherForecast helper class file as
  #    LIB/juli/visitor/html/helper/weather_forecast.rb.
  #    (recent_update.rb could be a reference for this.)
  # 1. WeatherForecast should inherits
  #    Juli::Visitor::Html::Helper::AbstractHelper.
  # 1. implement each method: initialize, on_root, run.
  # 1. register the class at Juli::Visitor::Html::HELPER in 
  #    LIB/juli/visitor/html.rb
  #
  # Then, weather_forecast method can be used in ERB template.
  # This method is dynamically defined at Html visitor and equivalent 
  # to WeatherForecast#run.
  #
  module Helper

    # TRICKY PART: header_id is used for 'contents' helper link.
    # Intermediate::HeaderNode.dom_id cannot be used directory for
    # this purpose since when clicking a header of 'contents',
    # document jumps to its contents rather than header so that
    # header is hidden on browser.  To resolve this, header_id
    # is required for 'contents' helper and it is set at Html visitor.
    def header_id(n)
      "#{n.dom_id}_header"
    end

    # dest's relative path from src
    #
    # === EXAMPLE
    # relative_from('a.txt',   'juli.js'):: → './juli.js'
    # relative_from('a/b.txt', 'juli.js'):: → '../juli.js'
    def relative_from(src, dest)
      result = []
      Pathname.new(File.dirname(src)).descend{|dir|
        result << (dir.to_s == '.' ? '.' : '..')
      }
      File.join(result, dest)
    end

    require 'juli/visitor/html/helper/abstract_helper'

    # import all of helper/*.rb files other than abstract_helper
    Dir.glob(File.join(File.dirname(__FILE__), 'helper/*.rb')){|v|
      next if File.basename(v) == 'abstract_helper'
      require File.join('juli/visitor/html/helper', File.basename(v))
    }
  end
end
