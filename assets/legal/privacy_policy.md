# Privacy Policy

**Last Updated:** July 2025  
**App:** ReLog2 — Collaborative Travel Journals

---

## 1. Overview

ReLog2 ("we," "our," "us") respects your privacy. This Privacy Policy explains how we collect, use, share, and protect your information when you use our mobile application (the "App").

By using ReLog2, you agree to the collection and use of information in accordance with this policy.

---

## 2. Information We Collect

### 2.1 Information You Provide

| Category | Examples |
|----------|----------|
| **Account** | Email address, phone number (for SMS auth) |
| **Profile** | Display name, avatar (optional) |
| **Content** | Photos, videos, voice recordings, text notes, location data you capture |
| **Communications** | Chat messages in shared journals |

### 2.2 Information Collected Automatically

| Data | Purpose |
|------|---------|
| **Device info** | Model, OS version, unique device identifiers (for push notifications) |
| **Usage analytics** | Feature usage, crash reports, performance metrics |
| **Location** | GPS coordinates (only when you explicitly capture a memory with location) |
| **App diagnostics** | Crash logs, error reports (via Firebase Crashlytics) |

### 2.3 Information from Third Parties

- **Firebase Authentication** — Email/password and phone number verification
- **Firebase Cloud Messaging** — Push notification tokens
- **Cloudflare R2** — Encrypted media storage (photos, videos, audio)

---

## 3. How We Use Your Information

| Purpose | Legal Basis |
|---------|-------------|
| Create and manage your account | Contract |
| Sync your journals across devices | Contract |
| Enable collaborative features (shared journals, chat) | Contract |
| Send push notifications (new memories, messages) | Legitimate interest / Consent |
| Improve app stability and performance | Legitimate interest |
| Comply with legal obligations | Legal requirement |

We **do not sell** your personal data to third parties.

---

## 4. Data Sharing

### 4.1 With Your Consent
- Shared journal members see your name, email (first letter), and content you add
- Push notifications sent via Firebase Cloud Messaging

### 4.2 Service Providers (Processors)
| Provider | Purpose | Data |
|----------|---------|------|
| **Supabase** | Auth, database, realtime, edge functions | Account, journals, messages, metadata |
| **Firebase** | Auth, FCM push notifications, Crashlytics | Device tokens, crash logs, analytics |
| **Cloudflare R2** | Encrypted media storage | Photos, videos, voice recordings |

All processors are bound by Data Processing Agreements and process data only on our instructions.

### 4.3 Legal Requirements
We may disclose data if required by law, court order, or to protect rights/safety.

---

## 5. Data Retention

| Data Type | Retention Period |
|-----------|------------------|
| Account & profile | Until you delete your account |
| Journals & memories | Until you or journal creator deletes them |
| Chat messages | Until journal is deleted |
| Push notification tokens | Until you log out or uninstall |
| Crash logs / analytics | 90 days (Firebase default) |
| Authentication logs | 90 days (Supabase default) |

**Deletion:** You can delete your account in-app → all your data is permanently removed within 30 days.

---

## 6. Your Rights

Depending on your jurisdiction, you may have the right to:

- **Access** — Request a copy of your data
- **Rectify** — Correct inaccurate data
- **Erase** — Delete your account and data
- **Restrict** — Limit processing
- **Portability** — Receive your data in a portable format
- **Object** — Opt out of certain processing (e.g., analytics)

**To exercise these rights:** Use the in-app account deletion, or contact us at the email below.

---

## 7. Children's Privacy

ReLog2 is not intended for children under **13** (or 16 in EU/UK). We do not knowingly collect data from children. If you believe a child has provided data, contact us immediately.

---

## 8. International Transfers

Your data may be processed in the **United States** (Supabase, Firebase) and **EU/Global** (Cloudflare R2). Transfers rely on:
- Standard Contractual Clauses (SCCs)
- Adequacy decisions where applicable
- Processor commitments

---

## 9. Security

- **In transit:** TLS 1.2+ for all API calls
- **At rest:** AES-256 encryption (Supabase, Cloudflare R2)
- **Auth:** Industry-standard OAuth 2.0 / OIDC via Supabase
- **Media:** Private R2 buckets, signed URLs with short expiry

---

## 10. Changes to This Policy

We may update this policy. Material changes will be notified in-app. Continued use after changes constitutes acceptance.

---

## 11. Contact Us

**Data Controller:** ReLog2 Team  
**Email:** legal@relog2.app  
**Address:** [Your Business Address]

For data protection inquiries, include "Privacy" in the subject line.