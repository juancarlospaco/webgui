import webgui, os, strutils
let app = newWebView(currentHtmlPath())

app.css(app.setBlink("#a"))

app.run()
app.exit()
