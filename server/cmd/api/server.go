package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/CMSC-23-2nd-Sem-2024-2025-ecisungga/project-suroy/internal/firebase"
)

type application struct {
	logger   *log.Logger
	config   config
	services firebase.Services
}

type config struct {
	port   int
	apiURL string
	fcm    struct {
		serviceAccountKeyPath string
	}
}

func (app *application) serve() error {
	s := &http.Server{
		Addr:         fmt.Sprintf(":%d", app.config.port),
		Handler:      app.routes(),
		IdleTimeout:  120 * time.Second,
		ReadTimeout:  1 * time.Second,
		WriteTimeout: 1 * time.Second,
	}

	go func() {
		app.logger.Print("starting server", map[string]string{
			"addr": s.Addr,
		})

		if err := s.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("ListenAndServe	(): %v", err)
		}
	}()

	signalChannel := make(chan os.Signal, 1)
	signal.Notify(signalChannel, os.Interrupt, syscall.SIGTERM)

	sig := <-signalChannel
	log.Println("Received terminate signal, initiating graceful shutdown:", sig)

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := s.Shutdown(ctx); err != nil {
		return err
	}
	log.Println("Server exited properly")

	return nil
}
