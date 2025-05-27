# How to run the appp:

## Prerequisites 

Make sure the following are installed:
**Flutter SDK and Go**: Check if the following are installed
```bash
flutter doctor
go version
```

If not, kindly refer to these links for the installation guide:
- [Flutter installation](https://docs.flutter.dev/install)
- [Go installation](https://go.dev/doc/install)

**git**: Check if git is installed.
```bash
git --version
```

If not, kindly refer to this link for the installation guide: [Git installation](https://git-scm.com/downloads)

If the prerequisites are installed, clone the git repository.

```bash
git clone https://github.com/CMSC-23-2nd-Sem-2024-2025-ecisungga/project-suroy.git
```

Navigate to the project folder
```bash
cd project-suroy
```

## Starting the application
To run the application, use multiple terminal instances.

### Starting the app itself
```bash
# From the root directory
flutter run
```

### Starting the notification server
```bash
# From the root directory
cd server
go run ./cmd/api
```
```bash
To start the "remind" notification
go run ./cmd/cron
```