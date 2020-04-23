import webgui, osproc
let app = newWebView(currentHtmlPath())

app.bindProcs("api"):
  proc callback() = echo execCmd("echo 'Nim is awesome'")

app.run()
app.exit()
