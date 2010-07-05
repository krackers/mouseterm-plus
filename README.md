MouseTerm
=========

MouseTerm is a [SIMBL][1] plugin for Mac OS X's [Terminal.app][2] that passes
mouse events to the terminal, allowing you to use mouse shortcuts within
applications that support them.

To get started, first install [SIMBL][1] (MouseTerm won't work without it!).
Once you've done that, open the `.dmg` file, run `Install`, and restart
Terminal.app. To uninstall, run `Uninstall` from the `.dmg`.

[1]: http://www.culater.net/software/SIMBL/SIMBL.php
[2]: http://www.apple.com/macosx/technology/unix.html


Download
--------

* [MouseTerm.dmg][3] (99 KB, requires Leopard or newer)

[3]: http://bitheap.org/mouseterm/MouseTerm.dmg


Status
------

MouseTerm is currently alpha quality software. Some features have not yet
been implemented, and there may be bugs in the current implementation.

What works:

* Mouse button reporting.
* Mouse scroll wheel reporting.
* Simulated mouse wheel scrolling for programs like `less` (i.e. any
  fullscreen program that uses [application cursor key mode][4]).

What's being worked on:

* A preferences dialog and terminal profile integration.

[4]: http://the.earth.li/~sgtatham/putty/0.60/htmldoc/Chapter4.html#config-appcursor


Frequently Asked Questions
--------------------------

> What programs can I use the mouse in?

This varies widely and depends on the specific program. `less`, [Emacs][5],
and [Vim][6] are good places to test out mouse reporting.

> How do I enable mouse reporting in Vim?

To enable the mouse for all modes add the following to your `~/.vimrc` file:

    if has("mouse")
        set mouse=a
    endif

Run `:help mouse` for more information and other possible values.

> What about enabling it in Emacs?

By default MouseTerm will use simulated mouse wheel scrolling in Emacs. To
enable terminal mouse support, add this to your `~/.emacs` file:

    (unless window-system
      (xterm-mouse-mode 1)
      (mouse-wheel-mode 1)
      (global-set-key [mouse-4] '(lambda ()
                                   (interactive)
                                   (scroll-down 1)))
      (global-set-key [mouse-5] '(lambda ()
                                   (interactive)
                                   (scroll-up 1))))

[5]: http://www.gnu.org/software/emacs/
[6]: http://www.vim.org/


Development
-----------

Download the official development repository using [Git][7]:

    git clone git://github.com/brodie/mouseterm.git

Run `make` to compile the plugin, and `make install` to install it into
your home directory's SIMBL plugins folder. Run `make` and `make builddmg`
to create a disk image of the application.

Visit [GitHub][8] if you'd like to fork the project, watch for new changes,
or report issues.

[JRSwizzle][9] and some mouse reporting code from [iTerm][10] are used in
MouseTerm.

[7]: http://git-scm.org/
[8]: http://github.com/brodie/mouseterm
[9]: http://rentzsch.com/trac/wiki/JRSwizzle
[10]: http://iterm.sourceforge.net/


Contact
-------

Contact information can be found on my site, [brodierao.com][11].

[11]: http://brodierao.com/
