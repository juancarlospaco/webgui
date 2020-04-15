import webgui
let app = newWebView(currentHtmlPath())
app.js(app.addHtml("#a", app.datetimePicker(yearID = "y", monthID = "m", dayID = "d", hourID = "h", minuteID = "x",  secondID = "s", year = 2020, month = 6, day = 9)))
app.run()
app.exit()
