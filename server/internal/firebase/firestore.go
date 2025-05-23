package firebase

import (
	"context"
	"log"
	"time"

	"cloud.google.com/go/firestore"
)

type FirestoreClient struct {
	client *firestore.Client
	logger *log.Logger
}

type NotificationPayload struct {
	Title       string    `firestore:"title"`
	Body        string    `firestore:"body"`
	SenderUID   string    `firestore:"senderId"`
	RecieverUID string    `firestore:"receiverId"`
	CreatedAt   time.Time `firestore:"createdAt"`
}

type UserPayload struct {
	FirstName string   `firestore:"firstName"`
	LastName  string   `firestore:"lastName"`
	FCMTokens []string `firestore:"fcmTokens"`
}

func (f *FirestoreClient) GetUserByUID(ctx context.Context, uid string) (*UserPayload, error) {
	userDoc, err := f.client.Collection("users").Doc(uid).Get(ctx)
	if err != nil {
		f.logger.Printf("Error getting user %s document: %v", uid, err)
		return nil, err
	}

	var userData UserPayload

	if err := userDoc.DataTo(&userData); err != nil {
		f.logger.Printf("Error unmarshalling user %s data: %v", uid, err)
		return nil, err
	}

	f.logger.Printf("user loaded: %v", userData)

	return &userData, nil
}

func (f *FirestoreClient) CreateNotification(ctx context.Context, notification NotificationPayload) error {
	_, _, err := f.client.Collection("notifications").Add(ctx, notification)

	if err != nil {
		f.logger.Printf("Error creating notification document for %s: %v", notification.RecieverUID, err)
		return err
	}

	return nil
}
