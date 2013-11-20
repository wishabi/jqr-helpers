require 'jqr-helpers/version'
require 'action_view/base'

module JqrHelpers
  module Rails
    class Engine < ::Rails::Engine
      config.to_prepare do
        ActionView::Base.send :include, JqrHelpers::Helpers
      end
    end
  end
end
