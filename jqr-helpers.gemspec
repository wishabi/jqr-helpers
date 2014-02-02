Gem::Specification.new do |s|
  s.name         = 'jqr-helpers'
  s.require_paths = %w(. lib lib/jqr-helpers)
  s.version      = '1.0.29'
  s.date         = '2014-02-02'
  s.summary      = 'Helpers to print unobtrusive jQuery-UI tags.'
  s.description  = <<-EOF
    This gem adds helper methods to create unobtrusive jQuery code. It outputs
    HTML, which is hooked by an included JavaScript file to provide the
    functionality. Helpers include links to Ajax requests to update elements on
    the page, dialogs (including remote dialogs), date pickers and tab containers.
EOF
  s.authors      = ['Daniel Orner']
  s.email        = 'daniel.orner@wishabi.com'
  s.files        = `git ls-files`.split($/)
  s.homepage     = 'https://github.com/wishabi/jqr-helpers'
  s.license       = 'MIT'
  s.requirements  << 'Optionally install will_paginate to allow Ajax pagination'

  s.add_dependency 'rails', '>= 3.0'
  s.add_development_dependency 'yard'

end