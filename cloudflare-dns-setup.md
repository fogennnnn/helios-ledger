# Cloudflare DNS Setup for ai.oooooooooo.se
# ════════════════════════════════════════════

## Goal
Point `ai.oooooooooo.se` → GitHub Pages at `fogennnnn.github.io`
with HTTPS enforced via Cloudflare.

---

## Step 1 — Add oooooooooo.se to Cloudflare (if not already there)

1. Go to https://dash.cloudflare.com → **Add a Site**
2. Enter `oooooooooo.se` → Free plan is fine
3. Cloudflare will detect existing DNS records — keep them
4. Update your registrar's nameservers to the two Cloudflare ones shown

---

## Step 2 — Add DNS Records

In Cloudflare dashboard → **oooooooooo.se** → **DNS** → **Records**

Add these records exactly:

### CNAME record (for the subdomain `ai`)

| Type  | Name | Target                    | Proxy status | TTL  |
|-------|------|---------------------------|--------------|------|
| CNAME | ai   | fogennnnn.github.io       | ☁️ Proxied   | Auto |

> **Important:** Set it to **Proxied** (orange cloud) — this gives you:
> - Free HTTPS via Cloudflare's SSL cert
> - DDoS protection
> - CDN caching of your landing page
> - Hides your origin server IP

---

## Step 3 — Cloudflare SSL/TLS Settings

Go to **oooooooooo.se** → **SSL/TLS** in Cloudflare:

- Set encryption mode to **Full** (not Full Strict, GitHub Pages uses a shared cert)

Go to **SSL/TLS** → **Edge Certificates**:

- ✅ Always Use HTTPS → **On**
- ✅ Automatic HTTPS Rewrites → **On**
- ✅ HTTP/2 → **On** (usually default)

---

## Step 4 — Page Rules (optional but good for SEO)

Go to **Rules** → **Page Rules** → **Create Page Rule**

Rule 1 — Force HTTPS:
```
URL:      http://ai.oooooooooo.se/*
Setting:  Always Use HTTPS
```

Rule 2 — Cache landing page aggressively:
```
URL:      ai.oooooooooo.se/
Setting:  Cache Level = Cache Everything
          Edge Cache TTL = 1 month
```

---

## Step 5 — Verify

After DNS propagates (usually 1–5 min with Cloudflare):

```bash
# Should resolve to Cloudflare IPs
dig ai.oooooooooo.se CNAME

# Should return 200
curl -I https://ai.oooooooooo.se/

# Check cert
curl -vI https://ai.oooooooooo.se/ 2>&1 | grep "issuer\|subject"
```

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| 404 on GitHub Pages | Wait for Pages to build — check Actions tab |
| SSL cert error | Switch SSL mode to Full (not Strict) |
| Domain not resolving | Check nameservers at registrar point to Cloudflare |
| Still serving old content | Purge Cloudflare cache: Caching → Purge Everything |

---

## GitHub Pages also needs to know the custom domain

The `CNAME` file in `docs/site/CNAME` already contains `ai.oooooooooo.se` — 
this is what tells GitHub Pages to accept requests for that domain.

You can also set it in: **GitHub repo → Settings → Pages → Custom domain**
Then tick **Enforce HTTPS** (appears once DNS is verified).
