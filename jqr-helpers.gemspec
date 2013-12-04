Gem::Specification.new do |s|
  s.name         = 'jqr-helpers'
  s.require_paths = %w(. lib lib/jqr-helpers)
  s.version      = '1.0.10'
  s.date         = '2013-11-19'
  s.summary      = 'Helpers to print unobtrusive jQuery-UI tags.'
  s.description  = <<-EOF
    This gem allows the use of several helper methods.
    The tags output contain classes and data attributes that are grabbed by
    unobtrusive JavaScript code and turned into jQuery UI widgets.
    Helpers include Ajax requests to update elements on the page, dialogs
    (including remote dialogs), and tab containers.
EOF
  s.authors      = ['Daniel Orner']
  s.email        = 'daniel.orner@wishabi.com'
  s.files        = `git ls-files`.split($/)
  s.homepage     = 'https://github.com/wishabi/jqr-helpers'
  s.license       = 'MIT'

  s.add_dependency 'rails', '>= 3.0'
  s.add_development_dependency 'yard'

end