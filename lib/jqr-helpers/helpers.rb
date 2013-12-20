require 'securerandom'

module JqrHelpers
  module Helpers

    # A renderer used for tabs, accordions, etc.
    class PanelRenderer

      # @return [Array<Hash>]
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
          content = ''
          id = nil
        else
          options = url_or_options
          content = yield
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
    def confirm_button(html_content, url, message, html_options)
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
    #     <%= r.panel 'Tab 1',  do %>
    #       My tab content here
    #     <% end %>
    #     <%= r.panel 'Tab 2', 'http://www.foobar.com/' %>
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
            sum = sum + content_tag(:div, panel[:content], panel[:options])
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
      value = value.strftime(format)
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

    # Generate a random string for IDs.
    # @return [String]
    def self._random_string
      SecureRandom.hex(16)
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
        puts "% is #{percent} prev is #{prev_index} format is #{format}"
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
      new_options[:'data-type'] = 'html'
      new_options[:'data-callback'] = options.delete(:callback)
      new_options[:'data-close-dialog'] = options.delete(:close_dialog)
      new_options[:'data-use-dialog-opener'] = options.delete(:use_dialog_opener)

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
