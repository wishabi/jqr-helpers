require 'securerandom'

module JqrHelpers
  module Helpers

    # A renderer used for tabs, accordions, etc.
    class PanelRenderer

      # @return [Array<Hash>]
      # @private
      attr_accessor :panels

      def initialize
        self.panels = []
      end

      # Render a panel in the parent container. The panel must have either
      # a URL or a block containing content.
      # @param title [String]
      # @param url_or_options [String|Hash] If a URL is given, it will be here
      #  and the options will be the next parameter. If a block is given,
      #  this will be the option hash. Options will be passed as is into the
      #  HTML <li> tag.
      # @param options [Hash] the options if a URL is given.
      def panel(title, url_or_options={}, options={}, &block)
        if url_or_options.is_a?(String)
          url = url_or_options
          content = nil
          id = nil
        else
          options = url_or_options
          content = block
          id = Helpers._random_string
          url = '#' + id
        end
        options.merge!(:id => id)
        panels << {
          :title => title,
          :url => url,
          :options => options,
          :content => content
        }
        nil # suppress output
      end

    end

    # Add a link to create a jQuery dialog.
    # If a block is given, dialog_options and html_options are shifted left by
    # 1 and the block is used as the html_content.
    # @param dialog_id [String] The ID of the element to put in the dialog.
    # @param html_content [String] Text or HTML tags to use as the link body.
    # @param dialog_options [Hash] Dialog options as described in the readme.
    # @param html_options [Hash] Attributes to put on the link tag. There is
    #  a special :tag_name option that can be used to change the tag being
    #  created. Default is :a, but you can pass :div, :span, etc.
    # @return [String]
    def link_to_dialog(dialog_id, html_content='', dialog_options={},
      html_options={}, &block)

      if block_given?
        html_options = dialog_options
        dialog_options = html_content.presence || {}
        html_content = capture(&block)
      end

      html_options[:class] ||= ''
      html_options[:class] << ' ujs-dialog'
      html_options[:'data-dialog-id'] = dialog_id
      html_options[:'data-close-x'] = dialog_options[:close_x]

      tag_name = html_options.delete(:tag_name) || :a
      html_options[:href] = '#' if tag_name == :a

      dialog_options[:dialogClass] ||= ''
      if dialog_options[:title] == false # not nil or blank
        dialog_options[:dialogClass] << ' ujs-dialog-modal no-title'
      else
        dialog_options[:title] ||= 'Dialog'
        dialog_options[:dialogClass] << ' ujs-dialog-modal'
      end
      dialog_options[:modal] = true
      dialog_options[:width] ||= 'auto'
      if dialog_options.delete(:default_buttons)
        dialog_options[:buttons] = {
          :OK => 'submit',
          :Cancel => 'close'
        }
      end

      html_options[:'data-dialog-options'] = dialog_options.to_json

      content_tag tag_name, html_content, html_options
    end

    # Add a button to create a jQuery dialog.
    # @param dialog_id [String] The ID of the element to put in the dialog.
    # @param html_content [String] Text or HTML tags to use as the button body.
    # @param html_options [Hash] Attributes to put on the button tag.
    # @param dialog_options [Hash] Dialog options as described in the readme.
    # @return [String]
    def button_to_dialog(dialog_id, html_content, dialog_options={},
      html_options={})
      link_to_dialog(dialog_id, html_content, dialog_options,
                     html_options.merge(:tag_name => 'button'))
    end

    # Create a button that prompts a jQuery confirm dialog, which is nicer-looking
    # than the default window.confirm() which is used by Rails. Done using
    # button_to, so note that a form element will be added.
    # @param html_content [String] the text or content to go inside the button
    # @param url [String] the URL which the button should go to if confirmed
    # @param message [String] the confirm message to prompt
    # @param html_options [Hash] HTML attributes.
    def confirm_button(html_content, url, message, html_options={})
      button_to html_content, url, html_options.merge(
        :'data-message' => simple_format(message), # turn text into HTML
        :'data-ujs-confirm' => true
      )
    end

    # Same as link_to_dialog, but loads content from a remote URL instead of
    # using content already on the page.
    # If a block is given, dialog_options and html_options are shifted left by
    # 1 and the block is used as the html_content.
    # @param url [String] The URL to load the content from.
    # @param html_content [String] Text or HTML tags to use as the link body.
    # @param dialog_options [Hash] Dialog options as described in the readme.
    # @param html_options [Hash] Attributes to put on the link tag. There is
    #  a special :tag_name option that can be used to change the tag being
    #  created. Default is :a, but you can pass :div, :span, etc.
    # @return [String]
    def link_to_remote_dialog(url, html_content, dialog_options={},
      html_options={}, &block)

      if block_given?
        html_options = dialog_options
        dialog_options = html_content
        html_content = capture(&block)
      end
      html_options[:'data-throbber'] =
        dialog_options.delete(:throbber) || 'large'

      html_options[:'data-dialog-url'] = url
      link_to_dialog(Helpers._random_string, html_content,
                     dialog_options, html_options)
    end

    # Same as button_to_dialog, but loads content from a remote URL instead of
    # using content already on the page.
    # @param url [String] The URL to load the content from.
    # @param html_content [String] Text or HTML tags to use as the button body.
    # @param dialog_options [Hash] Dialog options as described in the readme.
    # @param html_options [Hash] Attributes to put on the button tag.
    # @return [String]
    def button_to_remote_dialog(url, html_content, dialog_options={},
      html_options={})
      link_to_remote_dialog(url, html_content, dialog_options,
                     html_options.merge(:tag_name => 'button'))
    end

    # Set the dialog title from +inside+ the dialog itself. This prints a
    # hidden div which is read by the UJS callback to set the title.
    def dialog_title(content)
      content_tag :div, content, :class => 'ujs-dialog-title-hidden'
    end

    # Create a link that fires off a jQuery Ajax request. This is basically
    # a wrapper around link_to :remote => true.
    # If a block is given, url and options will be shifted left by 1 position
    # and the block contents will be used for the body.
    # @param body [String] the text/content that goes inside the tag.
    # @param url [String] the URL to connect to.
    # @param options [Hash] Ajax options - see above.
    # @return [String]
    def link_to_ajax(body, url, options={}, &block)
      if block_given?
        options = url
        url = body
        body = capture(&block)
      end

      options[:remote] = true
      options.merge!(_process_ajax_options(options))

      link_to body, url, options
    end

    # Create a button that fires off a jQuery Ajax request. This does not use
    # button_to, so it can be used inside forms.
    # @param body [String] the text/content that goes inside the tag.
    # @param url [String] the URL to connect to.
    # @param options [Hash] Ajax options - see above.
    # @return [String]
    def button_to_ajax(body, url, options={})

      # Specifically do not add data-remote
      options[:'data-method'] = options.delete(:method)
      options[:'class'] ||= ''
      options[:'class'] << ' ujs-ajax-button'
      options[:'data-url'] = url
      if options.key?(:confirm)
        options[:'data-confirm'] = options.delete(:confirm)
      end
      options.merge!(_process_ajax_options(options))

      content_tag :button, body, options
    end

    # Create a form tag that submits to an Ajax request. Basically a wrapper for
    # form_tag with :remote => true.
    # @param url [String] the URL to connect to.
    # @param options [Hash] Ajax options - see above.
    # @return [String]
    def form_tag_ajax(url, options={}, &block)

      options[:remote] = true
      # note that we only override if nil - not false
      options[:close_dialog] = true if options[:close_dialog].nil?
      options[:use_dialog_opener] = true if options[:use_dialog_opener].nil?
      options.merge!(_process_ajax_options(options))

      form_tag url, options, &block
    end

    # Identical to form_tag_ajax except that this passes the given model into
    # form_for instead of form_tag.
    # @param record [ActiveRecord::Base]
    # @param options [Hash]
    # @return [String]
    def form_for_ajax(record, options={}, &block)
      options[:remote] = true
      # note that we only override if nil - not false
      options[:close_dialog] = true if options[:close_dialog].nil?
      options[:use_dialog_opener] = true if options[:use_dialog_opener].nil?
      options[:html] ||= {}
      options[:html].merge!(_process_ajax_options(options))

      form_for record, options, &block

    end

    # Print a tab container. This expects a block, which will be passed a
    # PanelRenderer object. Panels can be local (with content) or remote
    # (with a URL).
    # @example
    #   <%= tab_container {:collapsible => true}, {:class => 'my-tabs}' do |r| %>
    #     <% r.panel 'Tab 1' do %>
    #       My tab content here
    #     <% end %>
    #     <% r.panel 'Tab 2', 'http://www.foobar.com/' %>
    #   <% end %>
    # @param options [Hash] options to pass to the jQuery tabs() method.
    # @param html_options [Hash] options to pass to the tab container element
    #   itself.
    def tab_container(options={}, html_options={}, &block)
      renderer = PanelRenderer.new
      capture(renderer, &block)
      html_options[:class] ||= ''
      html_options[:class] << ' ujs-tab-container'
      html_options[:'data-tab-options'] = options.to_json
      content_tag(:div, html_options) do
        s = content_tag :ul do
          s2 = ''
          renderer.panels.each do |panel|
            s2 << content_tag(:li) do
              link_to panel[:title], panel[:url]
            end
          end
          raw s2
        end
        s3 = renderer.panels.inject('') do |sum, panel|
          if panel[:options][:id]
            sum = sum + content_tag(:div, panel[:options], &panel[:content])
          end
          sum
        end
        s + raw(s3)
      end
    end

    # Create a date picker field. The attributes given are passed to
    # text_field_tag. There is a special option :format - this expects a
    # *Ruby* style date format. It will format both the initial display of the
    # date and the jQuery date format to be the same.
    # @param name [String] the name of the form element.
    # @param value [Date] the initial value.
    # @param options [Hash] options to be passed to datepicker().
    # @param html_options [Hash] options to be passed to text_field_tag.
    # @return [String]
    def date_picker_tag(name, value=Date.today, options={}, html_options={})
      format = options.delete(:format) || '%Y-%m-%d'
      value = value.strftime(format) if value.present?
      options[:dateFormat] = _map_date(format)
      html_options[:'data-date-options'] = options.to_json
      html_options[:class] ||= ''
      html_options[:class] << ' ujs-date-picker'
      text_field_tag(name, value, html_options)
    end

    # Print a button set. Each button will be a radio button, and the group
    # will then be passed into jQuery's buttonset() method.
    # @param name [String] the name of the form element.
    # @param values [Hash<String, String>] a hash of value => label.
    # @param selected [String] the selected value, if any.
    # @param html_options [Hash] a set of options that will be passed into
    #   the parent div tag.
    def buttonset(name, values, selected=nil, html_options={})
      html_options[:class] ||= ''
      html_options[:class] << ' ujs-button-set'
      content = values.inject('') do |sum, (value, label)|
        sum += radio_button_tag(name, value, selected == value) +
          label_tag("#{name}_#{value}", label)
      end
      content_tag(:div, raw(content), html_options)
    end

    # Prints a button set which *pretends* to be a jQuery buttonset() and is
    # specifically for radio buttons. The main difference is that this will
    # load much faster in DOM-heavy pages (e.g. in tables where you may have
    # hundreds of buttons) and it does not have most of the frills of jQuery
    # button(), such as allowing disabling.
    # @param name [String] the name of the form element.
    # @param values [Hash<String, String>] a hash of value => label.
    # @param selected [String] the selected value, if any.
    # @param html_options [Hash] a set of options that will be passed into
    #   the parent div tag.
    def quick_radio_set(name, values, selected=nil, html_options={})
      html_options[:class] ||= ''
      html_options[:class] << ' ujs-quick-buttonset ui-buttonset'
      content = ''
      last_key = values.keys.length - 1
      values.each_with_index do |(value, label), i|
        content << radio_button_tag(name, value, selected == value,
                                :class => 'ui-helper-hidden-accessible')
        label_class = 'ui-button ui-widget ui-state-default ui-button-text-only'
        label_class << ' ui-state-active' if selected == value
        label_class << ' ui-corner-left' if i == 0
        label_class << ' ui-corner-right' if i == last_key
        content << label_tag("#{name}_#{value}", :class => label_class,
                             :role => 'button',
                             :'aria-disabled' => 'false') do
          content_tag :span, label, :class => 'ui-button-text'
        end
      end
      content_tag(:div, raw(content), html_options)

    end

    # This is identical to the built-in Rails button_to() in every way except
    # that it will work inside an existing form. Instead, it appends a form
    # to the body, and uses a click handler to submit it.
    # This does not support the :remote option - instead, use {#button_to_ajax}.
    # This supports the :target option to pass to the form.
    # @param content [String] the text of the button.
    # @param url [String|Hash] the URL (or URL hash) the button should go to.
    # @param options [Hash] HTML Options to pass to the button.
    def button_to_external(content, url, options={})
      options[:disabled] = 'disabled' if options.delete(:disabled)
      method = (options.delete(:method) || 'post').to_s.downcase
      confirm = options.delete(:confirm)
      disable_with = options.delete(:disable_with)

      token_name = token_value = nil
      if %w(post put).include?(method) && protect_against_forgery?
        token_name = request_forgery_protection_token.to_s
        token_value = form_authenticity_token
      end
      url = url_for(url) if url.is_a?(Hash)

      options['data-confirm'] = confirm if confirm
      options['data-disable-with'] = disable_with if disable_with
      options['data-method'] = method if method
      options['data-url'] = url
      options[:'data-target'] = options.delete(:target)
      options[:class] ||= ''
      options[:class] << ' ujs-external-button'
      if token_name
        options['data-token-name'] = token_name
        options['data-token-value'] = token_value
      end

      content_tag(:button, content, options)
    end

    # Generate a random string for IDs.
    # @return [String]
    # @private
    def self._random_string
      SecureRandom.hex(16)
    end

    # Only run this code if will_paginate is installed
    begin
      require 'will_paginate/view_helpers'
      require 'will_paginate/view_helpers/action_view'

      # Define a link renderer to use with will_paginate.
      class AjaxLinkRenderer < WillPaginate::ActionView::LinkRenderer

        # Returns the subset of +options+ this instance was initialized with
        # that represent HTML attributes for the container element of pagination
        # links.
        def container_attributes
          @container_attributes ||=
           @options.except(*(WillPaginate::ViewHelpers.pagination_options.keys +
              _ajax_keys + [:renderer] - [:class]))
        end

        protected

        def page_number(page)
          ajax_options = @options.slice(*_ajax_keys)
          if page == current_page
            tag(:em, page, :class => 'current')
          else
            link(page, page,
              ajax_options.merge(:class => 'ujs-ajax', :rel => rel_value(page)))
          end
        end

        def previous_or_next_page(page, text, classname)
          ajax_options = @options.slice(*_ajax_keys)
          if page
            link(text, page,
                 ajax_options.merge(:class => "#{classname} ujs-ajax"))
          else
            tag(:span, text,
                ajax_options.merge(:class => "#{classname} disabled"))
          end
        end

        private

        # Option keys used exclusively for jqr-helpers Ajax stuff.
        # @return [Array<Symbol>]
        def _ajax_keys
          [
            :'data-type',
            :'data-result-method',
            :'data-selector',
            :'data-remote',
            :'data-scroll-to',
            :'data-throbber'
          ]
        end

      end
    rescue # no will_paginate installed
    end

    # Create a will_paginate pagination interface which runs via Ajax. If
    # will_paginate is not in the Gemfile or gem environment, this will
    # throw an error.
    # @param collection [Array|ActiveRecord::Relation] the
    #     will_paginate collection.
    # @param to_update [String] the selector to use to update the content -
    #   either a ".class" or "#id" selector.
    # @param options [Hash] options passed through to will_paginate
    # @return [String]
    def will_paginate_ajax(collection, to_update, options={})
      if defined?(AjaxLinkRenderer)
        options[:'data-type'] = 'html'
        options[:'data-result-method'] = 'update'
        options[:'data-selector'] = to_update
        options[:'data-remote'] = true
        options[:'data-scroll-to'] = true
        options[:'data-throbber'] = options[:throbber] || 'large'
        options[:renderer] = AjaxLinkRenderer
        will_paginate(collection, options)
      else
        raise 'will_paginate not installed!'
      end
    end

    private

    # @param format [String] the Rails date format to map
    # @return [String] the jQuery date format
    def _map_date(format)
      format.gsub!(/'/, "''")
      format_map = {
        '%Y' => 'yy',
        '%y' => 'y',
        '%-d' => 'd',
        '%d' => 'dd',
        '%j' => 'oo',
        '%a' => 'D',
        '%A' => 'DD',
        '%-m' => 'm',
        '%m' => 'mm',
        '%b' => 'M',
        '%B' => 'MM'
      }
      prev_index = 0
      while true do
        format_expr = ''
        percent = format.index('%')
        break if !percent
        if percent > prev_index
          format.insert(percent, "'")
          format.insert(prev_index, "'")
          percent += 2
        end
        length = 2
        next_char = format[percent + 1]
        if next_char == '-'
          length += 1
        end
        format_expr = format[percent, length]
        new_format_expr = format_map[format_expr]
        format[percent, length] = new_format_expr
        prev_index = percent + new_format_expr.length
      end
      format

    end

    # Process options related to Ajax requests (e.g. button_to_ajax).
    # @param options [Hash]
    # @return [Hash] HTML options to inject.
    def _process_ajax_options(options)
      new_options = {}
      new_options[:class] = options[:class] || ''
      new_options[:class] << ' ujs-ajax'
      new_options[:'data-type'] = options[:return_type] || 'html'
      new_options[:'data-callback'] = options.delete(:callback)
      new_options[:'data-close-dialog'] = options.delete(:close_dialog)
      new_options[:'data-use-dialog-opener'] = options.delete(:use_dialog_opener)
      new_options[:'data-refresh'] = true if options.delete(:refresh)
      new_options[:'data-redirect'] = true if options.delete(:redirect)
      new_options[:'data-scroll-to'] = true if options.delete(:scroll_to)
      new_options[:'data-throbber'] = options.delete(:throbber) || 'small'
      new_options[:'data-empty'] = options.delete(:empty)
      new_options[:'data-container'] = options.delete(:container)

      [:update, :append, :delete].each do |result_method|
        selector = options.delete(result_method)
        if selector
          new_options[:'data-selector'] = selector
          new_options[:'data-result-method'] = result_method
        end
      end
    new_options
    end
  end
end
