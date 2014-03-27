require 'helpers'
require 'engine'

module JqrHelpers
  # @private
  class Railtie < Rails::Railtie
    initializer 'jqr-helpers.helpers' do
      ActionView::Base.send :include, Helpers
    end
    generators do
      require 'install_generator'
    end
  end
end