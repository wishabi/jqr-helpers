module JqrHelpers
  module Helpers

    # Add a link to create a jQuery dialog.
    # If a block is given, dialog_options and html_options are shifted left by
    # 1 and the block is used as the html_content.
    # @param dialog_id [String] The ID of the element to put in the dialog.
    # @param html_content [String] Text or HTML tags to use as the link body.
    # @param dialog_options [Hash] See above.
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

      if dialog_options[:title] == false # not nil or blank
        dialog_options[:dialogClass] ||= ''
        dialog_options[:dialogClass] << ' ujs-dialog-modal no-title'
      else
        dialog_options[:title] ||= 'Dialog'
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
    # @param dialog_options [Hash] See above.
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
    # @param id [String] A unique ID to use to reference the dialog options.
    #  This is ultimately created as an element with that ID in the DOM,
    #  but the element does not have to exist already, unlike link_to_dialog.
    # @param url [String] The URL to load the content from.
    # @param html_content [String] Text or HTML tags to use as the link body.
    # @param dialog_options [Hash] See above.
    # @param html_options [Hash] Attributes to put on the link tag. There is
    #  a special :tag_name option that can be used to change the tag being
    #  created. Default is :a, but you can pass :div, :span, etc.
    # @return [String]
    def link_to_remote_dialog(id, url, html_content, dialog_options={},
      html_options={}, &block)

      if block_given?
        html_options = dialog_options
        dialog_options = html_content
        html_content = capture(&block)
      end

      html_options[:'data-dialog-url'] = url
      link_to_dialog(id, html_content, dialog_options, html_options)
    end

    # Same as button_to_dialog, but loads content from a remote URL instead of
    # using content already on the page.
    # @param id [String] A unique ID to use to reference the dialog options.
    #  This is ultimately created as an element with that ID in the DOM,
    #  but the element does not have to exist already, unlike button_to_dialog.
    # @param url [String] The URL to load the content from.
    # @param html_content [String] Text or HTML tags to use as the button body.
    # @param dialog_options [Hash] See above.
    # @param html_options [Hash] Attributes to put on the button tag.
    # @return [String]
    def button_to_remote_dialog(id, url, html_content, dialog_options={},
      html_options={})
      link_to_remote_dialog(id, url, html_content, dialog_options,
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

    # Create a button that fires off a jQuery Ajax request. This is basically
    # a wrapper around button_to :remote => true.
    # @param body [String] the text/content that goes inside the tag.
    # @param url [String] the URL to connect to.
    # @param options [Hash] Ajax options - see above.
    # @return [String]
    def button_to_ajax(body, url, options={})

      options[:remote] = true
      options[:form] ||= {}
      options[:form].merge!(_process_ajax_options(options))

      button_to body, url, options
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

    private

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
