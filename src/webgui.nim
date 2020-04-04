import tables, strutils, macros, json

const headerC = currentSourcePath().substr(0, high(currentSourcePath()) - 10) & "webview.h"
{.passC: "-DWEBVIEW_STATIC -DWEBVIEW_IMPLEMENTATION -I" & headerC.}
when defined(linux):
  {.passC: "-DWEBVIEW_GTK=1 " & staticExec"pkg-config --cflags gtk+-3.0 webkit2gtk-4.0", passL: staticExec"pkg-config --libs gtk+-3.0 webkit2gtk-4.0".}
elif defined(windows):
  {.passC: "-DWEBVIEW_WINAPI=1", passL: "-lole32 -lcomctl32 -loleaut32 -luuid -lgdi32".}
elif defined(macosx):
  {.passC: "-DWEBVIEW_COCOA=1 -x objective-c", passL: "-framework Cocoa -framework WebKit".}

type
  ExternalInvokeCb* = proc (w: Webview; arg: string)
  WebviewPrivObj {.importc: "struct webview_priv", header: headerC, bycopy.} = object
  WebviewObj* {.importc: "struct webview", header: headerC, bycopy.} = object
    url* {.importc: "url".}: cstring
    title* {.importc: "title".}: cstring
    width* {.importc: "width".}: cint
    height* {.importc: "height".}: cint
    resizable* {.importc: "resizable".}: cint
    debug* {.importc: "debug".}: cint
    invokeCb {.importc: "external_invoke_cb".}: pointer
    priv {.importc: "priv".}: WebviewPrivObj
    userdata {.importc: "userdata".}: pointer
  Webview* = ptr WebviewObj
  DispatchFn* = proc()
  DialogType {.size: sizeof(cint).} = enum
    dtOpen = 0, dtSave = 1, dtAlert = 2
  CallHook = proc (params: string): string # json -> proc -> json
  MethodInfo = object
    scope, name, args: string

const
  dataUriHtmlHeader* = "data:text/html;charset=utf-8,"
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

func init(w: Webview): cint {.importc: "webview_init", header: headerC.}
func loop(w: Webview; blocking: cint): cint {.importc: "webview_loop", header: headerC.}
func js*(w: Webview; javascript: cstring): cint {.importc: "webview_eval", header: headerC.}  ## Evaluate a JavaScript cstring, runs the javascript string on the window
func css*(w: Webview; css: cstring): cint {.importc: "webview_inject_css", header: headerC.} ## Set a CSS cstring
func setTitle*(w: Webview; title: cstring) {.importc: "webview_set_title", header: headerC.}     ## Set Title of window
func setColor*(w: Webview; red, green, blue, alpha: uint8) {.importc: "webview_set_color", header: headerC.}  ## Set background color
func setFullscreen*(w: Webview; fullscreen: bool) {.importc: "webview_set_fullscreen", header: headerC.} ## Set fullscreen
func dialog(w: Webview; dlgtype: DialogType; flags: cint; title: cstring; arg: cstring; result: cstring; resultsz: system.csize_t) {.importc: "webview_dialog", header: headerC.}
func dispatch(w: Webview; fn: pointer; arg: pointer) {.importc: "webview_dispatch", header: headerC.}
func webview_terminate(w: Webview) {.importc: "webview_terminate", header: headerC.}
func webview_exit(w: Webview) {.importc: "webview_exit", header: headerC.}   ## Exit and quit
func jsDebug*(format: cstring) {.varargs, importc: "webview_debug", header: headerC.}  ##  `console.debug()` directly inside the JavaScript context.
func jsLog*(s: cstring) {.importc: "webview_print_log", header: headerC.} ## `console.log()` directly inside the JavaScript context.
func webview(title: cstring; url: cstring; w: cint; h: cint; resizable: cint): cint {.importc: "webview", header: headerC, used.}
func setUrl*(w: Webview; url: cstring) {.importc: "webview_launch_external_URL", header: headerC.} ## Set the URL
func setIconify*(w: Webview; mustBeIconified: bool) {.importc: "webview_set_iconify", header: headerC.}  ## Set window to be Minimized Iconified

func setBorderless*(w: Webview, decorated: bool) {.inline.} =
  ## Use a window without borders, no close nor minimize buttons.
  when defined(linux): {.emit: "gtk_window_set_decorated(GTK_WINDOW(`w`->priv.window), `decorated`);".}

func setSkipTaskbar*(w: Webview, hint: bool) {.inline.} =
  ## Do not show the window on the Taskbar
  when defined(linux): {.emit: "gtk_window_set_skip_taskbar_hint(GTK_WINDOW(`w`->priv.window), `hint`); gtk_window_set_skip_pager_hint(GTK_WINDOW(`w`->priv.window), `hint`);".}

func setSize*(w: Webview, width: Positive, height: Positive) {.inline.} =
  ## Resize the window
  when defined(linux): {.emit: "gtk_widget_set_size_request(GTK_WINDOW(`w`->priv.window), `width`, `height`);".}

func setFocus*(w: Webview) {.inline.} =
  ## Force focus on the window
  when defined(linux): {.emit: "gtk_widget_grab_focus(GTK_WINDOW(`w`->priv.window));".}

func setOnTop*(w: Webview, mustBeOnTop: bool) {.inline.} =
  ## Force window to be on top of all other windows
  when defined(linux): {.emit: "gtk_window_set_keep_above(GTK_WINDOW(`w`->priv.window), `mustBeOnTop`);".}

func setClipboard*(w: Webview, text: cstring) {.inline.} =
  ## Set a text cstring on the Clipboard
  assert text.len > 0, "text for clipboard must not be empty string"
  when defined(linux): {.emit: "gtk_clipboard_set_text(gtk_clipboard_get(GDK_SELECTION_CLIPBOARD), `text`, -1);".}

func setTrayIcon*(w: Webview, path: cstring, visible = true) {.inline.} =
  ## Set a TrayIcon on the corner of the desktop. ``path`` is full path to a PNG image icon. Only shows an icon.
  assert path.len > 0, "icon path must not be empty string"
  when defined(linux): {.emit: "GtkStatusIcon* webview_icon_nim = gtk_status_icon_new_from_file(`path`); gtk_status_icon_set_visible(webview_icon_nim, `visible`);".}

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
  ## Set the external invoke callback for webview
  cbs[w] = callback

proc generalDispatchProc(w: Webview; arg: pointer) {.exportc.} =
  let idx = cast[int](arg)
  let fn = dispatchTable[idx]
  fn()

proc dispatch*(w: Webview; fn: DispatchFn) {.inline.} =
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
  w.dialog(dtOpen, flag = 0, title, "")

template dialogSave*(w: Webview; title = ""): string =
  ## Opens a dialog that requests a filename to save to from the user.
  ## Returns "" if the user closed the dialog without selecting a file.
  w.dialog(dtSave, flag = 0, title, "")

template dialogOpenDir*(w: Webview; title = ""): string =
  ## Opens a dialog that requests a Directory from the user.
  w.dialog(dtOpen, flag = 1, title, "")

func run*(w: Webview) {.inline.} =
  ## ``run`` starts the main UI loop until the user closes the webview window or `exit()` is called.
  while w.loop(1) == 0: discard

func exit*(w: Webview) {.inline.} =
  ## Terminate and Exit.
  w.webview_terminate()
  w.webview_exit()

template setTheme*(w: Webview; dark: bool) =
  ## Set Dark Theme or Light Theme on-the-fly.
  discard w.css(if dark: cssDark else: cssLight)

template imgLazyLoadHtml*(src, id: string, width = "", heigth = "", class = "",  alt = ""): string =
  ## HTML Image LazyLoad. https://codepen.io/FilipVitas/pen/pQBYQd (Must have ID!)
  imageLazy.format(src, id, width, heigth, class,  alt)

proc bindProc[P, R](w: Webview; scope, name: string; p: (proc(param: P): R)) {.used.} =
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

proc bindProcNoArg(w: Webview; scope, name: string; p: proc()) {.used.} =
  assert name.len > 0, "Name must not be empty string"
  proc hook(hookParam: string): string =
    p()
    return ""
  discard eps.hasKeyOrPut(w, newTable[string, TableRef[string, CallHook]]())
  discard hasKeyOrPut(eps[w], scope, newTable[string, CallHook]())
  eps[w][scope][name] = hook
  w.dispatch(proc() = discard w.js(jsTemplateNoArg % [name, scope]))

proc bindProc[P](w: Webview; scope, name: string; p: proc(arg: P)) {.used.} =
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
  ## bind procs like:
  ##
  ## .. code-block:: nim
  ##
  ##    proc fn[T, U](arg: T): U
  ##    proc fn[T](arg: T)
  ##    proc fn()
  ##
  ## to webview ``w``, in scope ``scope``
  ## then you can invode in js side, like this:
  ##
  ## .. code-block:: js
  ##
  ##    scope.fn(arg)
  ##
  assert scope.len > 0, "Scope must not be empty string"
  expectKind(n, nnkStmtList)
  let body = n
  for def in n:
    expectKind(def, nnkProcDef)
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
  const url =
    when path.endsWith".html": "file:///" & path
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
  when trayIcon.len > 0: result.setTrayIcon(trayIcon, visible = true)
  when fullscreen: result.setFullscreen(fullscreen)
  discard result.css(when cssPath.len > 0: static(staticRead(cssPath).cstring) else: cssDark)
  when path.endsWith".js": result.js(readFile(path))
  when path.endsWith".nim":
    const compi = gorgeEx("nim js --out:" & path & ".js " & path & (when defined(release): " -d:release" else: "") & (when defined(danger): " -d:danger" else: ""))
    const jotaese = when compi.exitCode == 0: staticRead(path & ".js").strip.cstring else: "".cstring
    when not defined(release): echo jotaese
    when compi.exitCode == 0: echo result.js(jotaese)