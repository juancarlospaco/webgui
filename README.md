# WebGui

- Web Technologies based Crossplatform GUI.

![](https://img.shields.io/github/languages/top/juancarlospaco/webgui?style=for-the-badge)
![](https://img.shields.io/github/stars/juancarlospaco/webgui?style=for-the-badge "Star webgui on GitHub!")
![](https://img.shields.io/github/languages/code-size/juancarlospaco/webgui?style=for-the-badge)
![](https://img.shields.io/github/issues-raw/juancarlospaco/webgui?style=for-the-badge "Bugs")
![](https://img.shields.io/github/issues-pr-raw/juancarlospaco/webgui?style=for-the-badge "PRs")
![](https://img.shields.io/github/last-commit/juancarlospaco/webgui?style=for-the-badge "Commits")
![](https://github.com/juancarlospaco/webgui/workflows/Build/badge.svg?branch=master)


## Install

```bash
$ nimble install webgui
```

WebGUI also requires that your OS have the GTK+ 3.0 and webkit2gtk 4.0 packages installed
(Nimble should ask for these system dependencies on Ubuntu).

Generic instructions can be found at:

* https://www.gtk.org/docs/installations
* https://webkitgtk.org

In Ubuntu (or Ubuntu-based distributions), these packages can be installed as follows:

```console
$ sudo apt-get install gtk+-3.0 webkit2gtk-4.0 build-essential
```


## Documentation

- https://juancarlospaco.github.io/webgui
- Each push is built with `--panics:on --styleCheck:hint --gc:arc`.


## Buit-in Dark Mode

![Dark mode](https://raw.githubusercontent.com/juancarlospaco/webgui/master/docs/darkui.png)


## Buit-in Light Mode

![Light mode](https://raw.githubusercontent.com/juancarlospaco/webgui/master/docs/lightui.png)


## Apple Mac OS

![](https://raw.githubusercontent.com/juancarlospaco/webgui/master/docs/webgui-mac.png "Apple Mac OS Vanilla")


## Real Life Apps

[![Ballena Itcher GUI](https://raw.githubusercontent.com/juancarlospaco/ballena-itcher/master/0.png)](https://github.com/juancarlospaco/ballena-itcher)


[![SMNAR GUI](https://raw.githubusercontent.com/juancarlospaco/nim-smnar/master/0.png)](https://github.com/juancarlospaco/nim-smnar)


[![Nimble GUI](https://user-images.githubusercontent.com/1189414/78953126-2f055c00-7aae-11ea-9570-4a5fcd5813bc.png)](https://github.com/ThomasTJdev/nim_nimble_gui)


![example code](https://user-images.githubusercontent.com/1189414/78956916-36cafd80-7aba-11ea-97eb-75af94c99c80.png)


[![Choosenim GUI](https://raw.githubusercontent.com/ThomasTJdev/choosenim_gui/master/private/screenshot1.png)](https://github.com/ThomasTJdev/choosenim_gui)


![](https://raw.githubusercontent.com/juancarlospaco/borapp/master/borapp.png)


![](https://raw.githubusercontent.com/ThomasTJdev/nmqttgui/master/private/screenshot1.png)


## Uninstall

```bash
$ nimble uninstall webgui
```


## Hello World

```nim
import webgui
let app = newWebView()
app.run()
app.exit()
```


# FAQ

- Does it works on Hackintosh or Cracked Windows?.

It may or may not work on *Cracked* operating systems,
because the core OS libraries are modified on those.

Please try your code on legit operating system before reporting bugs.

- On Windows it says it can not find the URL?.

Windows is more annoying about URL format, check your URL is correct,
try with raw string literal.

Please check that your URL is correct before reporting bugs.

- Whats the oldest compatibility?.

If you need to target Windows, then your software needs to support Internet Explorer 11.


# Stars

![](https://starchart.cc/juancarlospaco/webgui.svg "Star WebGUI on GitHub!")
