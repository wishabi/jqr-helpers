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

Full documentation can be found [here](doc/JqrHelpers/Helpers.html).

* `link_to_dialog` - open a dialog when a link is clicked
* `button_to_dialog` - open a dialog when a button is clicked
* `confirm_button` - open a nice jQuery confirm dialog (rather than a built-in browser one)
* `link_to_remote_dialog` - open a remote dialog when a link is clicked (i.e. load
the dialog content from a remote route)
* `button_to_remote_dialog` - open a remote dialog when a button is clicked
* `link_to_ajax` - send an Ajax request when a link is clicked
* `button_to_ajax` - send an Ajax request when a button is clicked
* `form_tag_ajax` - send an Ajax request when a form is submitted
* `form_for_ajax` - ditto but using Rails's `form_for` helper
* `tab_container` - create a tab container
* `date_picker_tag` - create a date picker

There are two sets of options that recur throughout the methods here:

## Dialog Options ##

These are parameters to pass to the `jQuery.dialog()` function.
See <http://api.jqueryui.com/dialog/>.

An extra custom option is `:title` - setting it to `false` will hide the
title bar.

Another thing to note is the special values for buttons. Usually the buttons
must have JavaScript callbacks, but 99% of the time you want the classic
OK and Cancel buttons. Passing `submit` and `close` as the values
of the buttons (or the values of the "click" attribute of the buttons)
will do just that - submit the form inside the dialog or close it.

Example:

    button_to_dialog('my-dialog-id', 'Open Dialog', :buttons =>
      {'OK' => 'submit', 'Cancel' => 'close'})

You can also use a special option, `:default_buttons => true`, as a shortcut
to the above buttons, since it's so common to have an OK and Cancel
button.

Another option is `:close_x => true` - this will print a green X at the top
right of the dialog. Generally this is used when `:title => false`.

Note about dialog ID - you can always pass in the special value `:next` for
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

* `:callback` (String) - the name of a JS function to call on completion.
The function will be in the scope of the original element, and
will be passed the result data of the Ajax request.
* `:use_dialog_opener` (Boolean) - if the Ajax request is sent from inside
a dialog, this indicates that the update/append/delete options should
look at the element that opened the dialog rather than the element that
fired the Ajax request. This is true by default for forms and false for
other elements.
* `:close_dialog` (Boolean) - if the Ajax request is sent from inside a dialog,
this indicates that the dialog should be closed when the request completes
successfully. This is true by default for forms and false for
other elements.

## Panel Renderers ##

Tabs (and eventually accordion panes and menus) are rendered using a "panel renderer".
This allows you to loop through the tabs in an intuitive and concise way.

       <%= tab_container {:collapsible => true}, {:class => 'my-tabs}' do |r| %>
         <%= r.panel 'Tab 1',  do %>
           My tab content here
         <% end %>
         <%= r.panel 'Tab 2', 'http://www.foobar.com/' %>
       <% end %>

## jQuery Events ##

There are two special events triggered by jqr-helpers:

* `jqr.load` - this is triggered when a remote call populates an element with
data. The target for the event is the element which has just had data
populated.
* `jqr.beforedialogopen` - for remote dialogs, this is triggered when the
link or button is clicked to open the dialog but before the request is sent out.

***

jqr-helpers was developed by [Wishabi](http://www.wishabi.com).