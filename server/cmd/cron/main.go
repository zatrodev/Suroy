package main

import (
	"context"
	"flag"
	"log"
	"os"

	"github.com/CMSC-23-2nd-Sem-2024-2025-ecisungga/project-suroy/internal/firebase"
	"github.com/joho/godotenv"
)

type config struct {
	port   int
	apiURL string
	fcm    struct {
		serviceAccountKeyPath string
	}
}

func main() {
	err := godotenv.Load()
	if err != nil {
		log.Fatal("Error loading .env file")
	}

	var cfg config

	flag.IntVar(&cfg.port, "port", 4000, "API Server Port")
	flag.StringVar(&cfg.fcm.serviceAccountKeyPath, "service-account-key-path", os.Getenv("SERVICE_ACCOUNT_KEY_PATH"), "Service Account Key Path")

	flag.Parse()

	ctx := context.Background()

	services := *firebase.NewServices(ctx, cfg.fcm.serviceAccountKeyPath)

	SendStartDateReminders(ctx, &services.Firestore, &services.FCM)
}
