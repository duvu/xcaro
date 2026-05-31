package email

import (
	"fmt"
	"os"
	"strconv"

	gomail "github.com/wneessen/go-mail"
)

func SendVerificationEmail(to, token string) error {
	host := os.Getenv("SMTP_HOST")
	portStr := os.Getenv("SMTP_PORT")
	user := os.Getenv("SMTP_USER")
	pass := os.Getenv("SMTP_PASS")
	from := os.Getenv("SMTP_FROM")

	if host == "" {
		return fmt.Errorf("SMTP_HOST not configured")
	}

	port, _ := strconv.Atoi(portStr)
	if port == 0 {
		port = 587
	}

	appURL := os.Getenv("APP_URL")
	if appURL == "" {
		appURL = "http://localhost:8080"
	}
	link := fmt.Sprintf("%s/api/auth/verify-email?token=%s", appURL, token)

	m := gomail.NewMsg()
	if err := m.From(from); err != nil {
		return err
	}
	if err := m.To(to); err != nil {
		return err
	}
	m.Subject("Verify your PlayVerse email")
	m.SetBodyString(gomail.TypeTextHTML, fmt.Sprintf(`<p>Click <a href="%s">here</a> to verify your email. Link expires in 24 hours.</p>`, link))

	c, err := gomail.NewClient(host, gomail.WithPort(port),
		gomail.WithSMTPAuth(gomail.SMTPAuthPlain),
		gomail.WithUsername(user),
		gomail.WithPassword(pass))
	if err != nil {
		return err
	}
	return c.DialAndSend(m)
}
