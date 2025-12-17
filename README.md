# PHP Dev Stack (Docker)

A **Valet-style local development environment for PHP**, powered by Docker.  
Designed for developers who work with **Laravel, CodeIgniter 3, and Core PHP** and want fast local domains, trusted HTTPS, and zero per-project Docker configuration.

Projects live directly on macOS for performance, while PHP, Nginx, MySQL, and MailHog run in containers.

---

## Why This Exists

Laravel Valet is excellent — but:
- It’s macOS-only
- It’s Laravel-centric
- It relies on Homebrew PHP & services

This project provides a **Docker-first alternative** that:
- Works for **any PHP framework**
- Keeps your system clean
- Is easy to share across teams
- Feels just as simple as Valet

---

## Features

- Automatic local domains: `project.test`
- Trusted HTTPS via `mkcert`
- PHP 8.2 (Docker)
- Laravel, CodeIgniter 3, Core PHP support
- MySQL 5.7 with data persisted on host
- MailHog for email testing (`mailhog.test`)
- No per-project Docker files
- No Homebrew PHP / MySQL
- Projects stay on macOS (`~/Projects`)
- Generic, framework-agnostic containers

---

## Tech Stack

- Docker & Docker Compose
- Nginx
- PHP-FPM 8.2
- MySQL 5.7
- MailHog
- dnsmasq
- mkcert

---

## Requirements

- macOS
- Docker Desktop
- Homebrew

---

## Project Convention

All projects must follow this structure:

```
~/Projects/
└── project-name/
└── public/
└── index.php
```

Automatic mapping:

```
project-name.test → ~/Projects/project-name/public
````

---

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/<your-username>/php-dev-stack.git
cd php-dev-stack
````

---

### 2. Run the setup script

⚠️ This will remove any existing Docker dev-stack folders
(`~/docker/dev-stack`, not your projects).

```bash
chmod +x setup-dev-stack.sh
./setup-dev-stack.sh
```

---

## DNS Setup (One-Time)

Install dnsmasq:

```bash
brew install dnsmasq
```

Configure wildcard `.test` domain:

```bash
echo "address=/.test/127.0.0.1" | sudo tee /usr/local/etc/dnsmasq.conf
sudo brew services restart dnsmasq
```

Configure macOS resolver:

```bash
sudo mkdir -p /etc/resolver
echo "nameserver 127.0.0.1" | sudo tee /etc/resolver/test
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

Verify:

```bash
ping example.test
```

---

## HTTPS Setup (One-Time)

Install mkcert and trust local CA:

```bash
brew install mkcert
mkcert -install
```

Generate wildcard certificate:

```bash
cd ~/docker/dev-stack
mkcert "*.test"
mv _wildcard.test.pem certs/dev.test.pem
mv _wildcard.test-key.pem certs/dev.test-key.pem
```

> Note: Browsers fully support `project.test`.
> Nested subdomains like `a.b.test` are intentionally not supported.

---

## Start the Stack

```bash
cd ~/docker/dev-stack
docker-compose up -d --build
```

Verify containers:

```bash
docker ps
```

---

## Usage

### Applications

```
http://project.test
https://project.test
```

### MailHog

```
http://mailhog.test
https://mailhog.test
```

---

## Mail Configuration

### Laravel (`.env`)

```env
MAIL_MAILER=smtp
MAIL_HOST=mailhog
MAIL_PORT=1025
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
```

---

### CodeIgniter 3

```php
$config['protocol'] = 'smtp';
$config['smtp_host'] = 'mailhog';
$config['smtp_port'] = 1025;
```

---

## Database Configuration

### Inside applications

```env
DB_HOST=mysql
DB_USERNAME=laravel
DB_PASSWORD=secret
```

### From host tools (TablePlus, etc.)

```
Host: 127.0.0.1
Port: 3306
User: laravel
Password: secret
```

MySQL data is stored on host at:

```
~/docker/dev-stack/mysql-data
```

---

## Supported Project Types

| Type          | Supported |
| ------------- | --------- |
| Laravel       | ✅         |
| CodeIgniter 3 | ✅         |
| Core PHP      | ✅         |
| Legacy PHP    | ✅         |

All projects must expose a `public/` directory.

---

## What This Stack Intentionally Avoids

* Homebrew PHP
* Homebrew MySQL
* Per-project Docker files
* `.local` domains
* Browser HTTPS warnings
* Framework-specific assumptions

---

## Troubleshooting

* DNS issues → flush cache & restart dnsmasq
* HTTPS warnings → rerun `mkcert -install`
* App not loading → ensure `public/` exists
* MySQL permission issues → `sudo chown -R 999:999 mysql-data`

---

## Contributing

Contributions are welcome.

* Fork the repo
* Create a feature branch
* Open a PR with a clear description

Please keep changes:

* Framework-agnostic
* Backward compatible
* Documented

---

## License

MIT License

---

## Inspiration

Inspired by Laravel Valet —
built for **Docker-first**, **multi-framework**, **team-friendly** PHP development.
