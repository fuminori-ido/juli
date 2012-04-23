require 'fileutils'
require 'digest/sha1'
require 'RMagick'

module Juli
  module Macro
    # embed photo(image) in juli wiki text with minimum maintenance cost
    #
    # See 'doc/photo(macro).txt' for the detail.
    class Photo < Base
      include Juli::Visitor::Html::TagHelper

      PUBLIC_PHOTO_DIR_DEFAULT  = 'public_photo'
      SEED_DEFAULT              = '-- Juli seed default!! --'
      SIZE_DEFAULT              = {
        :small  => 512,   # default small width in pixel
        :large  => 1024,  # default large width in pixel
       #:same   => nil    # same as original size, but drop exif info
      }

      class DirNameConflict < Juli::JuliError; end
      class NoConfig        < Juli::JuliError; end
      class ConfigNoMount   < Juli::JuliError; end

      attr_accessor :mount
    
      def self.conf_template
        <<EOM
# (>= v1.10) photo macro setup sample is as follows.

#photo:
# mount:    /home/YOUR_NAME/Photos
# small:
#   width:  512
#   style:  'float: right'
# large:
#   width:  1024
EOM
      end

      def initialize
        super

        @conf_photo = conf['photo']
        raise NoConfig if !@conf_photo

        @mount = @conf_photo['mount']
        raise ConfigNoMount if !@mount
        @mount = File.realpath(@mount)

        @mangle = false
      end

      # rotate image to fit orientation
      def rotate(img)
        exif = img.get_exif_by_entry(:Orientation)
        return img if !(exif && exif[0] && exif[0][0] == :Orientation)
        case exif[0][1]
        when '1'  # Normal
        when '6'  #  90 degree
          img.rotate(90)    # 90[deg] to clock direction
        when '8'  # 270 degree
          img.rotate(-90)   # 90[deg] to reversed-clock direction
        else
          img
        end
      end

      # public photo directory is used to:
      #
      # * store converted photo from original one
      # * protect private photo in 'mount' directory from public web access
      #   by copying (with conversion) to it on demand.
      #
      # === INPUTS
      # url::   when true, return url, else, return physical file-system path
      def public_photo_dir(url = true)
        dir = File.join(conf['output_top'], PUBLIC_PHOTO_DIR_DEFAULT)
        raise DirNameConflict if File.file?(dir)

        if !File.directory?(dir)
          FileUtils.mkdir(dir)
        end
        url ? PUBLIC_PHOTO_DIR_DEFAULT : dir
      end

      # simplify path to the non-directory name with size.
      #
      # === Example
      # path::        a/b/c.jpg
      # photo_name::  a_b_c_#{size}.jpg (when @mangle==false)
      def photo_name(path, size)
        if @mangle
          raise 'not yet implemented'
        else
          flat = path.gsub(/\//, '_')
          sprintf("%s_%s%s",
              File.basename(flat, '.*'), size, File.extname(flat))
        end
      end

      # cached photo path
      #
      # === INPUTS
      # path::  photo-macro path argument
      # size::  :small, or :large
      # url::   when true, return url, else, return physical file-system path
      def photo_path(path, size, url = true)
        File.join(public_photo_dir(url), photo_name(path, size))
      end

      # create resized, rotated, and 'exif' eliminated cache when:
      # 1. not already created, or
      # 1. cache is obsolete
      #
      # and return the path.
      #
      # === INPUTS
      # path::  photo-macro path argument
      # size::  :small, or :large
      # url::   when true, return url, else, return physical file-system path
      def intern(path, size = :small, url = true)
        protected_path    = File.join(@mount, path)
        public_phys_path  = photo_path(path, size, false)
        if !File.exist?(public_phys_path) ||
            File::Stat.new(public_phys_path).mtime < File::Stat.new(protected_path).mtime

          img     = Magick::ImageList.new(protected_path)
          width   = if (s = @conf_photo[size.to_s]) && s['width']
                      s['width']
                    else
                      SIZE_DEFAULT[size]
                    end
          self.rotate(img).
              strip!.
              resize_to_fit(width, img.rows * width / img.columns).
              write(public_phys_path).destroy!
        end
        photo_path(path, size, url)
      end

      # return <img...> HTML tag for the photo with this macro features.
      def run(*args)
        path      = args[0].gsub(/\.\./, '')     # sanitize '..'
        style     = @conf_photo['small'] ? @conf_photo['small']['style'] : nil
        small_url = intern(path)
        large_url = intern(path, :large)
        content_tag(:a, :href=>large_url) do
          tag(:img,
              :src    => intern(path),
              :class  => 'juli_photo_small',
              :style  => style)
        end
      end
=begin
    private
      def seed
        conf['photo']['seed'] || SEED_DEFAULT
      end

      def mangle(path)
        Digest::SHA1.hexdigest(path + seed)
      end
=end
    end
  end
end