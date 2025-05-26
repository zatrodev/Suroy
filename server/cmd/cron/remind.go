package main

import (
	"context"
	"fmt"
	"log"

	"cloud.google.com/go/firestore"
	"firebase.google.com/go/v4/messaging"
	"github.com/CMSC-23-2nd-Sem-2024-2025-ecisungga/project-suroy/internal/firebase"
)

func SendStartDateReminders(ctx context.Context, client *firebase.FirestoreClient, fcmClient *firebase.FCMClient) error {

	iter := client.GetNearingTravelPlans(ctx)
	defer iter.Stop()
	for {
		doc, err := iter.Next()
		if err != nil {
			if err.Error() == "iterator done" {
				break
			}
			log.Printf("Error iterating travel plans: %v", err)
			return fmt.Errorf("iteration error: %w", err)
		}

		var planData map[string]any
		if err := doc.DataTo(&planData); err != nil {
			log.Printf("Error converting plan data for doc %s: %v", doc.Ref.ID, err)
			continue
		}

		planName, _ := planData["name"].(string)
		ownerID, ok := planData["ownerId"].(string)
		if !ok || ownerID == "" {
			log.Printf("Missing or invalid ownerId for plan %s", doc.Ref.ID)
			continue
		}

		log.Printf("Found plan starting soon: %s (ID: %s) for owner: %s", planName, doc.Ref.ID, ownerID)

		user, err := client.GetUserByUsername(ctx, ownerID)

		fcmTokens := user.FCMTokens
		notification := messaging.Notification{
			Title: "Trip Reminder!",
			Body:  fmt.Sprintf("Your trip '%s' is starting tomorrow!", planName),
		}

		if err = fcmClient.SendNotifcationToTokens(ctx, fcmTokens, notification); err != nil {
			return err
		}

		log.Printf("Successfully sent message for plan %s", doc.Ref.ID)

		_, err = doc.Ref.Update(ctx, []firestore.Update{
			{Path: "isStartDateReminderSent", Value: true},
			{Path: "startDateReminderSentAt", Value: firestore.ServerTimestamp},
		})
		if err != nil {
			log.Printf("Error updating plan %s after sending reminder: %v", doc.Ref.ID, err)
		}
	}

	return nil
}
