MouseTerm plus
==============

MouseTerm plus is the provisional fork of [brodie's MouseTerm][1].
We want to push the fruits of this experimental project to the original MouseTerm, if possible.

MouseTerm is a [SIMBL][2] plugin for Mac OS X's [Terminal.app][3] that
passes mouse events to the terminal, allowing you to use mouse
shortcuts within applications that support them.

[1]: https://bitheap.org/mouseterm
[2]: http://www.culater.net/software/SIMBL/SIMBL.php
[3]: http://www.apple.com/macosx/technology/unix.html

Download
--------

Installer package with source code is available:

[https://github.com/saitoha/mouseterm-plus/releases](https://github.com/saitoha/mouseterm-plus/releases)

Status
------

MouseTerm-Plus added some fixes to original MouseTerm and implemented a lot of tweaks
that includes various features unrelated to mouse emulation.

Original MouseTerm(version 1.0b1) does:

* Mouse normal event reporting.
* Mouse button event reporting.
* Mouse scroll wheel reporting.
* Simulated mouse wheel scrolling for programs like `less` (i.e. any
  fullscreen program that uses [application cursor key mode][4]).
* Menu item integration.

Additionally, this project does:

* Fix OS X Mavericks installation problem.
* Fix some bugs around mouse event coordinate handling.
* Performance improvement: filter out extra motion events during mouse dragging.
* Handle RIS (hard reset) sequence (*reset(1)* command works well).
* Support OS X Yosemite installation.
* Support *URXVT 1015 styled mouse tracking*(already backported into original source).
  [MinEd][5] uses it.
* Support *SGR 1006 styled mouse tracking*(already backported into original source).
  Recent various terminal applications use it.
* Support *"DEC Locator mode"*.
  [Vim][7] optionally uses it(:set ttymouse=dec).
* Support xterm's *"Any Event Mouse(private mode 1003)"* tracking mode.
  [MinEd][5] uses it.
* Support xterm's *"Focus Reporting Mode (private mode 1004)"*.
  Used by [MinEd][5].
* Support xterm's *"Title stacking"* feature.
  Used by [tmux][6], [MinEd][5].
* Support xterm's *"tcap-query"* feature.
  [Vim][7] uses it.
  You no longer need not set *$TERM* to *'xterm-256color'* to use xterm's 256 color extension in vim.
* Support xterm's palette operation sequences: OSC 4/104.
  This features complement missing terminfo capabilities *'ccc'* and *'initc'*.
  It is rude of Terminal.app to declare 'xterm-256color' although it does not have these capabilities.
  [MinEd][5] uses this feature.
* Support xterm's *foreground text color operation sequences*: OSC 10/110.
  Used by [MinEd][5].
* Support xterm's *background text color operation sequences*: OSC 11/111.
  Used by [Emacs][8], [MinEd][5], [Vim][7].
* Support xterm's *cursor color operation sequences*: OSC 12/112.
  [tmux][6] uses it at startup time.
* Support *"PASTE64"*: OSC 52 clipboard accsess(get access/set access).
  [tmux][6] uses it by default for accessing to clipboard.
  Some terminal emulators such as iTerm2 also have this feature(set access only).
  But they have some problems caused by buffer size restriction.
  The OSC 52 implementation of MouseTerm-Plus does not have buffer size restriction, just like XTerm.
* Report original DA1 response ("\033\[?1;22;29c").
* Report original DA2 response ("\033\[>19796;10000;2c").
* Eliminate [ragel][9] dependency.
* Parse control sequences with DEC VT/ECMA-48 compliant canonical parser.
* Handle "multiple-parameterized" control sequences(e.g. "\e[?1000;1006h") correctly.
* Ignore unhandled DCS/APC/PM/SOS control string.
* Localization support of menu resource (French/Japanese).
* Add extended mode 8810: *"Emoji width fix"*.
* Support VT's *DECSCUSR* sequence.

[4]: http://the.earth.li/~sgtatham/putty/0.60/htmldoc/Chapter4.html#config-appcursor
[5]: http://towo.net/mined/
[6]: http://tmux.sourceforge.net/
[7]: http://www.vim.org/
[8]: http://www.gnu.org/software/emacs/
[9]: http://www.colm.net/open-source/ragel/


Thanks
======

Thanks to [Brodie Rao][10](original developper) and contributors [Tom Feist][11], [Scott Kroll][12], and [Enrico Ghirardi][13].
[Benoit Chesneau][14] reported some bugs to MouseTerm-Plus.

[10]: http://brodierao.com/
[11]: http://github.com/shabble
[12]: http://github.com/skroll
[13]: https://github.com/cHoco
[14]: https://github.com/benoitc


-------

Frequently Asked Questions
--------------------------

> What programs can I use the mouse in?

This varies widely and depends on the specific program. `less`,
[Emacs][15], and [Vim][16] are good places to test out mouse reporting.

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

[15]: http://www.gnu.org/software/emacs/
[16]: http://www.vim.org/


Development
-----------

Download the development repository using [Git][17]:

    git clone git://github.com/saitoha/mouseterm-plus.git

Run `make` to compile the plugin, and `make install` to install it
into your home directory's SIMBL plugins folder.

Visit [GitHub][18] if you'd like to fork the project, watch for new
changes, or report issues.

[JRSwizzle][19] and some mouse reporting code from [iTerm][20] are used
in MouseTerm.

[17]: http://git-scm.org/
[18]: http://github.com/saitoha/mouseterm-plus
[19]: https://github.com/rentzsch/jrswizzle
[20]: http://iterm.sourceforge.net/

