(function($) {
  // for older versions of jQuery UI
  if (!$().uniqueId) {
    var uuid = 1;
    $.fn.uniqueId = function() {
      return this.each(function() {
        if (!this.id) {
          this.id = 'ui-id-' + (++uuid);
        }
      });
    };
  }

  function showThrobber(element, noDisable) {
    switch ($(element).data('throbber')) {
      case 'none':
        return;
      case 'large':
        $(document.body).append('<div id="ujs-dialog-throbber">');
        break;
      default: // small or not given
        $(element).after("<img src='/images/jqr-helpers/throbber.gif' class='throbber'/>");
    }
    if (!noDisable) {
      $(element).attr('disabled', 'disabled');
    }
    // refresh disabled state
    $(element).attr('autocomplete', 'off');
  }

  function hideThrobber(element) {
    $(element).nextAll('.throbber').remove();
    $('#ujs-dialog-throbber').remove();
    $(element).removeAttr('disabled');
  }

  var ujsSubmitElement = null; // the element that submitted a form

  // called from dialog button value
  function ujsSubmitDialogForm() {
    $('.ui-dialog:visible form').first().submit();
  }

  function findDialog(element) {
    var dialog = $(element).closest('.ui-dialog-content');
    if (dialog.length == 0) dialog = $(element).find('.ui-dialog-content');
    if (dialog.length == 0) dialog = $(element).prev('.ui-dialog-content');
    return dialog;
  }

  // called from dialog button value
  // uses $.proxy to set the "this" context
  function ujsDialogClose() {
    var dialog = findDialog(this);
    if (dialog.data('remote-dialog')) {
      dialog.dialog('destroy').remove();
    }
    else {
      dialog.dialog('destroy').addClass('ujs-dialog-hidden');
    }
  }

  function ujsDialogOpen() {
    $(this).css('maxHeight', ($(window).height() * 0.8) + 'px');
    if ($(this).parent().height() > $(window).height()) {
      $(this).height($(window).height() * 0.8);
      $(this).css('overflow-y', 'auto');
    }
    $(this).parent().position({
      my: 'center',
      at: 'center',
      of: $(window)
    });
    var x = $(this).find('.ujs-dialog-x');
    if (x.length) {
      $(this).parent().append(x); // to keep it fixed to the dialog
      // don't let the dialog be resized - the resize functionality
      // clashes with the X close functionality
      $(this).dialog('option', 'resizable', false);
    }
  }

  function ujsDialogClick(event) {
    $(this).uniqueId();
    var dialogClickID = $(this).prop('id');
    var dialogID = $(this).data('dialog-id');
    var dialogElement = $('#' + dialogID);
    if (dialogID == 'next') dialogElement = $(this).next();
    if ($(this).data('close-x')) {
      dialogElement.prepend('<span class="ujs-dialog-x"></span>');
    }
    var url = $(this).data('dialog-url');
    var dialogOptions = $(this).data('dialog-options');
    var data = dialogOptions['data'];
    var open = dialogOptions['open'];
    dialogOptions = $.extend(dialogOptions, {
      'close': function() {
        $(this).dialog('destroy').addClass('ujs-dialog-hidden');
        if (url) $(this).remove();
      },
      'open': function() {
        ujsDialogOpen.call(this);
        if (open) {
          var openFunc = eval(open);
          openFunc.call(this);
        }
        if (data) {
          for (var n in data) {
            dialogElement.find('[name=' + n + ']').val(data[n]);
          }
        }
      }
    });
    if (dialogOptions.buttons) {
      $.each(dialogOptions.buttons, function(index, element) {
        if (element == 'submit') {
          dialogOptions.buttons[index] = ujsSubmitDialogForm;
        }
        else if (element.click == 'submit') {
          dialogOptions.buttons[index].click = ujsSubmitDialogForm;
        }
        else if (element == 'close') {
          dialogOptions.buttons[index] = ujsDialogClose;
        }
        else if (element.click == 'close') {
          dialogOptions.buttons[index].click = ujsDialogClose;
        }
        else {
          dialogOptions.buttons[index] = eval(element);
        }
      });
    }
    if (url) {
      $(this).trigger('jqr.beforedialogopen');
      $(document.body).append('<div class="ui-widget-overlay ui-front">');
      showThrobber($('#' + dialogClickID));
      var closeX = $(this).data('close-x');
      if (dialogElement.length == 0) {
        $('body').append("<div id='" + dialogID + "'>");
        dialogElement = $('#' + dialogID);
      }
      dialogElement.data('remote-dialog', true);
      dialogElement.load(url, function() {
        if (closeX) {
          dialogElement.prepend('<span class="ujs-dialog-x"></span>');
        }
        if (dialogElement.find('.ujs-dialog-title-hidden').length) {
          if (!dialogOptions['title'] || dialogOptions['title'] == 'Dialog')
            dialogOptions['title'] =
                dialogElement.find('.ujs-dialog-title-hidden').text();
        }
        $('.ui-widget-overlay').remove();
        hideThrobber($('#' + dialogClickID));
        $('#ujs-dialog-throbber').remove();
        $(this).dialog(dialogOptions);
        $(this).data('dialog-opener', dialogClickID);
        $(dialogElement).trigger('jqr.beforeload').trigger('jqr.load');
      });
    }
    else {
      dialogElement.data('dialog-opener', dialogClickID);
      dialogElement.dialog(dialogOptions);
    }
    event.stopPropagation();
    return false;
  }

  function ujsDialogCloseClick() {
    ujsDialogClose.call(this);
    return false;
  }

  function ujsSubmitClick(event) {
    ujsSubmitElement = event.target;
  }

  function ujsButtonClick(event) {
    var element = $(this);
    element.uniqueId(); // to store for later
    // if the button is inside a form, allowAction is already called.
    if ($(this).closest('form').length || $.rails.allowAction(element)) {
      element.data('confirm', null); // we've already fired it
      // largely copied from rails_jquery.js
      var href = element.data('url');
      var method = element.data('method');
      var csrf_token = $('meta[name=csrf-token]').attr('content');
      var csrf_param = $('meta[name=csrf-param]').attr('content');
      var form = $('<form method="post" action="' + href + '"></form>');
      var metadata_input =
          '<input name="_method" value="' + method + '" type="hidden" />';

      if (csrf_param !== undefined && csrf_token !== undefined) {
        metadata_input += '<input name="' + csrf_param + '" value="' +
            csrf_token + '" type="hidden" />';
      }

      form.hide().append(metadata_input).appendTo('body');
      if ($(element).data('params')) {
        $.each($(element).data('params'), function(name, value) {
          var input = $j('<input>', { 'name': name, 'value': value});
          form.append(input);
        });
      }
      $(form).data(element.data()); // copy to form
      $(form).data('remote', true);
      $(form).addClass('ujs-ajax');
      $(form).data('real-element', element.attr('id'));
      form.submit();
    }
    event.preventDefault();
    return false;
  }

  function ujsAjaxBeforeSend() {
    var element = $(this);
    if (element.data('real-element')) {
      element = $('#' + element.data('real-element'));
    }
    if (element.is('form')) {
      if ($(ujsSubmitElement).parents('form').index(element) >= 0)
        element = ujsSubmitElement;
      else
        $(element).data('throbber', 'large');
    }
    // can't disable form fields because then they won't receive
    // the success event
    var name = $(element).prop('tagName').toUpperCase();
    showThrobber(element,
        (name == 'INPUT' || name == 'SELECT' || name == 'TEXTAREA'));
  }

  function ujsAjaxSuccess(evt, data, status, xhr) {
    var element = $(this);
    if (element.data('real-element')) {
      element = $('#' + element.data('real-element'));
    }
    var disableElement = element;
    if (element.is('form') &&
        $(ujsSubmitElement).parents('form').index(element) >= 0)
      disableElement = ujsSubmitElement;
    hideThrobber(disableElement);
    var targetElement = element;

    if (element.data('redirect') &&
        (data.indexOf('http') == 0 || data[0] == '/')) {
      window.location = data;
      return;
    }
    else if (!element.data('callback') && data &&
        data.trim().charAt(0) != '<' && data != 'success') {
      alert(data);
      return;
    }
    // if this was sent from a dialog, close the dialog and look at the
    // element that opened it for update/append/delete callbacks.
    if ($('.ui-dialog:visible').length) {
      if (element.data('use-dialog-opener')) {
        var dialog = findDialog(this);
        targetElement = $('#' + dialog.data('dialog-opener'));
      }
      if (element.data('close-dialog'))
        ujsDialogClose.call(element);
    }
    if (element.data('refresh')) {
      window.location.reload();
      return;
    }
    if (element.data('callback')) {
      var callback = eval(element.data('callback'));
      callback.call(targetElement, data);
    }
    var selector = element.data('selector');
    var empty = element.data('empty');
    var container = element.data('container');
    var target = null;
    if (selector) {
      if (selector[0] == '#') target = $(selector);
      else target = $(targetElement).parents(selector);

      if (container) {
        if (container[0] == '#') container = $(container);
        else container = targetElement.parents(container);
      }

      switch (element.data('result-method')) {
        case 'update':
          target.trigger('jqr.beforeload');
          // sometimes this adds text nodes
          target = $(data).replaceAll(target).filter(function() {
            return this.nodeType == 1;
          });
          target.trigger('jqr.load');
          break;
        case 'append':
          target.trigger('jqr.beforeload');
          if (empty && target.children().length == 0) {
            $('#' + empty).hide();
            if (container) {
              container.show();
            }
            else {
              target.show();
            }
          }
          target.append(data);
          target.trigger('jqr.load');
          break;
        case 'delete':
          target.trigger('jqr.beforeload');
          if (empty && target.parent().children().length == 1) {
            if (container) {
              container.hide();
            }
            else {
              target.parent().hide();
            }
            $('#' + empty).show();
            $(target).remove();
          }
          else {
            target.fadeOut(500, function() {$(this).remove()});
          }
          break;
      }
      target.effect('highlight');
      if (element.data('scroll-to')) {
        target[0].scrollIntoView(true);
      }
    }
    return false;
  }

  function ujsAjaxError(evt, xhr, status, error) {
    alert(error || 'An error occurred.');
    var element = $(this);
    if (element.data('real-element')) {
      element = $('#' + element.data('real-element'));
    }
    var disableElement = element;
    if (element.is('form') &&
        $(ujsSubmitElement).parents('form').index(element) >= 0)
      disableElement = ujsSubmitElement;
    hideThrobber(disableElement);
  }

  function ujsConfirmClick() {
    var div = $('<div>');
    var form = this.form;
    div.html($(this).data('message'));
    $('body').append(div);
    div.dialog({
      modal: true,
      width: 'auto',
      maxWidth: '75%',
      minWidth: '400',
      minHeight: 'auto',
      dialogClass: 'confirm-dialog no-title',
      buttons: {
        'Yes': function() {
          form.submit();
        },
        'No': function() {
          div.dialog('close');
          div.remove();
        }
      }
    });
    return false;
  }

  function updateQuickButton(radio, label) {
    var form = radio[0].form;
    var name = $(radio).attr('name');
    $(form).find('input[name="' + name + '"]').each(function() {
      $(this).next('label').removeClass('ui-state-active');
    });

    label.addClass('ui-state-active');

  }

  function ujsQuickButtonChange(event) {
    var radio = $(event.currentTarget);
    var label = radio.next('label');
    updateQuickButton(radio, label);
  }

  function ujsQuickButtonClick(event) {
    var label = $(event.currentTarget);
    var radio = label.prev('input');
    updateQuickButton(radio, label);
  }

  function ujsQuickButtonHover(event) {
    $(event.currentTarget).toggleClass('ui-state-hover');
  }

  function ujsToggleClick() {
    var id = $(this).data('id');
    var target = $('#' + id);
    $('#' + id).toggle();
    if ($(target).is(':visible')) {
      $(this).addClass('ujs-toggle-open').removeClass('ujs-toggle-closed');
    }
    else {
      $(this).removeClass('ujs-toggle-open').addClass('ujs-toggle-closed');
    }
  }

  function ujsLoadPlugins(event) {

    $('.ujs-quick-buttonset input:checked').change();

    function addHiddenField(form, name, value) {
      var input = $('<input type="hidden">');
      input.attr('name', name);
      input.attr('value', value);
      form.append(input);
    }

    $('.ujs-external-button').each(function() {
      var button = $(this);
      var form = $('<form>');
      var method = button.data('method');
      if (method == 'put' || method == 'delete') {
        form.attr('method', 'post');
        addHiddenField(form, '_method', method);
      }
      else {
        form.attr('method', method);
      }
      form.attr('action', button.data('url'));
      form.attr('target', button.data('target'));
      if (method != 'get') {
        form.attr('rel', 'nofollow');
        addHiddenField(form, button.data('token-name'),
            button.data('token-value'));
      }
      $('body').append(form);
      button.click(function(event) {
        event.stopImmediatePropagation();
        if (!$.rails.allowAction(button)) {
          return false;
        }
        if (button.data('disable-with')) {
          button.html(button.data('disable-with'));
          button.attr('disabled', 'disabled');
          button.attr('autocomplete', 'off');
        }
        form.submit();
        return false;
      });
    });
    $('.ujs-date-picker', event.target).each(function() {
      var options = $(this).data('date-options');
      $(this).datepicker(options);
    });

    $('.ujs-button-set', event.target).each(function() {
      $(this).buttonset();
    });

    $('.ujs-tab-container', event.target).each(function() {
      var options = $(this).data('tab-options');
      options = $.extend(options, {
        beforeLoad: function(event, ui) {
          if (ui.tab.data('loaded')) {
            event.preventDefault();
            return;
          }
          ui.jqXHR.success(function() {
            ui.tab.data('loaded', true);
          });
          $(ui.panel).html('Loading...');
          ui.jqXHR.fail(function(jqXHR, textStatus, errorThrown) {
            ui.panel.html('Error loading the tab: ' + errorThrown);
          });
        }
      });
      $(this).tabs(options);
    });

    // observe fields
    $('.ujs-ajax-change').each(function() {
      var dataAttrs = ['type', 'callback', 'refresh', 'redirect', 'scroll-to',
        'throbber', 'empty', 'container', 'selector', 'result-method', 'url',
        'method', 'params'];
      var dataMap = {};
      var element = $(this);
      $.each(dataAttrs, function(index, val) {
        dataMap[val] = element.data(val);
        element.removeAttr('data-' + val);
      });
      element.removeClass('ujs-ajax');
      // we have to set a data-remote attribute because Rails uses [data-remote]
      // as a selector rather than checking the actual data in the element
      $(this).find('input, select').data(dataMap).addClass('ujs-ajax').
          attr('data-remote', 'true');
    });
    $(event.target).trigger('jqr.afterload');
  }

  $(function() {
    if ($().on) { // newer jQueries
      $(document).on('jqr.load', ujsLoadPlugins);
      $(document).on('click', 'input[type=submit]', ujsSubmitClick);
      $(document).on('click', '.ujs-dialog', ujsDialogClick);
      $(document).on('click', '.ujs-dialog-close, .ujs-dialog-x',
          ujsDialogCloseClick);
      $(document).on('click', '.ujs-ajax-button', ujsButtonClick);
      $(document).on('ajax:beforeSend', '.ujs-ajax', ujsAjaxBeforeSend);
      $(document).on('ajax:success', '.ujs-ajax', ujsAjaxSuccess);
      $(document).on('ajax:error', '.ujs-ajax', ujsAjaxError);
      $(document).on('click', '[data-ujs-confirm=true]', ujsConfirmClick);
      $(document).on('change', '.ujs-quick-buttonset input',
          ujsQuickButtonChange);
      $(document).on('click', '.ujs-quick-buttonset label',
          ujsQuickButtonClick);
      $(document).on('mouseenter mouseleave', '.ujs-quick-buttonset label',
          ujsQuickButtonHover);
      $(document).on('click', '.ujs-toggle', ujsToggleClick);
    }
    else {
      $('body').live('jqr.load', ujsLoadPlugins);
      $('input[type=submit]').live('click', ujsSubmitClick);
      $('.ujs-dialog').live('click', ujsDialogClick);
      $('.ujs-dialog-close, .ujs-dialog-x').live('click', ujsDialogCloseClick);
      $('.ujs-ajax-button').live('click', ujsButtonClick);
      $('.ujs-ajax').live('ajax:beforeSend', ujsAjaxBeforeSend);
      $('.ujs-ajax').live('ajax:success', ujsAjaxSuccess);
      $('.ujs-ajax').live('ajax:error', ujsAjaxError);
      $('[data-ujs-confirm=true]').live('click', ujsConfirmClick);
      $('.ujs-quick-buttonset input').live('change', ujsQuickButtonChange);
      $('.ujs-quick-buttonset label').live('click', ujsQuickButtonClick);
      $('.ujs-quick-buttonset label').live('mouseenter mouseleave',
          ujsQuickButtonHover);
      $('.ujs-toggle').live('click', ujsToggleClick);
    }
    $('body').trigger('jqr.beforeload').trigger('jqr.load');
  });

}(jQuery));

