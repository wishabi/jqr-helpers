require 'rails'
require 'rails/generators'

module JqrHelpers
  # @private
  module Generators
    class InstallGenerator < ::Rails::Generators::Base

      desc 'This generator installs jqr-helper JavaScript, CSS, and image files.'
      source_root File.expand_path('../../../app/assets', __FILE__)

      def copy_files
        log 'Copying files...'
        files = [
          'javascripts/jqr-helpers.js',
          'images/jqr-helpers/close.png',
          'images/jqr-helpers/throbber.gif'
        ]
        if Rails.version.to_i >= 3.2
          files << 'stylesheets/jqr-helpers.css'
        end
        files.each do |file|
          copy_file file, "public/#{file}"
        end
        if Rails.version.to_i < 3.2
          copy_file 'stylesheets/jqr-helpers-legacy.css',
                    'public/stylesheets/jqr-helpers.css'
        end
      end
    end
  end
end
