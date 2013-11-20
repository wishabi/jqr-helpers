require 'rails'

class JqrHelpersGenerator < ::Rails::Generators::Base

  desc 'This generator installs jqr-helper JavaScript, CSS, and image files.'
  puts source_root
  source_root File.expand_path('../../../../../app/assets', __FILE__)

  def copy_files
    log 'Copying files...'
    files = [
      'javascripts/jqr-helpers.js',
      'stylesheets/jqr-helpers.css',
      'images/jqr-helpers/close.png',
      'images/jqr-helpers/throbber.gif'
    ]
    files.each do |file|
      copy_file file, "public/#{file}"
      log "#{file} copied."
    end
  end
end
