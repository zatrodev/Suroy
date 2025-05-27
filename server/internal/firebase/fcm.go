package firebase

import (
	"context"
	"errors"
	"log"

	"firebase.google.com/go/v4/messaging"
)

type FCMClient struct {
	client *messaging.Client
	logger *log.Logger
}

func (fcm *FCMClient) SendNotifcationToTokens(ctx context.Context, tokens []string, notification messaging.Notification, payload map[string]string) error {
	var encounteredErrors []bool
	for _, token := range tokens {
		message := &messaging.Message{
			Data:         payload,
			Notification: &notification,
			Token:        token,
		}
		_, err := fcm.client.Send(ctx, message)

		if err != nil {
			encounteredErrors = append(encounteredErrors, true)
			continue
		}
	}

	if len(encounteredErrors) == len(tokens) {
		return errors.New("Failed sending notification. All FCM tokens failed.")
	}

	return nil
}
