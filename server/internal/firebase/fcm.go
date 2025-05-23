package firebase

import (
	"context"
	"log"

	"firebase.google.com/go/v4/messaging"
)

type FCMClient struct {
	client *messaging.Client
	logger *log.Logger
}

func (fcm *FCMClient) SendNotifcationToTokens(ctx context.Context, tokens []string, notification messaging.Notification) error {
	for _, token := range tokens {
		message := &messaging.Message{
			Notification: &notification,
			Token:        token,
		}
		_, err := fcm.client.Send(ctx, message)

		if err != nil {
			fcm.logger.Printf("Failed sending notification: %v", err)
			return err
		}
	}

	return nil
}
