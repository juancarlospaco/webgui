import webgui
let app = newWebView(currentHtmlPath())
app.js(app.addHtml("#a", app.datePicker(yearID = "y", monthID = "m", dayID = "d", year = 2020, month = 6, day = 9)))
app.run()
app.exit()
