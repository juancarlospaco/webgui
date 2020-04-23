import webgui
let app = newWebView(currentHtmlPath())

app.bindProcs("api"):
  proc callback() = echo app.js("console.log('Nim is awesome')")

app.run()
app.exit()
