# Jqr-Helpers

`jqr-helpers` is a set of methods that create tags that are watched by unobtrusive JavaScript
events. It is primarily designed to cut down on JavaScript event handling and
callbacks and try to allow as much as possible to happen with Rails helpers.

The two main uses of these methods are to create dialogs and handle
Ajax requests without having to write JavaScript code. In particular, the options
available to the methods provide more support for the most common ways of using
these sorts of things in a web application environment.

Although there is some overlap with Rails 3 UJS methods, the important part
is the added options available. These make more assumptions than the built-in
helper methods, but are optimized to make it much easier to use them in
common scenarios. The existing methods are not altered.

jqr-helpers was developed using jQuery 1.10 and jQuery-UI 1.10, but it should
be compatible with earlier versions as well. The assumption is that all
required JS files are included, including jQuery, jQuery-UI, and the jquery-rails
UJS adapter. jqr-helpers does not attempt to include them itself.

## Using jqr-helpers ##

If you are running Rails >= 3.1, the required assets should be installed
automatically as part of the asset pipeline. You can require them as needed:

    //= require jqr-helpers
    *= require jqr-helpers

If you are running Rails 3.0, you can manually copy the JavaScript and CSS
into your public folders:

    rails g jqr_helpers:install

## Helper Methods ##

Full documentation can be found [here](https://rawgithub.com/wishabi/jqr-helpers/master/doc/JqrHelpers/Helpers.html).

* `link_to_dialog` - open a dialog when a link is clicked
* `button_to_dialog` - open a dialog when a button is clicked
* `confirm_button` - open a nice jQuery confirm dialog (rather than a built-in browser one)
* `link_to_toggle` - when clicked, the link will toggle visibility for another element
* `button_to_toggle`- when clicked, the button will toggle visibility for another element
* `link_to_remote_dialog` - open a remote dialog when a link is clicked (i.e. load
the dialog content from a remote route)
* `button_to_remote_dialog` - open a remote dialog when a button is clicked
* `dialog_title` - set the dialog title from inside remote content
* `link_to_ajax` - send an Ajax request when a link is clicked
* `button_to_ajax` - send an Ajax request when a button is clicked
* `form_tag_ajax` - send an Ajax request when a form is submitted
* `form_for_ajax` - ditto but using Rails's `form_for` helper
* `tab_container` - create a tab container
* `date_picker_tag` - create a date picker
* `buttonset` - create a radio button set
* `quick_radio_set` - create a radio button set FAST - these are not true jQuery UI buttons but
they load a heck of a lot faster when you have dozens or hundreds of them.
* `button_to_external` - create a working `button_to` button inside an existing form (!)
* `will_paginate_ajax` - create a `will_paginate` interface that uses Ajax to
replace the paginated contents.
* `ajax_change` - monitor any inputs inside the given block for changes
and send to the Ajax URL when they happen.

There are two sets of options that recur throughout the methods here:

## Dialog Options ##

These are parameters to pass to the `jQuery.dialog()` function.
See <http://api.jqueryui.com/dialog/>.

Additional or changed options:

* `:title` - setting this to `false` will hide the title bar.
* `:buttons`: Usually the buttons must have JavaScript callbacks, but 99% of the
time you want the classic OK and Cancel buttons. Passing `submit` and `close`
as the values of the buttons (or the values of the "click" attribute of the
buttons) will do just that - submit the form inside the dialog or close it.

Example:

    button_to_dialog('my-dialog-id', 'Open Dialog', :buttons =>
      {'OK' => 'submit', 'Cancel' => 'close'})

* `:default_buttons`: This is a special option which acts as a shortcut
to the above example, since it's so common to have an OK and Cancel button.
* `:close_x => true`: this will print a green X at the top
right of the dialog. Generally this is used when `:title => false`.
*`:data`: this accepts a hash of string/value pairs. When this
is given, jqr-helpers will search the dialog for input fields whose names
match the keys and populate them with the values. This is helpful when you want
to pass data to a local dialog but don't want to mess around with saving data
attributes and callbacks. When using a remote dialog it's easier to just pass
the data into the URL and have Rails populate it on the server side.
*`:throbber`: For remote dialogs only. This can be `:small`, `:large`, or
`:none`. By default it is `:large`, indicating a throbber that goes in front
of the screen. `:small` would be a small inline throbber next to the button or
link that called the dialog, and `:none` shows no throbber at all.

A separate method `dialog_title` allows you to set the dialog title in a
remote dialog from _within_ the remote content. This allows you to reuse the
remote content and call it from multiple pages while still showing the same
title.

A note about dialog ID - you can always pass in the special value `:next` for
this. This will use whatever element is just after the clicked element
for the dialog contents. This can be useful for printing simple dialogs inside a
foreach loop that shouldn't require a totally separate route + view.

Dialogs will by default be centered on the page and have a max height of 80%
the page height.

## Ajax Options ##

By default, the `options` parameter in the various `_to_ajax` functions are
passed into the underlying function (e.g. `link_to_ajax` will pass them to
`link_to`), but there is support for several special options as well.

*Selector options* will act on another element once the request is complete.
Selectors can be IDs (`#selector`), or classes (`.selector`).
A class selector will be interpreted as an *ancestor* (parent) of the
element that sent the request that has the given class. So e.g. if you
are using `button_to_ajax`, giving `:update => '.my-parent'` will look for
an ancestor of the button tag with the class of `my-parent`.

* `:update` - update the given selector with the returned content.
* `:append` - insert the content as a child inside the given selector.
* `:delete` - delete all content of the given selector.

Other Ajax options:

* `:return_type` (String) - the expected return type, e.g. 'text' or 'html'.
* `:method` (String) - GET, POST, PUT, or DELETE, if the default is incorrect
  (GET for links, POST for forms and buttons).
* `:empty` (String) - the ID of an element which should be shown when the
element you are appending/deleting from is empty. If you delete the last child
from an element, that element will be hidden and the "empty" element will
be shown. Conversely, when you add a child to a target with no children, the
"empty" element will be hidden. Using `empty` without `container` implies that
the target element's parent should be hidden when the last child is deleted.
* `container` (String) - the selector (ID or class name for a parent) of the
element which contains the target. For example, if you are appending to a
`tbody` element, you may pass the `table` element's ID into this. This can be
used in conjunction with `empty` to hide the entire table, including the header,
when it is empty and instead show the `empty` element, and vice versa.
You can skip using this option to indicate that the show/hide
behavior should still happen but it should use the target element itself.
* `:callback` (String) - the name of a JS function to call on completion.
The function will be in the scope of the original element, and
will be passed the result data of the Ajax request.
* `:refresh` (Boolean) - refresh the current page when the call is completed.
This will cause `:update, :append, :delete,` `redirect`,
and `:callback` to be ignored.
* `redirect` (Boolean) - redirect the browser to the URL returned by the
server. This will check the returned data - if it begins with either "http"
or "/", it will consider it a success and do the redirect. Otherwise, it will
alert an error as usual.
This will cause `:update, :append, :delete,` and `:callback` to be ignored.
* `:use_dialog_opener` (Boolean) - if the Ajax request is sent from inside
a dialog, this indicates that the update/append/delete options should
look at the element that opened the dialog rather than the element that
fired the Ajax request. This is true by default for forms and false for
other elements.
* `:close_dialog` (Boolean) - if the Ajax request is sent from inside a dialog,
this indicates that the dialog should be closed when the request completes
successfully. This is true by default for forms and false for
other elements.
* `:alert_message` (Boolean) - if true, a string response which is *not*
`success` will not be considered an error - it will be alerted to the user
but will not stop the normal functionality from proceeding.
* `:scroll_to` (Boolean) - if given, the element that was updated or inserted
will be scrolled into view (i.e. its top will be aligned with the top of the
page).
* `:throbber` (String) - This can be `:small`, `:large`, or
`:none`. By default for most Ajax requests it is `:small`, indicating
a small inline throbber next to the button or link. For ``link_to_dialog`` and
``button_to_dialog``, the default is ``:large``, meaning a throbber that goes in
front of the screen.`:none` shows no throbber at all.

## Render Responses ##

For Ajax options, `update` and `append` expect HTML responses. Generally
you would do this in your Rails controller by rendering a partial, or a view
with `:layout => false`. Conversely, when using `delete`, the JS expects a
simple text response of `success` since there it is simply deleting a row.

If you want to alert a message and *also* accomplish the default functionality
(such as updating HTML or closing a dialog box), simply use the `alert_message`
option in your Ajax link/button/form.

## Monitoring Fields ##

You can monitor a field for changes using the ``ajax_change`` method:

    <%= ajax_change('/toggle_complete_url', :update => '.parent-row') do %>
      <%= check_box_tag 'toggle_complete', 1, my_model.complete? %>
      <%= hidden_field_tag :additional_field, 'additional_value' %>
    <% end %>

## Panel Renderers ##

Tabs (and eventually accordion panes and menus) are rendered using a "panel renderer".
This allows you to loop through the tabs in an intuitive and concise way.

    <%= tab_container {:collapsible => true}, {:class => 'my-tabs}' do |r| %>
      <% r.panel 'Tab 1' do %>
        My tab content here
      <% end %>
      <% r.panel 'Tab 2', 'http://www.foobar.com/' %>
    <% end %>

## jQuery Events ##

There are a few special events triggered by jqr-helpers:

* `jqr.load` - this is triggered when a remote call populates an element with
data. The target for the event is the element which has just had data
populated.
* `jqr.beforeload` - triggered just before `jqr.load`. This is useful if you
want to make massage your DOM before allowing jqr-helpers to do its magic.
* `jqr.afterload` - triggered just after `jqr.load`, allowing you to ensure
jqr-helper's stuff is done *before* yours.
* `jqr.beforedialogopen` - for remote dialogs, this is triggered when the
link or button is clicked to open the dialog but before the request is sent out.

## will_paginate ##

jqr-helpers supports an Ajax version of [will_paginate](https://github.com/mislav/will_paginate).
This replaces each link with an Ajax link and will load the content of the page
into the supplied element.

***

jqr-helpers was developed by [Wishabi](http://www.wishabi.com).