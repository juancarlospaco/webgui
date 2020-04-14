import webgui, strutils
let app = newWebView(currentHtmlPath())

app.css(app.setShake("#a", shakeCrazy))
app.css(app.setShake("#b", shakeSimple))
app.css(app.setShake("#c", shakeHard))
app.css(app.setShake("#d", shakeHorizontal))
app.css(app.setShake("#e", shakeTiny))
app.css(app.setShake("#f", shakeSpin))
app.css(app.setShake("#g", shakeSlow))
app.css(app.setShake("#h", shakeVertical))

app.run()
app.exit()
