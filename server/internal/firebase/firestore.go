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
	Type        string    `firestore:"type"`
}

type UserPayload struct {
	FirstName string   `firestore:"firstName"`
	LastName  string   `firestore:"lastName"`
	FCMTokens []string `firestore:"fcmTokens"`
}

func (f *FirestoreClient) GetUserByUsername(ctx context.Context, username string) (string, *UserPayload, error) {
	iter := f.client.Collection("users").Where("username", "==", username).Documents(ctx)

	userDoc, err := iter.Next()
	if err != nil {
		if err.Error() == "iterator done" {
			return "", nil, err
		}

		log.Printf("Error iterating travel plans: %v", err)
		return "", nil, err
	}

	var userData UserPayload

	if err := userDoc.DataTo(&userData); err != nil {
		f.logger.Printf("Error unmarshalling user %s data: %v", username, err)
		return "", nil, err
	}

	f.logger.Printf("user loaded: %v", userData)

	return userDoc.Ref.ID, &userData, nil
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

func (f *FirestoreClient) GetNearingTravelPlans(ctx context.Context) *firestore.DocumentIterator {
	loc, _ := time.LoadLocation("Asia/Shanghai")
	now := time.Now().In(loc)
	tomorrowStart := time.Date(now.Year(), now.Month(), now.Day()+1, 0, 0, 0, 0, loc)
	dayAfterTomorrowStart := time.Date(now.Year(), now.Month(), now.Day()+2, 0, 0, 0, 0, loc)

	f.logger.Printf("Checking for plans starting between %v and %v\n", tomorrowStart, dayAfterTomorrowStart)

	iter := f.client.Collection("travel_plans").
		Where("isStartDateReminderSent", "==", false).
		Where("startDate", ">=", tomorrowStart).
		Documents(ctx)

	f.logger.Printf("Iterations: %v", iter)

	return iter
}
