package main

import (
	"net/http"
)

func (app *application) routes() *http.ServeMux {
	mux := http.NewServeMux()

	mux.Handle("POST /send-notif", app.loggerMiddleware(http.HandlerFunc(app.sendNotificationHandler)))

	return mux
}
