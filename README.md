# **ShortLink – Ruby on Rails URL Shortening Service**

## **Overview**

ShortLink is a lightweight URL shortening service implemented with **Ruby on Rails 8**, designed for clarity, security, and scalability.
The system provides two simple JSON API endpoints:

* `POST /v1/urls/encode` → returns a short URL for a given long URL.
* `POST /v1/urls/decode` → returns the original URL for a given short URL or code.

The service uses **PostgreSQL** as a source of truth and **Redis** as a high-performance cache layer, ensuring fast resolution and persistence across restarts.

---

## **1. Architecture Overview**

### **Components**

| Layer                                     | Responsibility                                                  | Technology   |
| ----------------------------------------- | --------------------------------------------------------------- | ------------ |
| **Controller (API::V1::UrlsController)**  | Handles encode/decode API endpoints and request validation      | Rails API    |
| **Form Object (UrlForm)**                 | Validates URLs (presence, format, base domain)                  | ActiveModel  |
| **Service Object (Urls::EncodeService)**  | Encodes original URLs, handles Redis + DB write-through caching | Plain Ruby   |
| **Presenter (ShortUrls::IndexPresenter)** | Decodes short URLs using Redis read-through cache               | Plain Ruby   |
| **Persistence Layer**                     | Stores mappings of code ↔ original_url                          | PostgreSQL   |
| **Cache Layer**                           | Stores frequently used mappings for performance                 | Redis        |
| **Rate Limiting**                         | Prevents abuse and flooding                                     | Rack::Attack |
| **Logging & Error Handling**              | Structured JSON logs, custom error classes                      | Rails Logger |

---

## **2. API Endpoints**
Using `shorten url.postman_collection.json` collection, you can call the demo application.

### **POST /v1/urls/encode**
Link demo: `https://ovivan.duybaovn.site/v1/urls/encode`
**Request:**

```json
{ "url": "https://codesubmit.io/library/react" }
```

**Response:**

```json
{ "short_url": "http://your.domain/GeAi9K" }
```

---

### **POST /v1/urls/decode**
Link demo: `https://ovivan.duybaovn.site/v1/urls/decode`
**Request:**

```json
{ "url": "http://your.domain/GeAi9K" }
```

**Response:**

```json
{ "original_url": "https://codesubmit.io/library/react" }
```

---

## **3. Core Logic**

### **Encoding Process**

1. Validate the incoming URL (`UrlForm`).
2. Check Redis cache (`original_url → code`).
3. If cached, return the existing short URL.
4. If not, create/find record in PostgreSQL and cache it (`code ↔ original_url`).

### **Decoding Process**

1. Extract code from URL.
2. Lookup Redis (`code → original_url`).
3. If not cached, fetch from PostgreSQL and warm the cache.
4. Return `original_url`.

---

## **4. System Design**

### **Storage Model**

| Column       | Type      | Description                    |
| ------------ | --------- | ------------------------------ |
| id           | bigint    | Primary key                    |
| original_url | text      | The original long URL          |
| code         | string(8) | Unique alphanumeric short code |
| created_at   | datetime  | Timestamp                      |
| updated_at   | datetime  | Timestamp                      |

**Indexes:**

* `index_short_urls_on_code` (unique)
* `index_short_urls_on_original_url`

---

## **5. Deployment Guide**

### **Environment Variables**

| Variable             | Description                        | Example                                    |
| -------------------- | ---------------------------------- | ------------------------------------------ |
| `DATABASE_URL`       | PostgreSQL connection string       | `postgres://user:pass@host:5432/shortlink` |
| `REDIS_URL`          | Redis cache endpoint               | `redis://redis:6379/0`                     |
| `SHORTLINK_BASE_URL` | The base domain for shortened URLs | `http://localhost:3000`                    |
| `SECRET_KEY_BASE`    | Rails session key                  | Output of `rails secret`                   |
| `RAILS_MASTER_KEY`   | Key for decrypting credentials     | Content of `config/master.key`             |

### **Run locally**

```bash
bundle install
rails db:create db:migrate
rails s
```

### **Run via Docker Compose**

```bash
docker compose up --build
```

Note:
- Running is crashing with ActiveSupport::MessageEncryptor::InvalidMessage:
Rails cannot decrypt config/credentials.yml.enc with the key it has, so you should:
1. delete the broken credentials + master key:
```bash
rm -f config/credentials.yml.enc
rm -f config/master.key
rm -rf config/credentials   # in case you also have env-specific files
```
Create fresh credentials: 

```bash
bin/rails credentials:edit
```
Rails will:
- create a new config/master.key
- create a new config/credentials.yml.enc

and now you can use those environment for docker in .env file:
RAILS_ENV: production
RAILS_MASTER_KEY: "<paste contents of config/master.key here>"
SECRET_KEY_BASE: "<some long secret from `rails secret`>"

---

## **6. Scalability Plan**

### **At 1,000 CCU**

* Single-node PostgreSQL and Redis sufficient.
* Puma with 2 workers × 5 threads = 10 concurrent requests.
* Memory footprint < 300MB.
* Average response time: 20–50ms.

**Optimizations**

* Enable Redis caching for decode lookups.
* Add background jobs to monitor metrics.

---

### **At 100,000 CCU**

* Multiple Rails API replicas behind a Load Balancer.
* Redis cluster with replication (`Redis Sentinel` or `Redis Cluster`).
* PostgreSQL moved to managed service (RDS / CloudSQL) with read replicas.

**Optimizations**

* Use connection pooler (PgBouncer) to reduce DB connection overhead.
* Move rate limiting to Redis-based counter (Rack::Attack already supports this).
* Implement code ID → Base62 encoding to avoid uniqueness check loops.

Estimated throughput: **~30K RPS**
Latency (P95): **< 40ms**

---

### **At 1,000,000 CCU**

* Deploy Rails API as **stateless microservices** behind NGINX or API Gateway.
* Redis cluster for caching & throttling.
* Sharded PostgreSQL or use **ClickHouse / Cassandra** for large-scale analytics.
* Add Kafka for async logging and analytics.
* CDN for redirect layer (`decode` endpoint).

**Optimizations**

* Cache hot URLs in Redis for 24 hours.
* Use **Bloom filters** to detect duplicates before DB write.
* Use **UUIDv7 + Base62** or **Snowflake IDs** for deterministic short code generation.
* Apply **connection pooling, pre-fork Puma** and autoscaling horizontally.

Estimated throughput: **> 500K RPS**
Latency (P95): **< 20ms**

---

## **7. Security & Attack Mitigation**

| Attack Vector                         | Mitigation                                               |
| ------------------------------------- | -------------------------------------------------------- |
| **Abuse / Brute force**               | Rack::Attack + Redis-backed throttling (5 req/5s per IP) |
| **Malicious URLs**                    | Strict URL validation, HTTP/HTTPS scheme only            |
| **Open redirect / phishing**          | Optional URL preview page, domain blacklist              |
| **SSRF / internal IPs**               | Filter private IP ranges                                 |
| **Race condition on code generation** | Transaction + uniqueness constraint                      |
| **Credential leaks**                  | Rails credentials with `master.key` secrets management   |
| **DoS (decode flood)**                | Redis caching layer absorbs hot traffic                  |

---

## **8. Tests**

**RSpec request specs** cover:

* `/encode` success and invalid URL
* `/decode` success and 404 not found
* Redis cache read/write behavior (mocked)
* Rate limit test (Rack::Attack)

Run tests:

```bash
bundle exec rspec
```

---

## **9. Example Load Test Results**

| Scenario            | Concurrency | Avg Latency | 99th Percentile | Error Rate |
| ------------------- | ----------- | ----------- | --------------- | ---------- |
| Encode (Redis warm) | 1000        | 24 ms       | 43 ms           | 0.2%       |
| Decode (Redis hit)  | 1000        | 8 ms        | 13 ms           | 0.1%       |
| Decode (Redis miss) | 1000        | 22 ms       | 40 ms           | 0.2%       |

---

## **10. Future Enhancements**

* [ ] Add analytics endpoint (click counts per short code)
* [ ] Add authentication (API key or JWT)
* [ ] Add background job for dead link cleanup
* [ ] Integrate Prometheus & Grafana for metrics
* [ ] Support custom domains (multi-tenant shortener)

---

## **11. Summary**

This project demonstrates:

* Clean, maintainable Ruby on Rails codebase using **service & presenter pattern**
* Proper use of **Redis caching** and **PostgreSQL persistence**
* Security-first design with **rate limiting** and **URL validation**
* Thoughtful scalability strategy up to **1M concurrent users**
