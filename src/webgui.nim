## .. code-block:: nim
##   import webgui
##   let app = newWebView() ## newWebView(dataUriHtmlHeader & "<p>Hello World</p>")
##   app.run()              ## newWebView("http://localhost/index.html")
##   app.exit()             ## newWebView("index.html")
##                          ## newWebView("Karax_Compiled_App.js")
##                          ## newWebView("Will_be_Compiled_to_JavaScript.nim")
##
## - **Design with CSS3, mockup with HTML5, Fast as Rust, Simple as Python, No-GC, powered by Nim.**
## - Dark-Theme and Light-Theme Built-in, Fonts, TrayIcon, Clipboard, Lazy-Loading Images.
## - Native Notifications with Sound, Config and DNS helpers, few LOC, and more...
##
## Buit-in Dark Mode
## =================
##
## .. image:: https://raw.githubusercontent.com/juancarlospaco/webgui/master/docs/darkui.png
##
## Buit-in Light Mode
## ==================
##
## .. image:: https://raw.githubusercontent.com/juancarlospaco/webgui/master/docs/lightui.png
##
## Real-Life Examples
## ==================
##
## .. image:: https://raw.githubusercontent.com/juancarlospaco/ballena-itcher/master/0.png
##
## .. image:: https://raw.githubusercontent.com/juancarlospaco/nim-smnar/master/0.png
##
## .. image:: https://user-images.githubusercontent.com/1189414/78953126-2f055c00-7aae-11ea-9570-4a5fcd5813bc.png
##
## .. image:: https://user-images.githubusercontent.com/1189414/78956916-36cafd80-7aba-11ea-97eb-75af94c99c80.png
##
## .. image:: https://raw.githubusercontent.com/ThomasTJdev/choosenim_gui/master/private/screenshot1.png
##
## Real-Life Projects
## ==================
##
## * https://github.com/ThomasTJdev/nim_nimble_gui    (**~20 lines of Nim** at the time of writing)
## * https://github.com/juancarlospaco/ballena-itcher (**~42 lines of Nim** at the time of writing)
## * https://github.com/juancarlospaco/nim-smnar      (**~32 lines of Nim** at the time of writing)
## * https://github.com/ThomasTJdev/choosenim_gui     (**~80 lines of Nim** at the time of writing)

import tables, strutils, macros, json, os

const headerC = currentSourcePath().substr(0, high(currentSourcePath()) - 10) & "webview.h"
{.passc: "-DWEBVIEW_STATIC -DWEBVIEW_IMPLEMENTATION -I" & headerC.}
when defined(linux):
  {.passc: "-DWEBVIEW_GTK=1 " & staticExec"pkg-config --cflags gtk+-3.0 webkit2gtk-4.0", passl: staticExec"pkg-config --libs gtk+-3.0 webkit2gtk-4.0".}
elif defined(windows):
  {.passc: "-DWEBVIEW_WINAPI=1", passl: "-lole32 -lcomctl32 -loleaut32 -luuid -lgdi32".}
elif defined(macosx):
  {.passc: "-DWEBVIEW_COCOA=1 -x objective-c", passl: "-framework Cocoa -framework WebKit".}

type
  ExternalInvokeCb* = proc (w: Webview; arg: string)  ## External CallBack Proc
  WebviewPrivObj {.importc: "struct webview_priv", header: headerC, bycopy.} = object
  WebviewObj* {.importc: "struct webview", header: headerC, bycopy.} = object ## WebView Type
    url* {.importc: "url".}: cstring                    ## Current URL
    title* {.importc: "title".}: cstring                ## Window Title
    width* {.importc: "width".}: cint                   ## Window Width
    height* {.importc: "height".}: cint                 ## Window Height
    resizable* {.importc: "resizable".}: cint           ## `true` to Resize the Window, `false` for Fixed size Window
    debug* {.importc: "debug".}: cint                   ## Debug is `true` when not build for Release
    invokeCb {.importc: "external_invoke_cb".}: pointer ## Callback proc
    priv {.importc: "priv".}: WebviewPrivObj
    userdata {.importc: "userdata".}: pointer
  Webview* = ptr WebviewObj
  DispatchFn* = proc()
  DialogType {.size: sizeof(cint).} = enum
    dtOpen = 0, dtSave = 1, dtAlert = 2
  CallHook = proc (params: string): string # json -> proc -> json
  MethodInfo = object
    scope, name, args: string
  TinyDefaultButton* = enum
    tdbCancel = 0, tdbOk = 1, tdbNo = 2
  InsertAdjacent* = enum ## Positions for insertAdjacentElement, insertAdjacentHTML, insertAdjacentText
    beforeBegin = "beforebegin" ## Before the targetElement itself.
    afterBegin = "afterbegin"   ## Just inside the targetElement, before its first child.
    beforeEnd = "beforeend"     ## Just inside the targetElement, after its last child.
    afterEnd = "afterend"       ## After the targetElement itself.
  CSSShake* = enum  ## Pure CSS Shake Effects.
    shakeCrazy = "@keyframes shake-crazy{10%{transform:translate(-15px, 10px) rotate(-9deg);opacity:.86}20%{transform:translate(18px, 9px) rotate(8deg);opacity:.11}30%{transform:translate(12px, -4px) rotate(1deg);opacity:.93}40%{transform:translate(-9px, 14px) rotate(0deg);opacity:.46}50%{transform:translate(-4px, -3px) rotate(-9deg);opacity:.67}60%{transform:translate(-11px, 19px) rotate(-5deg);opacity:.59}70%{transform:translate(-19px, 11px) rotate(-5deg);opacity:.92}80%{transform:translate(-16px, 8px) rotate(-1deg);opacity:.63}90%{transform:translate(6px, 0px) rotate(-6deg);opacity:.09}0%,100%{transform:translate(0, 0) rotate(0)}} $1{animation-name:shake-crazy;animation-duration:100ms;animation-timing-function:ease-in-out;animation-iteration-count:infinite}" ## Crazy
    shakeSimple = "@keyframes shake{2%{transform:translate(1.5px, .5px) rotate(-.5deg)}4%{transform:translate(.5px, 2.5px) rotate(.5deg)}6%{transform:translate(2.5px, -1.5px) rotate(-.5deg)}8%{transform:translate(-1.5px, .5px) rotate(-.5deg)}10%{transform:translate(-.5px, 1.5px) rotate(.5deg)}12%{transform:translate(2.5px, .5px) rotate(.5deg)}14%{transform:translate(1.5px, -1.5px) rotate(.5deg)}16%{transform:translate(2.5px, -1.5px) rotate(1.5deg)}18%{transform:translate(.5px, -1.5px) rotate(.5deg)}20%{transform:translate(-.5px, .5px) rotate(.5deg)}22%{transform:translate(2.5px, -1.5px) rotate(-.5deg)}24%{transform:translate(2.5px, 1.5px) rotate(1.5deg)}26%{transform:translate(1.5px, 2.5px) rotate(.5deg)}28%{transform:translate(1.5px, 1.5px) rotate(.5deg)}30%{transform:translate(-.5px, 1.5px) rotate(-.5deg)}32%{transform:translate(2.5px, 2.5px) rotate(1.5deg)}34%{transform:translate(2.5px, -.5px) rotate(1.5deg)}36%{transform:translate(-1.5px, -.5px) rotate(-.5deg)}38%{transform:translate(-.5px, -.5px) rotate(.5deg)}40%{transform:translate(.5px, 2.5px) rotate(1.5deg)}42%{transform:translate(.5px, 1.5px) rotate(.5deg)}44%{transform:translate(-1.5px, -.5px) rotate(.5deg)}46%{transform:translate(1.5px, 1.5px) rotate(.5deg)}48%{transform:translate(-.5px, -.5px) rotate(1.5deg)}50%{transform:translate(2.5px, .5px) rotate(.5deg)}52%{transform:translate(2.5px, -.5px) rotate(1.5deg)}54%{transform:translate(.5px, -1.5px) rotate(-.5deg)}56%{transform:translate(-1.5px, -1.5px) rotate(-.5deg)}58%{transform:translate(.5px, -.5px) rotate(.5deg)}60%{transform:translate(-.5px, .5px) rotate(-.5deg)}62%{transform:translate(2.5px, 2.5px) rotate(.5deg)}64%{transform:translate(2.5px, 1.5px) rotate(.5deg)}66%{transform:translate(-1.5px, -.5px) rotate(.5deg)}68%{transform:translate(.5px, -.5px) rotate(1.5deg)}70%{transform:translate(.5px, -.5px) rotate(-.5deg)}72%{transform:translate(-.5px, 2.5px) rotate(-.5deg)}74%{transform:translate(1.5px, 2.5px) rotate(.5deg)}76%{transform:translate(1.5px, 2.5px) rotate(1.5deg)}78%{transform:translate(-1.5px, -.5px) rotate(-.5deg)}80%{transform:translate(2.5px, -.5px) rotate(.5deg)}82%{transform:translate(-1.5px, -.5px) rotate(-.5deg)}84%{transform:translate(.5px, -1.5px) rotate(-.5deg)}86%{transform:translate(-.5px, 2.5px) rotate(.5deg)}88%{transform:translate(2.5px, .5px) rotate(.5deg)}90%{transform:translate(2.5px, -.5px) rotate(1.5deg)}92%{transform:translate(2.5px, 1.5px) rotate(-.5deg)}94%{transform:translate(1.5px, 2.5px) rotate(-.5deg)}96%{transform:translate(2.5px, -1.5px) rotate(-.5deg)}98%{transform:translate(-.5px, .5px) rotate(.5deg)}0%,100%{transform:translate(0, 0) rotate(0)}} $1{animation-name:shake;animation-duration:100ms;animation-timing-function:ease-in-out;animation-iteration-count:infinite}" ## Simple
    shakeHard = "@keyframes shake-hard{2%{transform:translate(3px, 1px) rotate(3.5deg)}4%{transform:translate(3px, -2px) rotate(.5deg)}6%{transform:translate(8px, 2px) rotate(3.5deg)}8%{transform:translate(8px, -7px) rotate(-2.5deg)}10%{transform:translate(1px, 5px) rotate(2.5deg)}12%{transform:translate(8px, -8px) rotate(-.5deg)}14%{transform:translate(-5px, -3px) rotate(-1.5deg)}16%{transform:translate(-4px, -9px) rotate(-2.5deg)}18%{transform:translate(-7px, 4px) rotate(-1.5deg)}20%{transform:translate(-3px, -9px) rotate(3.5deg)}22%{transform:translate(9px, -6px) rotate(-2.5deg)}24%{transform:translate(4px, -3px) rotate(-1.5deg)}26%{transform:translate(-6px, 8px) rotate(3.5deg)}28%{transform:translate(1px, 10px) rotate(.5deg)}30%{transform:translate(0px, 5px) rotate(.5deg)}32%{transform:translate(2px, -9px) rotate(.5deg)}34%{transform:translate(-5px, -3px) rotate(2.5deg)}36%{transform:translate(-5px, -8px) rotate(-2.5deg)}38%{transform:translate(-9px, -4px) rotate(-2.5deg)}40%{transform:translate(-7px, -1px) rotate(-2.5deg)}42%{transform:translate(-5px, 1px) rotate(-.5deg)}44%{transform:translate(-5px, -3px) rotate(3.5deg)}46%{transform:translate(-8px, 5px) rotate(1.5deg)}48%{transform:translate(9px, 5px) rotate(1.5deg)}50%{transform:translate(5px, 3px) rotate(2.5deg)}52%{transform:translate(7px, 10px) rotate(-.5deg)}54%{transform:translate(-6px, 9px) rotate(3.5deg)}56%{transform:translate(-2px, 1px) rotate(-1.5deg)}58%{transform:translate(7px, 3px) rotate(-1.5deg)}60%{transform:translate(-9px, 4px) rotate(3.5deg)}62%{transform:translate(-3px, -6px) rotate(1.5deg)}64%{transform:translate(-3px, -9px) rotate(1.5deg)}66%{transform:translate(5px, 2px) rotate(-1.5deg)}68%{transform:translate(10px, 3px) rotate(-2.5deg)}70%{transform:translate(-4px, 6px) rotate(3.5deg)}72%{transform:translate(-2px, -6px) rotate(2.5deg)}74%{transform:translate(4px, -2px) rotate(-.5deg)}76%{transform:translate(-4px, -5px) rotate(3.5deg)}78%{transform:translate(9px, 4px) rotate(.5deg)}80%{transform:translate(-7px, -2px) rotate(3.5deg)}82%{transform:translate(-5px, -7px) rotate(-2.5deg)}84%{transform:translate(-3px, 1px) rotate(-2.5deg)}86%{transform:translate(-9px, 3px) rotate(2.5deg)}88%{transform:translate(-5px, -2px) rotate(2.5deg)}90%{transform:translate(7px, -2px) rotate(.5deg)}92%{transform:translate(-2px, 9px) rotate(-2.5deg)}94%{transform:translate(-8px, 8px) rotate(-.5deg)}96%{transform:translate(1px, -4px) rotate(3.5deg)}98%{transform:translate(-9px, 8px) rotate(-1.5deg)}0%,100%{transform:translate(0, 0) rotate(0)}} $1{animation-name:shake-hard;animation-duration:100ms;animation-timing-function:ease-in-out;animation-iteration-count:infinite}" ## Hard
    shakeHorizontal = "@keyframes shake-horizontal{2%{transform:translate(6px, 0) rotate(0)}4%{transform:translate(5px, 0) rotate(0)}6%{transform:translate(0px, 0) rotate(0)}8%{transform:translate(-5px, 0) rotate(0)}10%{transform:translate(7px, 0) rotate(0)}12%{transform:translate(9px, 0) rotate(0)}14%{transform:translate(3px, 0) rotate(0)}16%{transform:translate(-7px, 0) rotate(0)}18%{transform:translate(-3px, 0) rotate(0)}20%{transform:translate(0px, 0) rotate(0)}22%{transform:translate(9px, 0) rotate(0)}24%{transform:translate(-7px, 0) rotate(0)}26%{transform:translate(0px, 0) rotate(0)}28%{transform:translate(-6px, 0) rotate(0)}30%{transform:translate(2px, 0) rotate(0)}32%{transform:translate(3px, 0) rotate(0)}34%{transform:translate(1px, 0) rotate(0)}36%{transform:translate(-1px, 0) rotate(0)}38%{transform:translate(0px, 0) rotate(0)}40%{transform:translate(2px, 0) rotate(0)}42%{transform:translate(6px, 0) rotate(0)}44%{transform:translate(1px, 0) rotate(0)}46%{transform:translate(9px, 0) rotate(0)}48%{transform:translate(6px, 0) rotate(0)}50%{transform:translate(4px, 0) rotate(0)}52%{transform:translate(-4px, 0) rotate(0)}54%{transform:translate(10px, 0) rotate(0)}56%{transform:translate(8px, 0) rotate(0)}58%{transform:translate(5px, 0) rotate(0)}60%{transform:translate(6px, 0) rotate(0)}62%{transform:translate(3px, 0) rotate(0)}64%{transform:translate(-2px, 0) rotate(0)}66%{transform:translate(10px, 0) rotate(0)}68%{transform:translate(-5px, 0) rotate(0)}70%{transform:translate(-3px, 0) rotate(0)}72%{transform:translate(10px, 0) rotate(0)}74%{transform:translate(8px, 0) rotate(0)}76%{transform:translate(4px, 0) rotate(0)}78%{transform:translate(1px, 0) rotate(0)}80%{transform:translate(9px, 0) rotate(0)}82%{transform:translate(9px, 0) rotate(0)}84%{transform:translate(-4px, 0) rotate(0)}86%{transform:translate(-4px, 0) rotate(0)}88%{transform:translate(6px, 0) rotate(0)}90%{transform:translate(5px, 0) rotate(0)}92%{transform:translate(-7px, 0) rotate(0)}94%{transform:translate(-4px, 0) rotate(0)}96%{transform:translate(-4px, 0) rotate(0)}98%{transform:translate(4px, 0) rotate(0)}0%,100%{transform:translate(0, 0) rotate(0)}} $1{animation-name:shake-horizontal;animation-duration:100ms;animation-timing-function:ease-in-out;animation-iteration-count:infinite}" ## Horizontal
    shakeTiny = "@keyframes shake-little{2%{transform:translate(1px, 0px) rotate(.5deg)}4%{transform:translate(1px, 0px) rotate(.5deg)}6%{transform:translate(1px, 1px) rotate(.5deg)}8%{transform:translate(0px, 0px) rotate(.5deg)}10%{transform:translate(1px, 0px) rotate(.5deg)}12%{transform:translate(1px, 1px) rotate(.5deg)}14%{transform:translate(1px, 1px) rotate(.5deg)}16%{transform:translate(1px, 1px) rotate(.5deg)}18%{transform:translate(0px, 1px) rotate(.5deg)}20%{transform:translate(1px, 0px) rotate(.5deg)}22%{transform:translate(1px, 0px) rotate(.5deg)}24%{transform:translate(1px, 0px) rotate(.5deg)}26%{transform:translate(1px, 1px) rotate(.5deg)}28%{transform:translate(0px, 0px) rotate(.5deg)}30%{transform:translate(1px, 0px) rotate(.5deg)}32%{transform:translate(1px, 0px) rotate(.5deg)}34%{transform:translate(0px, 0px) rotate(.5deg)}36%{transform:translate(0px, 1px) rotate(.5deg)}38%{transform:translate(0px, 0px) rotate(.5deg)}40%{transform:translate(1px, 0px) rotate(.5deg)}42%{transform:translate(1px, 1px) rotate(.5deg)}44%{transform:translate(1px, 0px) rotate(.5deg)}46%{transform:translate(1px, 1px) rotate(.5deg)}48%{transform:translate(1px, 0px) rotate(.5deg)}50%{transform:translate(1px, 0px) rotate(.5deg)}52%{transform:translate(0px, 1px) rotate(.5deg)}54%{transform:translate(0px, 1px) rotate(.5deg)}56%{transform:translate(0px, 0px) rotate(.5deg)}58%{transform:translate(1px, 0px) rotate(.5deg)}60%{transform:translate(0px, 0px) rotate(.5deg)}62%{transform:translate(0px, 0px) rotate(.5deg)}64%{transform:translate(1px, 0px) rotate(.5deg)}66%{transform:translate(1px, 1px) rotate(.5deg)}68%{transform:translate(1px, 0px) rotate(.5deg)}70%{transform:translate(1px, 0px) rotate(.5deg)}72%{transform:translate(1px, 0px) rotate(.5deg)}74%{transform:translate(1px, 1px) rotate(.5deg)}76%{transform:translate(1px, 0px) rotate(.5deg)}78%{transform:translate(0px, 0px) rotate(.5deg)}80%{transform:translate(1px, 1px) rotate(.5deg)}82%{transform:translate(1px, 1px) rotate(.5deg)}84%{transform:translate(1px, 0px) rotate(.5deg)}86%{transform:translate(1px, 0px) rotate(.5deg)}88%{transform:translate(0px, 1px) rotate(.5deg)}90%{transform:translate(1px, 1px) rotate(.5deg)}92%{transform:translate(1px, 0px) rotate(.5deg)}94%{transform:translate(0px, 1px) rotate(.5deg)}96%{transform:translate(0px, 1px) rotate(.5deg)}98%{transform:translate(1px, 1px) rotate(.5deg)}0%,100%{transform:translate(0, 0) rotate(0)}}$1{animation-name:shake-little;animation-duration:100ms;animation-timing-function:ease-in-out;animation-iteration-count:infinite}"  ## Tiny
    shakeSpin = "@keyframes shake-rotate{2%{transform:translate(0, 0) rotate(.5deg)}4%{transform:translate(0, 0) rotate(2.5deg)}6%{transform:translate(0, 0) rotate(-.5deg)}8%{transform:translate(0, 0) rotate(-4.5deg)}10%{transform:translate(0, 0) rotate(-3.5deg)}12%{transform:translate(0, 0) rotate(-2.5deg)}14%{transform:translate(0, 0) rotate(-3.5deg)}16%{transform:translate(0, 0) rotate(5.5deg)}18%{transform:translate(0, 0) rotate(-1.5deg)}20%{transform:translate(0, 0) rotate(2.5deg)}22%{transform:translate(0, 0) rotate(-2.5deg)}24%{transform:translate(0, 0) rotate(5.5deg)}26%{transform:translate(0, 0) rotate(-.5deg)}28%{transform:translate(0, 0) rotate(5.5deg)}30%{transform:translate(0, 0) rotate(3.5deg)}32%{transform:translate(0, 0) rotate(3.5deg)}34%{transform:translate(0, 0) rotate(3.5deg)}36%{transform:translate(0, 0) rotate(-3.5deg)}38%{transform:translate(0, 0) rotate(-6.5deg)}40%{transform:translate(0, 0) rotate(-2.5deg)}42%{transform:translate(0, 0) rotate(7.5deg)}44%{transform:translate(0, 0) rotate(2.5deg)}46%{transform:translate(0, 0) rotate(-6.5deg)}48%{transform:translate(0, 0) rotate(-2.5deg)}50%{transform:translate(0, 0) rotate(2.5deg)}52%{transform:translate(0, 0) rotate(3.5deg)}54%{transform:translate(0, 0) rotate(-6.5deg)}56%{transform:translate(0, 0) rotate(-5.5deg)}58%{transform:translate(0, 0) rotate(.5deg)}60%{transform:translate(0, 0) rotate(.5deg)}62%{transform:translate(0, 0) rotate(2.5deg)}64%{transform:translate(0, 0) rotate(-5.5deg)}66%{transform:translate(0, 0) rotate(3.5deg)}68%{transform:translate(0, 0) rotate(-3.5deg)}70%{transform:translate(0, 0) rotate(.5deg)}72%{transform:translate(0, 0) rotate(-.5deg)}74%{transform:translate(0, 0) rotate(6.5deg)}76%{transform:translate(0, 0) rotate(-6.5deg)}78%{transform:translate(0, 0) rotate(-1.5deg)}80%{transform:translate(0, 0) rotate(-2.5deg)}82%{transform:translate(0, 0) rotate(-6.5deg)}84%{transform:translate(0, 0) rotate(-3.5deg)}86%{transform:translate(0, 0) rotate(5.5deg)}88%{transform:translate(0, 0) rotate(-1.5deg)}90%{transform:translate(0, 0) rotate(-.5deg)}92%{transform:translate(0, 0) rotate(-1.5deg)}94%{transform:translate(0, 0) rotate(6.5deg)}96%{transform:translate(0, 0) rotate(4.5deg)}98%{transform:translate(0, 0) rotate(-3.5deg)}0%,100%{transform:translate(0, 0) rotate(0)}} $1{animation-name:shake-rotate;animation-duration:100ms;animation-timing-function:ease-in-out;animation-iteration-count:infinite}"  ## Spin
    shakeSlow = "@keyframes shake-slow{2%{transform:translate(7px, 8px) rotate(2.5deg)}4%{transform:translate(-6px, -5px) rotate(-1.5deg)}6%{transform:translate(6px, 4px) rotate(-1.5deg)}8%{transform:translate(-8px, -5px) rotate(-1.5deg)}10%{transform:translate(0px, 7px) rotate(2.5deg)}12%{transform:translate(-9px, 6px) rotate(3.5deg)}14%{transform:translate(10px, -7px) rotate(-1.5deg)}16%{transform:translate(-8px, -9px) rotate(-2.5deg)}18%{transform:translate(-7px, -5px) rotate(.5deg)}20%{transform:translate(0px, -3px) rotate(-2.5deg)}22%{transform:translate(4px, 10px) rotate(3.5deg)}24%{transform:translate(-5px, 7px) rotate(-2.5deg)}26%{transform:translate(7px, -6px) rotate(2.5deg)}28%{transform:translate(10px, 8px) rotate(-2.5deg)}30%{transform:translate(-5px, 6px) rotate(2.5deg)}32%{transform:translate(1px, 3px) rotate(-2.5deg)}34%{transform:translate(4px, 6px) rotate(-2.5deg)}36%{transform:translate(-7px, 0px) rotate(-1.5deg)}38%{transform:translate(4px, 6px) rotate(.5deg)}40%{transform:translate(-2px, 5px) rotate(.5deg)}42%{transform:translate(6px, 2px) rotate(.5deg)}44%{transform:translate(-9px, 4px) rotate(-.5deg)}46%{transform:translate(6px, -7px) rotate(-.5deg)}48%{transform:translate(8px, 1px) rotate(1.5deg)}50%{transform:translate(-4px, -9px) rotate(1.5deg)}52%{transform:translate(7px, -5px) rotate(3.5deg)}54%{transform:translate(10px, 1px) rotate(.5deg)}56%{transform:translate(5px, 2px) rotate(3.5deg)}58%{transform:translate(4px, -4px) rotate(2.5deg)}60%{transform:translate(-2px, 6px) rotate(-2.5deg)}62%{transform:translate(5px, -4px) rotate(-2.5deg)}64%{transform:translate(8px, 0px) rotate(-2.5deg)}66%{transform:translate(7px, 7px) rotate(-1.5deg)}68%{transform:translate(7px, -2px) rotate(.5deg)}70%{transform:translate(3px, -4px) rotate(3.5deg)}72%{transform:translate(-5px, -9px) rotate(2.5deg)}74%{transform:translate(1px, 0px) rotate(-1.5deg)}76%{transform:translate(1px, -8px) rotate(-2.5deg)}78%{transform:translate(5px, 9px) rotate(-2.5deg)}80%{transform:translate(-9px, 2px) rotate(-.5deg)}82%{transform:translate(-5px, 9px) rotate(.5deg)}84%{transform:translate(-7px, -2px) rotate(-.5deg)}86%{transform:translate(-3px, 3px) rotate(1.5deg)}88%{transform:translate(8px, -7px) rotate(-1.5deg)}90%{transform:translate(-2px, 3px) rotate(2.5deg)}92%{transform:translate(10px, 10px) rotate(.5deg)}94%{transform:translate(0px, 8px) rotate(2.5deg)}96%{transform:translate(-6px, 6px) rotate(3.5deg)}98%{transform:translate(9px, -6px) rotate(2.5deg)}0%,100%{transform:translate(0, 0) rotate(0)}} $1{animation-name:shake-slow;animation-duration:5s;animation-timing-function:ease-in-out;animation-iteration-count:infinite}" ## Slow
    shakeVertical = "@keyframes shake-vertical{2%{transform:translate(0, -2px) rotate(0)}4%{transform:translate(0, 0px) rotate(0)}6%{transform:translate(0, 8px) rotate(0)}8%{transform:translate(0, 1px) rotate(0)}10%{transform:translate(0, -3px) rotate(0)}12%{transform:translate(0, -5px) rotate(0)}14%{transform:translate(0, 10px) rotate(0)}16%{transform:translate(0, 10px) rotate(0)}18%{transform:translate(0, 1px) rotate(0)}20%{transform:translate(0, -1px) rotate(0)}22%{transform:translate(0, -2px) rotate(0)}24%{transform:translate(0, 8px) rotate(0)}26%{transform:translate(0, -7px) rotate(0)}28%{transform:translate(0, -3px) rotate(0)}30%{transform:translate(0, -7px) rotate(0)}32%{transform:translate(0, -9px) rotate(0)}34%{transform:translate(0, -1px) rotate(0)}36%{transform:translate(0, 1px) rotate(0)}38%{transform:translate(0, 10px) rotate(0)}40%{transform:translate(0, -6px) rotate(0)}42%{transform:translate(0, 7px) rotate(0)}44%{transform:translate(0, 4px) rotate(0)}46%{transform:translate(0, 7px) rotate(0)}48%{transform:translate(0, -8px) rotate(0)}50%{transform:translate(0, -5px) rotate(0)}52%{transform:translate(0, 2px) rotate(0)}54%{transform:translate(0, -1px) rotate(0)}56%{transform:translate(0, -9px) rotate(0)}58%{transform:translate(0, -3px) rotate(0)}60%{transform:translate(0, -2px) rotate(0)}62%{transform:translate(0, -2px) rotate(0)}64%{transform:translate(0, 0px) rotate(0)}66%{transform:translate(0, -4px) rotate(0)}68%{transform:translate(0, 4px) rotate(0)}70%{transform:translate(0, -3px) rotate(0)}72%{transform:translate(0, 6px) rotate(0)}74%{transform:translate(0, -1px) rotate(0)}76%{transform:translate(0, -8px) rotate(0)}78%{transform:translate(0, -6px) rotate(0)}80%{transform:translate(0, -9px) rotate(0)}82%{transform:translate(0, 4px) rotate(0)}84%{transform:translate(0, 4px) rotate(0)}86%{transform:translate(0, -3px) rotate(0)}88%{transform:translate(0, 1px) rotate(0)}90%{transform:translate(0, -4px) rotate(0)}92%{transform:translate(0, -5px) rotate(0)}94%{transform:translate(0, 5px) rotate(0)}96%{transform:translate(0, 4px) rotate(0)}98%{transform:translate(0, 8px) rotate(0)}0%,100%{transform:translate(0, 0) rotate(0)}} $1{animation-name:shake-vertical;animation-duration:100ms;animation-timing-function:ease-in-out;animation-iteration-count:infinite}"  ## Vertical

const
  dataUriHtmlHeader* = "data:text/html;charset=utf-8,"  ## Data URI for HTML UTF-8 header string
  fileLocalHeader* = "file:///"  ## Use Local File as URL.
  cssDark = staticRead"dark.css".strip.cstring
  cssLight = staticRead"light.css".strip.cstring
  imageLazy = """
    <img class="$5" id="$2" alt="$6" data-src="$1" src="" lazyload="on" onclick="this.src=this.dataset.src" onmouseover="this.src=this.dataset.src" width="$3" heigth="$4"/>
    <script>
      const i = document.querySelector("img#$2");
      window.addEventListener('scroll',()=>{if(i.offsetTop<window.innerHeight+window.pageYOffset+99){i.src=i.dataset.src}});
      window.addEventListener('resize',()=>{if(i.offsetTop<window.innerHeight+window.pageYOffset+99){i.src=i.dataset.src}});
    </script>
  """.strip.unindent
  jsTemplate = """
    if (typeof $2 === 'undefined') {
      $2 = {};
    }
    $2.$1 = (arg) => {
      window.external.invoke(
        JSON.stringify(
          {scope: "$2", name: "$1", args: JSON.stringify(arg)}
        )
      );
    };
  """.strip.unindent
  jsTemplateOnlyArg = """
    if (typeof $2 === 'undefined') {
      $2 = {};
    }
    $2.$1 = (arg) => {
      window.external.invoke(
        JSON.stringify(
          {scope: "$2", name: "$1", args: JSON.stringify(arg)}
        )
      );
    };
  """.strip.unindent
  jsTemplateNoArg = """
    if (typeof $2 === 'undefined') {
      $2 = {};
    }
    $2.$1 = () => {
      window.external.invoke(
        JSON.stringify(
          {scope: "$2", name: "$1", args: ""}
        )
      );
    };
  """.strip.unindent

var
  eps = newTable[Webview, TableRef[string, TableRef[string, CallHook]]]() # for bindProc
  cbs = newTable[Webview, ExternalInvokeCb]() # easy callbacks
  dispatchTable = newTable[int, DispatchFn]() # for dispatch

{.compile: "tinyfiledialogs.c".}
func beep*(_: Webview): void {.importc: "tinyfd_beep".} ## Beep Sound to alert the user.
func notifySend*(aTitle: cstring, aMessage: cstring, aDialogType = "yesno".cstring, aIconType = "info".cstring, aDefaultButton = tdbOk): cint {.importc: "tinyfd_notifyPopup".}
  ## This is similar to `notify-send` from Linux, but implemented in C.
  ## This will send 1 native notification, but will fallback from best to worse,
  ## on Linux without a full desktop or without notification system, it may use `zenity` or similar.
  ## - ``aDialogType`` must be one of ``"ok"``, ``"okcancel"``, ``"yesno"``, ``"yesnocancel"``, ``string`` type.
  ## - ``aIconType`` must be one of ``"info"``, ``"warning"``, ``"error"``, ``"question"``, ``string`` type.
  ## - ``aDefaultButton`` must be one of ``0`` (for Cancel), ``1`` (for Ok), ``2`` (for No), ``range[0..2]`` type.

func dialogInput*(aTitle: cstring, aMessage: cstring, aDefaultInput: cstring = nil): cstring {.importc: "tinyfd_inputBox".}
  ## - ``aDialogType`` must be one of ``"ok"``, ``"okcancel"``, ``"yesno"``, ``"yesnocancel"``, ``string`` type.
  ## - ``aIconType`` must be one of ``"info"``, ``"warning"``, ``"error"``, ``"question"``, ``string`` type.
  ## - ``aDefaultButton`` must be one of ``0`` (for Cancel), ``1`` (for Ok), ``2`` (for No), ``range[0..2]`` type.
  ## - ``aDefaultInput`` must be ``nil`` (for Password entry field) or any string for plain text entry field with a default value, ``string`` or ``nil`` type.

func dialogMessage*(aTitle: cstring, aMessage: cstring, aDialogType = "yesno".cstring, aIconType = "info".cstring, aDefaultButton = tdbOk): cint {.importc: "tinyfd_messageBox".}
  ## - ``aDialogType`` must be one of ``"ok"``, ``"okcancel"``, ``"yesno"``, ``"yesnocancel"``, ``string`` type.
  ## - ``aIconType`` must be one of ``"info"``, ``"warning"``, ``"error"``, ``"question"``, ``string`` type.
  ## - ``aDefaultButton`` must be one of ``0`` (for Cancel), ``1`` (for Ok), ``2`` (for No), ``range[0..2]`` type.

func dialogOpen*(aTitle: cstring, aDefaultPathAndFile: cstring, aNumOfFilterPatterns = 0.cint, aFilterPattern = "*.*".cstring, aSingleFilterDescription = "".cstring, aAllowMultipleSelects: range[0..1] = 0): cstring {.importc: "tinyfd_openFileDialog".}
  ## * ``aAllowMultipleSelects`` must be ``0`` (false) or ``1`` (true), multiple selection returns 1 ``string`` with paths divided by ``|``, ``int`` type.
  ## * ``aDefaultPathAndFile`` is 1 default full path.
  ## * ``aFilterPatterns`` is 1 Posix Glob pattern string. ``"*.*"``, ``"*.jpg"``, etc.
  ## * ``aSingleFilterDescription`` is a string with descriptions for ``aFilterPatterns``.
  ## Similar to the other file dialog but with more extra options.

proc dialogSave*(aTitle: cstring, aDefaultPathAndFile: cstring, aNumOfFilterPatterns = 0.cint, aFilterPatterns = "*.*".cstring, aSingleFilterDescription = "".cstring, aAllowMultipleSelects: range[0..1] = 0): cstring {.importc: "tinyfd_saveFileDialog".}
  ## * ``aDefaultPathAndFile`` is 1 default full path.
  ## * ``aFilterPatterns`` is 1 Posix Glob pattern string. ``"*.*"``, ``"*.jpg"``, etc.
  ## * ``aSingleFilterDescription`` is a string with descriptions for ``aFilterPatterns``.
  ## * ``aAllowMultipleSelects`` must be ``0`` (false) or ``1`` (true), multiple selection returns 1 ``string`` with paths divided by ``|``, ``int`` type.
  ## Similar to the other file dialog but with more extra options.

proc dialogOpenDir*(aTitle: cstring, aDefaultPath: cstring): cstring {.importc: "tinyfd_selectFolderDialog".}
  ## * ``aDefaultPath`` is a Default Folder Path.
  ## Similar to the other file dialog but with more extra options.

func init(w: Webview): cint {.importc: "webview_init", header: headerC.}
func loop(w: Webview; blocking: cint): cint {.importc: "webview_loop", header: headerC.}
func js*(w: Webview; javascript: cstring): cint {.importc: "webview_eval", header: headerC, discardable.} ## Evaluate a JavaScript cstring, runs the javascript string on the window
func css*(w: Webview; css: cstring): cint {.importc: "webview_inject_css", header: headerC, discardable.} ## Set a CSS cstring, inject the CSS on the Window
func setTitle*(w: Webview; title: cstring) {.importc: "webview_set_title", header: headerC.} ## Set Title of window
func setColor*(w: Webview; red, green, blue, alpha: uint8) {.importc: "webview_set_color", header: headerC.} ## Set background color of the Window
func setFullscreen*(w: Webview; fullscreen: bool) {.importc: "webview_set_fullscreen", header: headerC.}     ## Set fullscreen
func dialog(w: Webview; dlgtype: DialogType; flags: cint; title: cstring; arg: cstring; result: cstring; resultsz: system.csize_t) {.importc: "webview_dialog", header: headerC.}
func dispatch(w: Webview; fn: pointer; arg: pointer) {.importc: "webview_dispatch", header: headerC.}
func webview_terminate(w: Webview) {.importc: "webview_terminate", header: headerC.}
func webview_exit(w: Webview) {.importc: "webview_exit", header: headerC.}
func jsDebug*(format: cstring) {.varargs, importc: "webview_debug", header: headerC.}  ##  `console.debug()` directly inside the JavaScript context.
func jsLog*(s: cstring) {.importc: "webview_print_log", header: headerC.} ## `console.log()` directly inside the JavaScript context.
func webview(title: cstring; url: cstring; w: cint; h: cint; resizable: cint): cint {.importc: "webview", header: headerC, used.}
func setUrl*(w: Webview; url: cstring) {.importc: "webview_launch_external_URL", header: headerC.} ## Set the current URL
func setIconify*(w: Webview; mustBeIconified: bool) {.importc: "webview_set_iconify", header: headerC.}  ## Set window to be Minimized Iconified

func setBorderless*(w: Webview, decorated: bool) {.inline.} =
  ## Use a window without borders, no close nor minimize buttons.
  when defined(linux): {.emit: "gtk_window_set_decorated(GTK_WINDOW(`w`->priv.window), `decorated`);".}

func setSkipTaskbar*(w: Webview, hint: bool) {.inline.} =
  ## Do not show the window on the Taskbar
  when defined(linux): {.emit: "gtk_window_set_skip_taskbar_hint(GTK_WINDOW(`w`->priv.window), `hint`); gtk_window_set_skip_pager_hint(GTK_WINDOW(`w`->priv.window), `hint`);".}

func setSize*(w: Webview, width: Positive, height: Positive) {.inline.} =
  ## Resize the window to given size
  when defined(linux): {.emit: "gtk_widget_set_size_request(GTK_WINDOW(`w`->priv.window), `width`, `height`);".}

func setFocus*(w: Webview) {.inline.} =
  ## Force focus on the window
  when defined(linux): {.emit: "gtk_widget_grab_focus(GTK_WINDOW(`w`->priv.window));".}

func setOnTop*(w: Webview, mustBeOnTop: bool) {.inline.} =
  ## Force window to be on top of all other windows
  when defined(linux): {.emit: "gtk_window_set_keep_above(GTK_WINDOW(`w`->priv.window), `mustBeOnTop`);".}

func setClipboard*(w: Webview, text: cstring) {.inline.} =
  ## Set a text cstring on the Clipboard, text must not be empty string
  assert text.len > 0, "text for clipboard must not be empty string"
  when defined(linux): {.emit: "gtk_clipboard_set_text(gtk_clipboard_get(GDK_SELECTION_CLIPBOARD), `text`, -1);".}

func setTrayIcon*(w: Webview, path, tooltip: cstring, visible = true) {.inline.} =
  ## Set a TrayIcon on the corner of the desktop. `path` is full path to a PNG image icon. Only shows an icon.
  assert path.len > 0, "icon path must not be empty string"
  when defined(linux): {.emit: """
    GtkStatusIcon* webview_icon_nim = gtk_status_icon_new_from_file(`path`);
    gtk_status_icon_set_visible(webview_icon_nim, `visible`);
    gtk_status_icon_set_title(webview_icon_nim, `tooltip`);
    gtk_status_icon_set_name(webview_icon_nim, `tooltip`);
  """.}

proc generalExternalInvokeCallback(w: Webview; arg: cstring) {.exportc.} =
  var handled = false
  if eps.hasKey(w):
    try:
      var mi = parseJson($arg).to(MethodInfo)
      if hasKey(eps[w], mi.scope) and hasKey(eps[w][mi.scope], mi.name):
        discard eps[w][mi.scope][mi.name](mi.args)
        handled = true
    except:
      when defined(release): discard else: echo getCurrentExceptionMsg()
  elif cbs.hasKey(w):
    cbs[w](w, $arg)
    handled = true
  when not defined(release):
    if unlikely(handled == false): echo "Error on External invoke: ", arg

proc `externalInvokeCB=`*(w: Webview; callback: ExternalInvokeCb) {.inline.} =
  ## Set the external invoke callback for webview, for Advanced users only
  cbs[w] = callback

proc generalDispatchProc(w: Webview; arg: pointer) {.exportc.} =
  let idx = cast[int](arg)
  let fn = dispatchTable[idx]
  fn()

proc dispatch*(w: Webview; fn: DispatchFn) {.inline.} =
  ## Explicitly force dispatch a function, for advanced users only
  let idx = dispatchTable.len() + 1
  dispatchTable[idx] = fn
  dispatch(w, generalDispatchProc, cast[pointer](idx))

proc dialog(w: Webview; dlgType: DialogType; dlgFlag: int; title, arg: string): string =
  ## dialog() opens a system dialog of the given type and title.
  ## String argument can be provided for certain dialogs, such as alert boxes.
  ## For alert boxes argument is a message inside the dialog box.
  const maxPath = 4096
  let resultPtr = cast[cstring](alloc0(maxPath))
  defer: dealloc(resultPtr)
  w.dialog(dlgType, dlgFlag.cint, title.cstring, arg.cstring, resultPtr, system.csize_t(maxPath))
  return $resultPtr

template msg*(w: Webview; title, msg: string) =
  ## Show one message box
  discard w.dialog(dtAlert, 0, title, msg)

template info*(w: Webview; title, msg: string) =
  ## Show one alert box
  discard w.dialog(dtAlert, 1 shl 1, title, msg)

template warn*(w: Webview; title, msg: string) =
  ## Show one warn box
  discard w.dialog(dtAlert, 2 shl 1, title, msg)

template error*(w: Webview; title, msg: string) =
  ## Show one error box
  discard w.dialog(dtAlert, 3 shl 1, title, msg)

template dialogOpen*(w: Webview; title = ""): string =
  ## Opens a dialog that requests filenames from the user. Returns ""
  ## if the user closed the dialog without selecting a file.
  w.dialog(dtOpen, 0.cint, title, "")

template dialogSave*(w: Webview; title = ""): string =
  ## Opens a dialog that requests a filename to save to from the user.
  ## Returns "" if the user closed the dialog without selecting a file.
  w.dialog(dtSave, 0.cint, title, "")

template dialogOpenDir*(w: Webview; title = ""): string =
  ## Opens a dialog that requests a Directory from the user.
  w.dialog(dtOpen, 1.cint, title, "")

func run*(w: Webview) {.inline.} =
  ## `run` starts the main UI loop until the user closes the window or `exit()` is called.
  while w.loop(1) == 0: discard

proc run*(w: Webview, quitProc: proc () {.noconv.}, controlCProc: proc () {.noconv.}, autoClose: static[bool] = true) {.inline.} =
  ## `run` starts the main UI loop until the user closes the window. Same as `run` but with extras.
  ## * `quitProc` is a function to run at exit, needs `{.noconv.}` pragma.
  ## * `controlCProc` is a function to run at CTRL+C, needs `{.noconv.}` pragma.
  ## * `autoClose` set to `true` to automatically run `exit()` at exit.
  system.addQuitProc(quitProc)
  system.setControlCHook(controlCProc)
  while w.loop(1) == 0: discard
  when autoClose:
    w.webview_terminate()
    w.webview_exit()

func exit*(w: Webview) {.inline.} =
  ## Explicitly Terminate, close, exit, quit.
  w.webview_terminate()
  w.webview_exit()

template setTheme*(w: Webview; dark: bool) =
  ## Set Dark Theme or Light Theme on-the-fly, `dark = true` for Dark, `dark = false` for Light.
  ## * If `--light-theme` on `commandLineParams()` then it will use Light Theme automatically.
  discard w.css(if dark: cssDark else: cssLight)

template imgLazyLoad*(_: Webview; src, id: string, width = "", heigth = "", class = "",  alt = ""): string =
  ## HTML Image LazyLoad (Must have an ID!).
  ## * https://codepen.io/FilipVitas/pen/pQBYQd
  assert id.len > 0, "ID must not be empty string, must have an ID"
  assert src.len > 0, "src must not be empty string"
  imageLazy.format(src, id, width, heigth, class,  alt)

template sanitizer*(_: Webview; s: string): string =
  ## Sanitize all non-printable and weird characters from a string. `import re` to use it.
  re.replace(s, re(r"[^\x00-\x7F]+", flags = {reStudy, reIgnoreCase}))

template getLang*(_: Webview): string =
  ## Detect the Language of the user, returns a string like `"en-US"`, JavaScript side.
  "((navigator.languages && navigator.languages.length) ? navigator.languages[0] : navigator.language);"

template duckDns*(_: Webview; domains: string; token: string ;ipv4 = ""; ipv6 = ""; verbose: static[bool] = false;
  clear: static[bool] = false;  noParameters: static[bool] = false; ssl: static[bool] = true): string =
  ## Duck DNS, Free Dynamic DNS Service, use your PC or RaspberryPi as $0 Web Hosting
  ## * https://www.duckdns.org/why.jsp
  assert token.len > 0 and domains.len > 0, "Token and Domains must not be empty string"
  when noParameters:
    assert ',' notin domains, "noParameters only allows 1 single subdomain"
    ((when ssl: "https" else: "http") & "://www.duckdns.org/update/" & domains & "/" & token & "/" & ipv4)
  else:
    ((when ssl: "https" else: "http") & "://www.duckdns.org/update?domains=" & domains & "&token=" & token &
      "&verbose=" & $verbose & "&clear=" & $clear & "&ip=" & ipv4 & "&ipv6=" & ipv6)

template setAttribute*(_: Webview; id, key, val: string): string =
  ## Sets an attribute value.
  ## * https://developer.mozilla.org/en-US/docs/Web/API/Element/setAttribute
  assert id.len > 0, "ID must not be empty string, must have an ID"
  "document.querySelector('" & id & "').setAttribute('" & key & "', '" & val & "')"

template toggleAttribute*(_: Webview; id, key: string): string =
  ## Toggles an attribute value. E.g. use it on a `readonly` attribute.
  ## * https://developer.mozilla.org/en-US/docs/Web/API/Element/toggleAttribute
  assert id.len > 0, "ID must not be empty string, must have an ID"
  "document.querySelector('" & id & "').toggleAttribute('" & key & "')"

template removeAttribute*(_: Webview; id, key: string): string =
  ## Remove an attribute.
  ## * https://developer.mozilla.org/en-US/docs/Web/API/Element/removeAttribute
  assert id.len > 0, "ID must not be empty string, must have an ID"
  "document.querySelector('" & id & "').removeAttribute('" & key & "')"

template setText*(_: Webview; id, text: string): string =
  ## Sets the Elements `innerHtml`.
  ## * https://developer.mozilla.org/en-US/docs/Web/API/Node/textContent
  assert id.len > 0, "ID must not be empty string, must have an ID"
  "document.querySelector('" & id & "').textContent = '" & text  & "'"

template addText*(_: Webview; id, text: string, position = beforeEnd): string =
  ## Appends **Plain-Text** to an Element by `id` at `position`, uses `insertAdjacentText()`, JavaScript side.
  ## * https://developer.mozilla.org/en-US/docs/Web/API/Element/insertAdjacentText
  assert id.len > 0, "ID must not be empty string, must have an ID"
  "document.querySelector('" & id & "').insertAdjacentText('" & $position & "',`" & text.replace('`', ' ') & "`);"

template addHtml*(_: Webview; id, html: string, position = beforeEnd): string =
  ## Appends **HTML** to an Element by `id` at `position`, uses `insertAdjacentHTML()`, JavaScript side.
  ## * https://developer.mozilla.org/en-US/docs/Web/API/Element/insertAdjacentHtml
  assert id.len > 0, "ID must not be empty string, must have an ID"
  "document.querySelector('" & id & "').insertAdjacentHTML('" & $position & "',`" & html.replace('`', ' ') & "`);"

template removeHtml*(_: Webview; id: string): string =
  ## Removes an object by `id`.
  ## * https://developer.mozilla.org/en-US/docs/Web/API/ChildNode/remove
  assert id.len > 0, "ID must not be empty string, must have an ID"
  "document.querySelector('" & id & "').remove()"

template addElement*(_: Webview; id, htmlTag: string, position = beforeEnd): string =
  ## Appends **1 New HTML Element** to an Element by `id` at `position`, uses `insertAdjacentElement()`, JavaScript side.
  ## * https://developer.mozilla.org/en-US/docs/Web/API/Element/insertAdjacentElement
  assert id.len > 0, "ID must not be empty string, must have an ID"
  "document.querySelector('" & id & "').insertAdjacentElement('" & $position & "',document.createElement('" & htmlTag & "'));"

template setBlink*(_: Webview; id: string; iterations = 3.byte; duration = 1.byte): string =
  ## `<blink>` is back!, use with `app.css()` https://developer.mozilla.org/en-US/docs/Web/HTML/Element/blink#Example
  ## * https://github.com/juancarlospaco/webgui/blob/master/examples/blink/example.nim
  assert id.len > 0, "ID must not be empty string, must have an ID"
  ("@keyframes blink { from { opacity: 1 } to { opacity: 0 } } " &
    id & " {animation-iteration-count:" & $iterations & ";animation-duration:" & $duration & "s;" &
    "animation-name:blink;animation-timing-function:cubic-bezier(1.0,0,0,1.0)}")

template setCursor*(_: Webview; id: string; url: string): string =
  ## Set the mouse Cursor, use with `app.css()`, PNG, SVG, GIF, JPG, BMP, CUR, Data URI.
  ## * https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Basic_User_Interface/Using_URL_values_for_the_cursor_property
  ## * For Data URI see https://nim-lang.github.io/Nim/uri.html#getDataUri%2Cstring%2Cstring%2Cstring
  ## * https://github.com/juancarlospaco/webgui/blob/master/examples/cursor/example.nim
  assert id.len > 0, "ID must not be empty string, must have an ID"
  id & "{ cursor: url('" & url & "'), auto !important };"

template setShake*(_: Webview; id: string, effect: CSSShake): string =
  ## Shake Effects, use with `app.css()`, `import strutils` to use.
  ## * https://github.com/juancarlospaco/webgui/blob/master/examples/shake/example.nim
  assert id.len > 0, "ID must not be empty string, must have an ID"
  format($effect, id)

template textareaScroll*(_: Webview; id: string, scrollIntoView: static[bool] = false, selectAll: static[bool] = false, copyToClipboard: static[bool] = false): string =
  ## **Scroll a textarea to the bottom**, alias for `textarea.scrollTop = textarea.scrollHeight;`.
  ## * `scrollIntoView` if `true` runs `textarea.scrollIntoView();`.
  ## * `selectAll` if `true` runs `textarea.select();`.
  ## * `copyToClipboard` if `true` runs `document.execCommand('copy');`, requires `selectAll = true`.
  assert id.len > 0, "ID must not be empty string, must have an ID"
  ((when scrollIntoView: "document.querySelector('" & id & "').scrollIntoView();" else: "") &
    (when selectAll: "document.querySelector('" & id & "').select();" else: "") &
    (when selectAll and copyToClipboard: "document.execCommand('copy');" else: "") &
    "document.querySelector('" & id & "').scrollTop = document.querySelector('" & id & "').scrollHeight;")

template jsWithDisable*(w: Webview; id: string; body: untyped) =
  ## Disable 1 element, run some code, Enable same element back again. Disables at the start, Enables at the end.
  ##
  ## .. code-block:: nim
  ##   app.jsWithDisable("#myButton"): ## "#myButton" becomes Disabled.
  ##     slowFunction()                ## Code block that takes a while to finish.
  ##                                   ## "#myButton" becomes Enabled.
  assert id.len > 0, "ID and jsScript must not be empty string"
  w.js("document.querySelector('" & id & "').disabled = true;document.querySelector('#" & id & "').style.cursor = 'wait';")
  try:
    body
  finally:
    w.js("document.querySelector('" & id & "').disabled = false;document.querySelector('#" & id & "').style.cursor = 'default';")

template jsWithHide*(w: Webview; id: string; body: untyped) =
  ## Hide 1 element, run some code, Show same element back again. Hides at the start, Visible at the end.
  ##
  ## .. code-block:: nim
  ##   app.jsWithHide("#myButton"): ## "#myButton" becomes Hidden.
  ##     slowFunction()             ## Code block that takes a while to finish.
  ##                                ## "#myButton" becomes Visible.
  assert id.len > 0, "ID and jsScript must not be empty string"
  w.js("document.querySelector('" & id & "').style.visibility = 'hidden';document.querySelector('#" & id & "').style.cursor = 'wait';")
  try:
    body
  finally:
    w.js("document.querySelector('" & id & "').style.visibility = 'visible';document.querySelector('#" & id & "').style.cursor = 'default';")

template jsWithOpacity*(w: Webview; id: string; body: untyped) =
  ## Opacity 25% on 1 element, run some code, Opacity 100% same element back again. 25% Transparent at the start, Opaque at the end.
  ##
  ## .. code-block:: nim
  ##   app.jsWithOpacity("#myButton"): ## "#myButton" becomes transparent.
  ##     slowFunction()                ## Code block that takes a while to finish.
  ##                                   ## "#myButton" becomes Opaque.
  assert id.len > 0, "ID and jsScript must not be empty string"
  w.js("document.querySelector('" & id & "').style.opacity = 0.25;document.querySelector('#" & id & "').style.cursor = 'wait';")
  try:
    body
  finally:
    w.js("document.querySelector('" & id & "').style.opacity = 1;document.querySelector('#" & id & "').style.cursor = 'default';")

func currentHtmlPath*(filename: static[string] = "index.html"): string {.inline.} =
  ## Alias for `currentSourcePath().splitPath.head / "index.html"` for URL of `index.html`
  result = currentSourcePath().splitPath.head / filename

template getConfig*(filename: string; configObject; compileTime: static[bool] = false): auto =
  ## **Config Helper, JSON to Type.** Read from `config.json`, serialize to `configObject`, return `configObject`,
  ## if `compileTime` is `true` all is done compile-time, `import json` to use it.
  ## You must provide 1 `configObject` that match the `config.json` structure. Works with ARC.
  ## * https://github.com/juancarlospaco/webgui/blob/master/examples/config/configuration.nim
  ## * https://nim-lang.github.io/Nim/json.html#to%2CJsonNode%2Ctypedesc%5BT%5D
  assert filename.len > 5 and filename[^5..^1] == ".json"
  when compileTime: {.hint: filename & " --> " & configObject.repr.}
  to((when compileTime: static(parseJson(staticRead(filename))) else: parseFile(filename)), configObject)

template setFont*(_: Webview; fontName: string): string =
  ## Use a Font from Google Fonts, returns `string` for `app.css()`, `import uri` to use.
  ## * https://fonts.google.com
  ## * https://github.com/juancarlospaco/webgui/blob/master/examples/font/example.nim
  assert fontName.len > 0, "fontName must not be empty string"
  "@import url('https://fonts.googleapis.com/css?family=" & uri.encodeUrl(fontName, true) & "&display=swap');"

template setFont*(_: Webview; fontName, element: string): string =
  ## Use a Font from Google Fonts and set it directly on HTML `element`,
  ## returns `string` for `app.css()`, `import uri` to use.
  ## * https://fonts.google.com
  ## * https://github.com/juancarlospaco/webgui/blob/master/examples/font/example.nim
  assert fontName.len > 0, "fontName must not be empty string"
  "@import url('https://fonts.googleapis.com/css?family=" & uri.encodeUrl(fontName, true) & "&display=swap');\n" & element & "{font-family:'" & fontName & "' !important;text-rendering:optimizeLegibility};"

proc bindProc*[P, R](w: Webview; scope, name: string; p: (proc(param: P): R)) {.used.} =
  ## Do NOT use directly, see `bindProcs` macro.
  assert name.len > 0, "Name must not be empty string"
  proc hook(hookParam: string): string =
    var paramVal: P
    var retVal: R
    try:
      let jnode = parseJson(hookParam)
      when not defined(release): echo jnode
      paramVal = jnode.to(P)
    except:
      when defined(release): discard else: return getCurrentExceptionMsg()
    retVal = p(paramVal)
    return $(%*retVal) # ==> json
  discard eps.hasKeyOrPut(w, newTable[string, TableRef[string, CallHook]]())
  discard hasKeyOrPut(eps[w], scope, newTable[string, CallHook]())
  eps[w][scope][name] = hook
  w.dispatch(proc() = discard w.js(jsTemplate % [name, scope]))

proc bindProcNoArg*(w: Webview; scope, name: string; p: proc()) {.used.} =
  ## Do NOT use directly, see `bindProcs` macro.
  assert name.len > 0, "Name must not be empty string"
  proc hook(hookParam: string): string =
    p()
    return ""
  discard eps.hasKeyOrPut(w, newTable[string, TableRef[string, CallHook]]())
  discard hasKeyOrPut(eps[w], scope, newTable[string, CallHook]())
  eps[w][scope][name] = hook
  w.dispatch(proc() = discard w.js(jsTemplateNoArg % [name, scope]))

proc bindProc*[P](w: Webview; scope, name: string; p: proc(arg: P)) {.used.} =
  ## Do NOT use directly, see `bindProcs` macro.
  assert name.len > 0, "Name must not be empty string"
  proc hook(hookParam: string): string =
    var paramVal: P
    try:
      let jnode = parseJson(hookParam)
      paramVal = jnode.to(P)
    except:
      when defined(release): discard else: return getCurrentExceptionMsg()
    p(paramVal)
    return ""
  discard eps.hasKeyOrPut(w, newTable[string, TableRef[string, CallHook]]())
  discard hasKeyOrPut(eps[w], scope, newTable[string, CallHook]())
  eps[w][scope][name] = hook
  w.dispatch(proc() = discard w.js(jsTemplateOnlyArg % [name, scope]))

macro bindProcs*(w: Webview; scope: string; n: untyped): untyped =
  ## * Functions must be `proc` or `func`; No `template` nor `macro`.
  ## * Functions must NOT have return Type, must NOT return anything, use the API.
  ## * To pass return data to the Frontend use the JavaScript API and WebGui API.
  ## * Functions do NOT need the `*` Star to work. Functions must NOT have Pragmas.
  ##
  ## You can bind functions with the signature like:
  ##
  ## .. code-block:: nim
  ##    proc functionName[T, U](argumentString: T): U
  ##    proc functionName[T](argumentString: T)
  ##    proc functionName()
  ##
  ## Then you can call the function in JavaScript side, like this:
  ##
  ## .. code-block:: js
  ##    scope.functionName(argumentString)
  ##
  ## Example:
  ##
  ## .. code-block:: js
  ##    let app = newWebView()
  ##    app.bindProcs("api"):
  ##      proc changeTitle(title: string) = app.setTitle(title) ## You can call code on the right-side,
  ##      proc changeCss(stylesh: string) = app.css(stylesh)    ## from JavaScript Web Frontend GUI,
  ##      proc injectJs(jsScript: string) = app.js(jsScript)    ## by the function name on the left-side.
  ##      ## (JS) JavaScript Frontend <-- = --> Nim Backend (Native Code, C Speed)
  ##
  ## The only limitation is `1` string argument only, but you can just use JSON.
  expectKind(n, nnkStmtList)
  let body = n
  for def in n:
    expectKind(def, {nnkProcDef, nnkFuncDef, nnkLambda})
    let params = def.params()
    let fname = $def[0]
    # expectKind(params[0], nnkSym)
    if params.len() == 1 and params[0].kind() == nnkEmpty: # no args
      body.add(newCall("bindProcNoArg", w, scope, newLit(fname), newIdentNode(fname)))
      continue
    if params.len > 2: error("Argument must be proc or func of 0 or 1 arguments", def)
    body.add(newCall("bindProc", w, scope, newLit(fname), newIdentNode(fname)))
  result = newBlockStmt(body)
  when not defined(release): echo repr(result)

proc webView(title = ""; url = ""; width: Positive = 640; height: Positive = 480; resizable: static[bool] = true; debug: static[bool] = not defined(release); callback: ExternalInvokeCb = nil): Webview {.inline.} =
  result = cast[Webview](alloc0(sizeof(WebviewObj)))
  result.title = title
  result.url = url
  result.width = width.cint
  result.height = height.cint
  result.resizable = when resizable: 1 else: 0
  result.debug = when debug: 1 else: 0
  result.invokeCb = generalExternalInvokeCallback
  if callback != nil: result.externalInvokeCB = callback
  if result.init() != 0: return nil

proc newWebView*(path: static[string] = ""; title = ""; width: Positive = 640; height: Positive = 480; resizable: static[bool] = true; debug: static[bool] = not defined(release); callback: ExternalInvokeCb = nil,
    skipTaskbar: static[bool] = false, windowBorders: static[bool] = true, focus: static[bool] = false, keepOnTop: static[bool] = false,
    minimized: static[bool] = false, cssPath: static[string] = "", trayIcon: static[cstring] = "", fullscreen: static[bool] = false): Webview =
  ## Create a new Window with given attributes, all arguments are optional.
  ## * `path` is the URL or Full Path to 1 HTML file, index of the Web GUI App.
  ## * `title` is the Title of the Window.
  ## * `width` is the Width of the Window.
  ## * `height` is the Height of the Window.
  ## * `resizable` set to `true` to allow Resize of the Window, defaults to `true`.
  ## * `debug` Debug mode, Debug is `true` when not built for Release.
  ## * `skipTaskbar` if set to `true` the Window will not be visible on the desktop Taskbar.
  ## * `windowBorders` if set to `false` the Window will have no Borders, no Close button, no Minimize button.
  ## * `focus` if set to `true` the Window will force Focus.
  ## * `keepOnTop` if set to `true` the Window will keep on top of all other windows on the desktop.
  ## * `minimized` if set the `true` the Window will be Minimized, Iconified.
  ## * `cssPath` Full Path or URL of a CSS file to use as Style, defaults to `"dark.css"` for Dark theme, can be `"light.css"` for Light theme.
  ## * `trayIcon` Path to a local PNG Image Icon file.
  ## * `fullscreen` if set to `true` the Window will be forced Fullscreen.
  ## * If `--light-theme` on `commandLineParams()` then it will use Light Theme automatically.
  ## * CSS is embedded, if your app is used Offline, it will display Ok.
  ## * For templates that do CSS, remember that CSS must be injected *after DOM Ready*.
  ## * Is up to the developer to guarantee access to the HTML URL or File of the GUI.
  const url =
    when path.endsWith".html": fileLocalHeader & path
    elif path.endsWith".js" or path.endsWith".nim":
      dataUriHtmlHeader & "<!DOCTYPE html><html><head><meta content='width=device-width,initial-scale=1' name=viewport></head><body id=body ><div id=ROOT ><div></body></html>"  # Copied from Karax
    elif path.len == 0: dataUriHtmlHeader & staticRead"demo.html"
    else: dataUriHtmlHeader & path.strip
  result = webView(title, url, width, height, resizable, debug, callback)
  when skipTaskbar: result.setSkipTaskbar(skipTaskbar)
  when not windowBorders: result.setBorderlessWindow(windowBorders)
  when focus: result.setFocus()
  when keepOnTop: result.setOnTop(keepOnTop)
  when minimized: webviewindow.setIconify(minimized)
  when trayIcon.len > 0: result.setTrayIcon(trayIcon, title.cstring, visible = true)
  when fullscreen: result.setFullscreen(fullscreen)
  discard result.css(when cssPath.len > 0: static(staticRead(cssPath).cstring) else:
    if "--light-theme" in commandLineParams(): cssLight else: cssDark)
  when path.endsWith".js": result.js(readFile(path))
  when path.endsWith".nim":
    const compi = gorgeEx("nim js --out:" & path & ".js " & path & (when defined(release): " -d:release" else: "") & (when defined(danger): " -d:danger" else: ""))
    const jotaese = when compi.exitCode == 0: staticRead(path & ".js").strip.cstring else: "".cstring
    when not defined(release): echo jotaese
    when compi.exitCode == 0: echo result.js(jotaese)
