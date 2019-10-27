require 'aws-sdk-s3'
require 'fileutils'
require 'digest/sha1'
require 'rmagick'
require 'pp'
require 'tmpdir'

module Juli
  module Macro
    # embed photo(image) in juli wiki text with minimum maintenance cost
    #
    # See 'doc/photo(macro).txt' for the detail.
    class Photo < Base
      include Juli::Visitor::Html::TagHelper

      PUBLIC_PHOTO_DIR_DEFAULT  = 'public_photo'
      SEED_DEFAULT              = '-- Juli seed default!! --'
      CONF_DEFAULT = {
        'storages'  => [
          {
            'kind'    => 'local',
            'dir'     => '/home/YOUR_NAME/Photos',
          },
        ],
        'small'     => {
          'width'   => 512,           # default small width in pixel
          'style'   => 'float: right'
        },
        'large'     => {
          'width'   => 1024           # default large width in pixel
        }
      }

      class DirNameConflict < Juli::JuliError; end
      class ConfigNoMount   < Juli::JuliError; end

      def self.conf_template
        <<EOM
# Photo macro setup sample is as follows.
#
#photo:
# mount:        '#{CONF_DEFAULT['mount']}'    # DEPERECATED, use storages[].kind = 'local'
# storages:
# - kind:       local
#   dir:        '#{CONF_DEFAULT['mount']}'
# - kind:       aws
#   params:
#     region:   ap-northeast-1
#     profile:  juli
#   bucket:     juli
#   prefix:     photo
# small:
#   width:      #{CONF_DEFAULT['small']['width']}
#   style:      '#{CONF_DEFAULT['small']['style']}'
# large:
#   width:      #{CONF_DEFAULT['large']['width']}
EOM
      end

      def initialize
        super
        for storage in conf_photo && conf_photo['storages'] || {}
          if storage['kind'] == 'aws'
            _h = {}
            storage['params'].each{|k,v| _h[k.to_sym] = v}  # to sym
            @aws = ::Aws::S3::Client.new(_h)
          end
        end
      end

      def set_conf_default(conf)
        set_conf_default_sub(conf, 'photo', CONF_DEFAULT)
      end

      # rotate image to fit orientation
      def rotate(img)
        exif = img.get_exif_by_entry(:Orientation)
        return img if !(exif && exif[0] && exif[0][0] == :Orientation)
        case exif[0][1]
        when '1'  # Normal
          img
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
      # * protect private photo in 'mount' directory and storage
      #   from public web access by copying (with conversion) to it on demand.
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
      # photo_name::  a_b_c_#{size}.jpg
      def photo_name(path, size)
        flat = path.gsub(/\//, '_')
        sprintf("%s_%s%s",
            File.basename(flat, '.*'), size, File.extname(flat))
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
      # source photo is looked up under the following order:
      # 1. local directory designated by 'mount' config, if defined
      # 1. remote storage designated by 'storage' config, if defined
      #
      # === INPUTS
      # path::  photo-macro path argument
      # size::  :small, or :large
      # url::   when true, return url, else, return physical file-system path
      def intern(path, size = :small, url = true)
        if conf_photo['mount']
          STDERR.printf "DEPERECATED WARNING: 'mount' is deprecated; use 'storages'\n"
          result = intern_local_mount(conf_photo['mount'], path, size, url)
          return result if result != ''
        end

        result = intern_storages(path, size, url)
        return result if result != ''
      end

      # return <img...> HTML tag for the photo with this macro features.
      def run(*args)
        path      = args[0].gsub(/\.\./, '')     # sanitize '..'
        style     = conf_photo['small']['style']
        small_url = intern(path)
        large_url = intern(path, :large)
        content_tag(:a, :href=>large_url) do
          tag(:img,
              :src    => intern(path),
              :class  => 'juli_photo_small',
              :style  => style)
        end
      end

      def conf_photo
        @conf_photo ||= conf['photo']
      end

      private

      def set_conf_default_sub(hash, key, val)
        case val
        when Hash
          hash[key] = {} if !hash[key]
          for k, v in val do
            set_conf_default_sub(hash[key], k, v)
          end
        else
          hash[key] = val if !hash[key]
        end
      end

      # @return '' if not found
      def intern_local_mount(mount_dir, path, size, url)
        protected_path    = File.join(mount_dir, path)
        if !File.exist?(protected_path)
         #debug("DEBUG: no source photo path(#{protected_path})")
          return ''
        end

        public_phys_path  = photo_path(path, size, false)
        if !File.exist?(public_phys_path) ||
            File::Stat.new(public_phys_path).mtime < File::Stat.new(protected_path).mtime

          img     = Magick::ImageList.new(protected_path)
          width   = (s = conf_photo[size.to_s]) && s['width']
          img.resize_to_fit!(width, img.rows * width / img.columns)
          self.rotate(img).
              strip!.
              write(public_phys_path).destroy!
        end
        photo_path(path, size, url)
      end

      def intern_storages(path, size, url)
        result = ''
        for storage in conf_photo && conf_photo['storages'] || {}
          result = case storage['kind']
                   when 'local'
                    intern_local_mount(storage['dir'], path, size, url)
                   when 'aws'
                    intern_aws(storage, path, size, url)
                   else
                    raise "unsupported kind of storage(#{storage['kind']})"
                   end
          return result if result != ''
        end
      end

      # FIXME: I gave up to use 'fog' gem so that I'm using AWS S3 here now.
      # I welcome somebody implements fog version!
      def intern_aws(storage, path, size, url)
        return '' if storage.nil? || storage.empty?

        resp = nil
        begin
          resp = @aws.head_object(bucket: storage['bucket'], key: path)
        rescue ::Aws::S3::Errors::NotFound
          warn("WARN: no source photo path(#{path}) in storage")
          return ''
        end

        public_phys_path  = photo_path(path, size, false)
        if !File.exist?(public_phys_path) ||
            File::Stat.new(public_phys_path).mtime < resp.last_modified

          work_path = tmpname('juli_photo')
          resp      = @aws.get_object(bucket:           storage['bucket'],
                                      key:              path,
                                      response_target:  work_path)
          img       = Magick::ImageList.new(work_path)
          width     = (s = conf_photo[size.to_s]) && s['width']
          img.resize_to_fit!(width, img.rows * width / img.columns)
          self.rotate(img).
              strip!.
              write(public_phys_path).destroy!
         #FileUtils.rm_f(work_path)
        end
        photo_path(path, size, url)
      end

      def tmpname(base_name)
        t = Time.now.strftime("%Y%m%d")
        "/tmp/#{base_name}-#{t}-#{$$}-#{rand(0x100000000).to_s(36)}"
      end
    end
  end
end
