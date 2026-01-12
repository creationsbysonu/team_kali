# Docker Deployment Guide

## 📋 Overview

This project is configured to run both locally and in Docker containers. The configuration automatically adapts based on environment variables.

---

## 🚀 Quick Start

### Local Development (Without Docker)

```bash
# Install dependencies
pip install -r requirements.txt

# Set environment variables (uses localhost by default)
# No REDIS_HOST needed - defaults to localhost

# Run migrations
python manage.py migrate

# Run development server
python manage.py runserver

# In another terminal, start Celery worker
celery -A sewa_sathi worker --loglevel=info
```

### Docker Development

```bash
# Build and start all services
docker-compose up --build

# Run migrations
docker-compose exec web python manage.py migrate

# Create superuser
docker-compose exec web python manage.py createsuperuser

# View logs
docker-compose logs -f

# Stop all services
docker-compose down
```

---

## 🏗️ Architecture

### Services

1. **web**: Django application (port 8000)
2. **db**: PostgreSQL database (port 5432)
3. **redis**: Redis for cache & Celery (port 6379)
4. **celery**: Celery worker for async tasks
5. **celery-beat**: Celery scheduler for periodic tasks
6. **flower**: Celery monitoring UI (port 5555)

### Network Communication

- **Local Dev**: `redis://localhost:6379`
- **Docker**: `redis://redis:6379` (uses service name)

The configuration in `settings.py` automatically uses the right host:

```python
REDIS_HOST = config('REDIS_HOST', default='localhost')
# Docker: REDIS_HOST=redis
# Local:  Uses 'localhost' (default)
```

---

## 🔧 Configuration

### Environment Variables

#### Local Development (.env)
```env
SECRET_KEY=your-secret-key
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1,0.0.0.0

# No REDIS_HOST needed - uses localhost by default
```

#### Docker Production (.env for docker-compose)
```env
SECRET_KEY=your-production-secret
DEBUG=False
ALLOWED_HOSTS=your-domain.com

# Docker service names
REDIS_HOST=redis
DB_HOST=db
DB_PORT=5432
```

---

## 📦 Digital Ocean Deployment

### Option 1: Docker Compose on Droplet

```bash
# 1. SSH into your droplet
ssh root@your-droplet-ip

# 2. Install Docker and Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
apt-get install docker-compose-plugin

# 3. Clone your repository
git clone your-repo-url
cd sewa_sathi_backend

# 4. Create .env file with production settings
cp .env.example .env
nano .env  # Edit with production values

# 5. Build and start
docker-compose up -d --build

# 6. Run migrations
docker-compose exec web python manage.py migrate

# 7. Create superuser
docker-compose exec web python manage.py createsuperuser

# 8. Collect static files
docker-compose exec web python manage.py collectstatic --noinput
```

### Option 2: Digital Ocean App Platform

Create `app.yaml`:

```yaml
name: sewa-sathi
services:
- name: web
  github:
    repo: your-username/your-repo
    branch: main
  build_command: pip install -r requirements.txt
  run_command: gunicorn sewa_sathi.wsgi:application --bind 0.0.0.0:8000
  envs:
  - key: REDIS_HOST
    value: ${redis.HOSTNAME}
  - key: DB_HOST
    value: ${db.HOSTNAME}
  
- name: celery-worker
  github:
    repo: your-username/your-repo
    branch: main
  build_command: pip install -r requirements.txt
  run_command: celery -A sewa_sathi worker --loglevel=info
  envs:
  - key: REDIS_HOST
    value: ${redis.HOSTNAME}

databases:
- name: db
  engine: PG
  version: "15"

- name: redis
  engine: REDIS
  version: "7"
```

---

## 🔍 Testing

### Test Redis & Celery (Local)

```bash
python test_redis_celery_quick.py
```

### Test Redis & Celery (Docker)

```bash
docker-compose exec web python test_redis_celery_quick.py
```

### Access Flower (Celery Monitor)

- **Local**: http://localhost:5555
- **Docker**: http://localhost:5555

---

## 📊 Service Health Checks

### Check Redis

```bash
# Local
redis-cli ping

# Docker
docker-compose exec redis redis-cli ping
```

### Check Celery

```bash
# Local
celery -A sewa_sathi inspect active

# Docker
docker-compose exec celery celery -A sewa_sathi inspect active
```

### Check All Services

```bash
docker-compose ps
```

---

## 🐛 Troubleshooting

### Redis Connection Failed

**Local:**
```bash
# Check if Redis is running
redis-cli ping

# Start Redis
redis-server
```

**Docker:**
```bash
# Check Redis logs
docker-compose logs redis

# Restart Redis
docker-compose restart redis
```

### Celery Worker Not Processing Tasks

**Local:**
```bash
# Check if worker is running
ps aux | grep celery

# Start worker
celery -A sewa_sathi worker --loglevel=info
```

**Docker:**
```bash
# Check celery logs
docker-compose logs celery

# Restart celery
docker-compose restart celery
```

### Database Connection Error

**Docker:**
```bash
# Check if DB is ready
docker-compose exec db pg_isready

# Check DB logs
docker-compose logs db
```

---

## 📝 Production Checklist

- [ ] Set `DEBUG=False` in .env
- [ ] Set strong `SECRET_KEY`
- [ ] Configure `ALLOWED_HOSTS` with your domain
- [ ] Set `JWT_COOKIE_SECURE=True` (requires HTTPS)
- [ ] Enable Redis persistence (RDB/AOF)
- [ ] Set up SSL/TLS certificates
- [ ] Configure firewall rules
- [ ] Set up monitoring (Sentry, Flower)
- [ ] Configure log rotation
- [ ] Set up automated backups
- [ ] Use strong database passwords
- [ ] Limit Redis memory usage
- [ ] Configure rate limiting

---

## 🔄 Updates and Maintenance

### Update Code (Docker)

```bash
# Pull latest code
git pull

# Rebuild and restart
docker-compose up -d --build

# Run migrations
docker-compose exec web python manage.py migrate
```

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f web
docker-compose logs -f celery
docker-compose logs -f redis
```

### Backup Database

```bash
# Backup
docker-compose exec db pg_dump -U postgres postgres > backup.sql

# Restore
docker-compose exec -T db psql -U postgres postgres < backup.sql
```

---

## 🎯 Summary

Your project is now **Docker-ready** and **future-proof**:

✅ **Local Development**: Works with `localhost` (no Docker needed)
✅ **Docker Development**: Run with `docker-compose up`
✅ **Production Ready**: Deploy to Digital Ocean with Docker
✅ **Scalable**: Add more workers easily
✅ **Monitored**: Flower for Celery monitoring
✅ **Persistent**: Data volumes for DB and Redis
✅ **Automatic**: Health checks and restart policies

**Key Feature**: Single codebase works everywhere - configuration adapts automatically based on environment variables!
