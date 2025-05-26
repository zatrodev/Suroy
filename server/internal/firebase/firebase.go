package firebase

import (
	"context"
	"fmt"
	"log"
	"os"

	firebase "firebase.google.com/go/v4"
	"google.golang.org/api/option"
)

type Services struct {
	Firestore FirestoreClient
	FCM       FCMClient
}

func NewServices(ctx context.Context, serviceAccountKeyPath string) *Services {
	opt := option.WithCredentialsFile(serviceAccountKeyPath)

	app, err := firebase.NewApp(ctx, nil, opt)
	if err != nil {
		var a []any = []any{err}
		fmt.Fprintf(os.Stdout, "error getting Firebase App: %w", a...)
		return nil
	}

	firestoreClient, err := app.Firestore(ctx)
	if err != nil {
		fmt.Printf("error getting Firebase Firestore client: %w", err)
		return nil
	}

	messagingClient, err := app.Messaging(ctx)
	if err != nil {
		fmt.Errorf("error getting Firebase Messaging client: %w", err)
		return nil
	}

	return &Services{
		Firestore: FirestoreClient{
			client: firestoreClient,
			logger: log.New(os.Stdout, "suroy-firestore", log.LstdFlags),
		},
		FCM: FCMClient{
			client: messagingClient,
			logger: log.New(os.Stdout, "suroy-firestore", log.LstdFlags),
		},
	}
}
