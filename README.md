MouseTerm plus
==============

MouseTerm plus is the provisional fork of [brodie's MouseTerm][1].
We want to push the results of this experimental project to the original MouseTerm, if possible.

MouseTerm is a [SIMBL][2] plugin for Mac OS X's [Terminal.app][3] that
passes mouse events to the terminal, allowing you to use mouse
shortcuts within applications that support them.

[1]: https://bitheap.org/mouseterm
[2]: http://www.culater.net/software/SIMBL/SIMBL.php
[3]: http://www.apple.com/macosx/technology/unix.html

Status
------

MouseTerm is currently beta quality software. It's feature complete,
but still needs testing.

What works:

* Mouse normal event reporting.
* Mouse button event reporting.
* Mouse scroll wheel reporting.
* Simulated mouse wheel scrolling for programs like `less` (i.e. any
  fullscreen program that uses [application cursor key mode][4]).
* URXVT 1015 styled mouse tracking (for vim).
* SGR 1006 styled mouse tracking.
* Menu item integration.

* Supports xterm's "Any Event Mouse(DECSET 1003)" tracking mode (The formar supports "Button Event" only).
* OSC 52 clipboard accsess (get access/set access, for tmux)
* Localization support of menu resource (French/Japanese)
* Emulate xterm patch-level 277 (the former reports as pl.95, in DA2 response).
* Ignore DCS (\eP ... ST, for vim, it's dirty hack - -;)
* Supports xterm's "Title stacking"

[4]: http://the.earth.li/~sgtatham/putty/0.60/htmldoc/Chapter4.html#config-appcursor

Thanks
======

Thanks to the original developper [Brodie Rao][5], and [Tom Feist][6] and [Scott Kroll][7] for their contributions.

[5]: http://brodierao.com/
[6]: http://github.com/shabble
[7]: http://github.com/skroll

-------

Frequently Asked Questions
--------------------------

> What programs can I use the mouse in?

This varies widely and depends on the specific program. `less`,
[Emacs][8], and [Vim][9] are good places to test out mouse reporting.

> How do I disable mouse reporting temporarily?

Use "Send Mouse Events" in the Shell menu.

> How do I configure mouse reporting on a profile basis?

In the preferences dialog under Settings, you can configure terminal
profiles. Select the profile you want to configure, go to the Keyboard
section, and click the "Mouse..." button to change what mouse buttons
are reported to programs in the terminal.

> How do I enable mouse reporting in Vim?

To enable the mouse for all modes add the following to your `~/.vimrc`
file:

    if has("mouse")
        set mouse=a
    endif

Run `:help mouse` for more information and other possible values.

> What about enabling it in Emacs?

By default MouseTerm will use simulated mouse wheel scrolling in
Emacs. To enable terminal mouse support, add this to your `~/.emacs`
file:

    (unless window-system
      (xterm-mouse-mode 1)
      (global-set-key [mouse-4] '(lambda ()
                                   (interactive)
                                   (scroll-down 1)))
      (global-set-key [mouse-5] '(lambda ()
                                   (interactive)
                                   (scroll-up 1))))

[8]: http://www.gnu.org/software/emacs/
[9]: http://www.vim.org/


Development
-----------

Download the official development repository using [Git][7]:

    git clone git://github.com/saitoha/mouseterm-plus.git

Run `make` to compile the plugin, and `make install` to install it
into your home directory's SIMBL plugins folder. `make test` will
install the plugin and run a second instance of Terminal.app for
testing.

Visit [GitHub][8] if you'd like to fork the project, watch for new
changes, or report issues.

[JRSwizzle][9] and some mouse reporting code from [iTerm][10] are used
in MouseTerm. [Ragel][11] is used for parsing control codes.

[7]: http://git-scm.org/
[8]: http://github.com/brodie/mouseterm
[9]: http://rentzsch.com/trac/wiki/JRSwizzle
[10]: http://iterm.sourceforge.net/
[11]: http://www.complang.org/ragel/

