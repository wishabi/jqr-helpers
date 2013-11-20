require 'helpers'

module JqrHelpers
  class Railtie < Rails::Railtie
    initializer 'jqr-helpers.helpers' do
      ActionView::Base.send :include, Helpers
    end
    generators do
      require 'install_generator'
    end
  end
end