(function($) {
  function showThrobber(element) {
    $(element).after("<img src='/images/jqr-helpers/throbber.gif' class='throbber'/>");
    $(element).attr('disabled', 'disabled');
  }

  function hideThrobber(element) {
    $(element).nextAll('.throbber').remove();
    $(element).removeAttr('disabled');
  }

  var ujsDialogElement = null; // the element that opened the dialog
  var ujsSubmitElement = null; // the element that submitted a form

  // called from dialog button value
  function ujsSubmitDialogForm() {
    $('.ui-dialog:visible form').first().submit();
  }

  // called from dialog button value
  function ujsDialogClose() {
    $('.ui-dialog-content:visible').dialog('destroy')
        .addClass('ujs-dialog-hidden');
  }

  function ujsDialogOpen() {
    if ($(this).parent().height() > $(window).height()) {
      $(this).height($(window).height() * 0.8);
      $(this).parent().css('top',
          ($(window).height() - $(this).parent().height()) / 2
      );
      $(this).css('overflow-y', 'auto');
    }
    var x = $(this).find('.ujs-dialog-x');
    if (x.length) {
      $(this).parent().append(x); // to keep it fixed to the dialog
      // don't let the dialog be resized - the resize functionality
      // clashes with the X close functionality
      $(this).dialog('option', 'resizable', false);
    }
  }

  function ujsDialogClick(event) {
    ujsDialogElement = $(this);
    var dialogID = $(this).data('dialog-id');
    var dialogElement = $('#' + dialogID);
    if (dialogID == 'next') dialogElement = $(this).next();
    if ($(this).data('close-x')) {
      dialogElement.prepend('<span class="ujs-dialog-x"></span>');
    }
    var url = $(this).data('dialog-url');
    var dialogOptions = $(this).data('dialog-options');
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
      });
    }
    if (url) {
      $(this).trigger('jqr.beforedialogopen');
      $(document.body).append('<div class="ui-widget-overlay ui-front">');
      $(document.body).append('<div id="remote-dialog-throbber">');
      if (dialogElement.length == 0) {
        $('body').append("<div id='" + dialogID + "'>");
        dialogElement = $('#' + dialogID);
        if ($(this).data('close-x')) {
          dialogElement.prepend('<span class="ujs-dialog-x"></span>');
        }
      }
      dialogElement.load(url, function() {
        $('.ui-widget-overlay').remove();
        $('#remote-dialog-throbber').remove();
        $(this).dialog(dialogOptions);
        $(dialogElement).trigger('jqr.load');
      });
    }
    else {
      dialogElement.dialog(dialogOptions);
    }
    event.stopPropagation();
    return false;
  }

  function ujsDialogCloseClick() {
    ujsDialogClose();
    return false;
  }

  function ujsSubmitClick(event) {
    ujsSubmitElement = event.target;
  }

  function ujsButtonClick(event) {
    var element = $(this);
    element.uniqueId(); // to store for later
    element.data('confirm', null); // we've already fired it
    if ($.rails.allowAction(element)) {
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
    if (element.is('form') &&
        $(ujsSubmitElement).parents('form').index(element) >= 0)
      element = ujsSubmitElement;
    showThrobber(element);
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
    // if this was sent from a dialog, close the dialog and look at the
    // element that opened it for update/append/delete callbacks.
    if ($('.ui-dialog:visible').length) {
      if (element.data('use-dialog-opener'))
        targetElement = ujsDialogElement;
      if (element.data('close-dialog'))
        ujsDialogClose();
    }
    if (element.data('callback')) {
      var callback = eval(element.data('callback'));
      callback.call(targetElement, data);
    }
    else if (data && data.trim().charAt(0) != '<' && data != 'success') {
      alert(data);
      return;
    }
    var selector = element.data('selector');
    var target = null;
    if (selector) {
      if (selector[0] == '#') target = $(selector);
      else target = $(targetElement).parents(selector);
      switch (element.data('result-method')) {
        case 'update':
          target = $(data).replaceAll(target);
          target.trigger('jqr.load');
          break;
        case 'append':
          target.append(data);
          target.trigger('jqr.load');
          break;
        case 'delete':
          target.fadeOut(500, function() {$(this).remove()});
          break;
      }
      target.effect('highlight');
    }
    return false;
  }

  function ujsAjaxError(evt, xhr, status, error) {
    alert(error || 'An error occurred.');
    hideThrobber(this);
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

  function ujsLoadPlugins(event) {
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
    }
    $('body').trigger('jqr.load');

    // Derived from
    // https://makandracards.com/makandra/3877-re-enable-submit-buttons-disabled-by-the-disabled_with-option
    $(window).unload(function() {
      $.rails.enableFormElements($($.rails.formSubmitSelector));
      $('input[disabled],button[disabled],select[disabled]').prop('disabled', false);
    });

  });

}(jQuery));

