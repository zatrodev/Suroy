package main

import (
	"fmt"
	"net/http"
	"time"

	"firebase.google.com/go/v4/messaging"
	"github.com/CMSC-23-2nd-Sem-2024-2025-ecisungga/project-suroy/internal/firebase"
)

func (app *application) sendNotificationHandler(w http.ResponseWriter, r *http.Request) {
	var input struct {
		SenderUID   string `json:"senderUid"`
		ReceiverUID string `json:"receiverUid"`
	}

	if err := app.readJSON(w, r, &input); err != nil {
		print(err.Error())
		app.badRequestResponse(w, r, err)
		return
	}

	if input.SenderUID == "" {
		app.badRequestResponse(w, r, nil)
		app.logger.Panic("senderUid can't be empty.")
		return
	}

	if input.ReceiverUID == "" {
		app.badRequestResponse(w, r, nil)
		app.logger.Panic("receiverUid can't be empty.")
		return
	}

	if input.SenderUID == input.ReceiverUID {
		app.badRequestResponse(w, r, nil)
		app.logger.Panic("Can't send a notification to yourself.")
		return
	}

	senderUser, err := app.services.Firestore.GetUserByUID(r.Context(), input.SenderUID)
	if err != nil {
		app.serverErrorResponse(w, r, err)
		return
	}

	receiverUser, err := app.services.Firestore.GetUserByUID(r.Context(), input.ReceiverUID)
	if err != nil {
		app.serverErrorResponse(w, r, err)
		return
	}

	currentTime := time.Now()
	notificationData := &firebase.NotificationPayload{
		Title:       fmt.Sprintf("%s %s sent you a friend request.", senderUser.FirstName, senderUser.LastName),
		Body:        fmt.Sprintf("%s %d, %d | %d:%d", currentTime.Month(), currentTime.Day(), currentTime.Year(), currentTime.Hour(), currentTime.Minute()),
		SenderUID:   input.SenderUID,
		RecieverUID: input.ReceiverUID,
		CreatedAt:   time.Now(),
	}

	if err = app.services.Firestore.CreateNotification(r.Context(), *notificationData); err != nil {
		app.serverErrorResponse(w, r, err)
		return
	}

	actualNotification := messaging.Notification{
		Title: notificationData.Title,
		Body:  notificationData.Body,
	}

	if err = app.services.FCM.SendNotifcationToTokens(r.Context(), receiverUser.FCMTokens, actualNotification); err != nil {
		app.serverErrorResponse(w, r, err)
		return
	}

	if err := app.writeJSON(w, http.StatusOK, envelope{"notification": input}, nil); err != nil {
		app.serverErrorResponse(w, r, err)
	}
}
