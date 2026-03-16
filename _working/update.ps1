# update.ps1 - Fix blank sections bug
# Run from C:\Users\fogen\HELIOS

Write-Host "Updating index.html..." -ForegroundColor Cyan

Set-Content -Path docs\index.html -Value @'
<!DOCTYPE html>
<html lang="en" prefix="og: https://ogp.me/ns#">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />

  <!-- ═══════════════════════════════════════════
       PRIMARY SEO META TAGS
  ═══════════════════════════════════════════ -->
  <title>Helios Ledger — AI Provenance & Content Authenticity Platform</title>
  <meta name="description" content="Helios Ledger is an open-source AI provenance platform. Cryptographically verify the origin, integrity, and authenticity of AI-generated content using Ed25519 signatures and Merkle-tree attestations." />
  <meta name="keywords" content="AI provenance, content authenticity, AI content verification, cryptographic provenance, Ed25519, Merkle tree, blockchain provenance, AI watermarking, digital content integrity, AI transparency, content origin tracking, AI audit trail, provenance ledger, open source AI tools, AI authenticity API" />
  <meta name="author" content="Helios Ledger" />
  <meta name="robots" content="index, follow, max-image-preview:large, max-snippet:-1, max-video-preview:-1" />
  <meta name="googlebot" content="index, follow" />
  <link rel="canonical" href="https://ai.oooooooooo.se/" />

  <!-- ═══════════════════════════════════════════
       OPEN GRAPH (Facebook, LinkedIn, Discord)
  ═══════════════════════════════════════════ -->
  <meta property="og:type" content="website" />
  <meta property="og:site_name" content="Helios Ledger" />
  <meta property="og:title" content="Helios Ledger — AI Provenance & Content Authenticity Platform" />
  <meta property="og:description" content="Cryptographically verify the origin and integrity of AI-generated content. Open-source provenance ledger powered by Ed25519 and Merkle-tree attestations." />
  <meta property="og:url" content="https://ai.oooooooooo.se/" />
  <meta property="og:image" content="https://ai.oooooooooo.se/og-image.png" />
  <meta property="og:image:width" content="1200" />
  <meta property="og:image:height" content="630" />
  <meta property="og:image:alt" content="Helios Ledger — AI provenance platform" />
  <meta property="og:locale" content="en_US" />

  <!-- ═══════════════════════════════════════════
       TWITTER / X CARD
  ═══════════════════════════════════════════ -->
  <meta name="twitter:card" content="summary_large_image" />
  <meta name="twitter:site" content="@heliosledger" />
  <meta name="twitter:creator" content="@heliosledger" />
  <meta name="twitter:title" content="Helios Ledger — AI Provenance & Content Authenticity" />
  <meta name="twitter:description" content="Open-source cryptographic provenance for AI-generated content. Ed25519 signatures + Merkle attestations + REST API." />
  <meta name="twitter:image" content="https://ai.oooooooooo.se/og-image.png" />

  <!-- ═══════════════════════════════════════════
       STRUCTURED DATA — SoftwareApplication
  ═══════════════════════════════════════════ -->
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "SoftwareApplication",
    "name": "Helios Ledger",
    "applicationCategory": "DeveloperApplication",
    "operatingSystem": "Linux, macOS, Windows",
    "url": "https://ai.oooooooooo.se/",
    "description": "Helios Ledger is an open-source AI provenance and content authenticity platform. It uses Ed25519 digital signatures and Merkle-tree attestations to create tamper-proof audit trails for AI-generated content.",
    "softwareVersion": "1.0.0",
    "license": "https://opensource.org/licenses/MIT",
    "codeRepository": "https://github.com/heliosledger/helios-ledger",
    "programmingLanguage": ["Python", "JavaScript"],
    "keywords": "AI provenance, content authenticity, cryptographic verification, Merkle tree",
    "offers": {
      "@type": "Offer",
      "price": "0",
      "priceCurrency": "USD"
    },
    "author": {
      "@type": "Organization",
      "name": "Helios Ledger",
      "url": "https://ai.oooooooooo.se/"
    },
    "featureList": [
      "Ed25519 cryptographic signing",
      "Merkle tree attestations",
      "REST API",
      "Tamper-proof audit logs",
      "Reward system",
      "Multi-node consensus"
    ]
  }
  </script>

  <!-- ═══════════════════════════════════════════
       STRUCTURED DATA — FAQPage (boosts rich snippets)
  ═══════════════════════════════════════════ -->
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "FAQPage",
    "mainEntity": [
      {
        "@type": "Question",
        "name": "What is AI provenance?",
        "acceptedAnswer": {
          "@type": "Answer",
          "text": "AI provenance is the ability to cryptographically prove the origin, creation context, and integrity of AI-generated content. Helios Ledger records a tamper-proof Ed25519-signed entry for each piece of content, creating an immutable audit trail."
        }
      },
      {
        "@type": "Question",
        "name": "How does Helios Ledger verify AI content authenticity?",
        "acceptedAnswer": {
          "@type": "Answer",
          "text": "Helios Ledger hashes your content and signs the hash using Ed25519 cryptography. The signature and metadata are stored in a Merkle tree, so any tampering with the record is immediately detectable."
        }
      },
      {
        "@type": "Question",
        "name": "Is Helios Ledger free and open source?",
        "acceptedAnswer": {
          "@type": "Answer",
          "text": "Yes. Helios Ledger is MIT-licensed and freely available on GitHub. You can self-host it or use the public API at ai.oooooooooo.se."
        }
      },
      {
        "@type": "Question",
        "name": "What industries benefit from AI content provenance?",
        "acceptedAnswer": {
          "@type": "Answer",
          "text": "Journalism, legal, healthcare, finance, academia, creative industries, and any organization that needs to demonstrate that AI-generated content has not been altered since creation."
        }
      },
      {
        "@type": "Question",
        "name": "Does Helios Ledger work with any AI model?",
        "acceptedAnswer": {
          "@type": "Answer",
          "text": "Yes. Helios Ledger is model-agnostic. It works with output from any AI model including GPT-4, Claude, Gemini, Llama, Mistral, and custom fine-tuned models."
        }
      }
    ]
  }
  </script>

  <!-- ═══════════════════════════════════════════
       STRUCTURED DATA — BreadcrumbList
  ═══════════════════════════════════════════ -->
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    "itemListElement": [
      { "@type": "ListItem", "position": 1, "name": "Home", "item": "https://ai.oooooooooo.se/" },
      { "@type": "ListItem", "position": 2, "name": "Docs",  "item": "https://ai.oooooooooo.se/docs/" },
      { "@type": "ListItem", "position": 3, "name": "API",   "item": "https://ai.oooooooooo.se/api/" }
    ]
  }
  </script>

  <!-- ═══════════════════════════════════════════
       PERFORMANCE & PWA HINTS
  ═══════════════════════════════════════════ -->
  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
  <link rel="dns-prefetch" href="https://github.com" />
  <meta name="theme-color" content="#0a0604" />
  <link rel="sitemap" type="application/xml" href="/sitemap.xml" />

  <!-- Fonts: Cinzel (solar/classical display) + Lora (refined body) -->
  <link href="https://fonts.googleapis.com/css2?family=Cinzel:wght@400;600;900&family=Lora:ital,wght@0,400;0,500;1,400&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet" />

  <style>
    /* ════════════════════════════════════════
       DESIGN SYSTEM — Solar / Heliocentric
       Dark cosmic canvas · Gold-fire accents
    ════════════════════════════════════════ */
    :root {
      --bg:        #07050a;
      --bg2:       #0f0b14;
      --bg3:       #17111f;
      --gold:      #f0aa3a;
      --gold-dim:  #b87825;
      --gold-pale: #fde8b0;
      --corona:    #ff6b1a;
      --white:     #f5f0e8;
      --muted:     #8a7d6a;
      --border:    rgba(240,170,58,0.18);
      --glow:      0 0 40px rgba(240,170,58,0.3);
      --ff-head:   'Cinzel', serif;
      --ff-body:   'Lora', serif;
      --ff-code:   'JetBrains Mono', monospace;
    }

    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    html { scroll-behavior: smooth; }

    body {
      background: var(--bg);
      color: var(--white);
      font-family: var(--ff-body);
      font-size: 17px;
      line-height: 1.75;
      overflow-x: hidden;
    }

    /* ── Starfield background ── */
    body::before {
      content: '';
      position: fixed; inset: 0; z-index: 0;
      background-image:
        radial-gradient(circle at 20% 30%, rgba(240,170,58,0.06) 0%, transparent 50%),
        radial-gradient(circle at 80% 70%, rgba(255,107,26,0.04) 0%, transparent 50%),
        url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='800' height='800'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.65' numOctaves='3' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='800' height='800' filter='url(%23n)' opacity='0.025'/%3E%3C/svg%3E");
      pointer-events: none;
    }

    /* ── Coronasphere decoration ── */
    .corona-orb {
      position: absolute;
      border-radius: 50%;
      pointer-events: none;
    }

    /* ── Layout ── */
    .container { max-width: 1120px; margin: 0 auto; padding: 0 2rem; position: relative; z-index: 1; }

    /* ════════════════════
       NAV
    ════════════════════ */
    nav {
      position: fixed; top: 0; left: 0; right: 0; z-index: 100;
      backdrop-filter: blur(16px) saturate(180%);
      background: rgba(7,5,10,0.85);
      border-bottom: 1px solid var(--border);
    }
    .nav-inner {
      max-width: 1120px; margin: 0 auto; padding: 0 2rem;
      display: flex; align-items: center; justify-content: space-between;
      height: 64px;
    }
    .nav-logo {
      font-family: var(--ff-head);
      font-size: 1.15rem; font-weight: 900;
      letter-spacing: 0.1em; text-transform: uppercase;
      color: var(--gold);
      text-decoration: none;
    }
    .nav-logo span { color: var(--corona); }
    .nav-links { display: flex; gap: 2rem; list-style: none; }
    .nav-links a {
      color: var(--muted); text-decoration: none;
      font-size: 0.85rem; font-family: var(--ff-head); letter-spacing: 0.08em;
      text-transform: uppercase; transition: color 0.2s;
    }
    .nav-links a:hover { color: var(--gold); }
    .nav-cta {
      background: linear-gradient(135deg, var(--gold), var(--corona));
      color: var(--bg) !important; padding: 0.45rem 1.1rem;
      border-radius: 4px; font-weight: 600 !important;
    }
    .nav-cta:hover { opacity: 0.9; color: var(--bg) !important; }

    /* ════════════════════
       HERO
    ════════════════════ */
    .hero {
      min-height: 100vh;
      display: flex; flex-direction: column;
      justify-content: center; align-items: center;
      text-align: center; padding: 8rem 2rem 6rem;
      position: relative; overflow: hidden;
    }
    .hero-sun {
      position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%);
      width: 600px; height: 600px; border-radius: 50%;
      background: radial-gradient(ellipse at center, rgba(240,170,58,0.12) 0%, rgba(255,107,26,0.06) 40%, transparent 70%);
      animation: pulse 8s ease-in-out infinite;
      pointer-events: none;
    }
    @keyframes pulse {
      0%, 100% { transform: translate(-50%,-50%) scale(1); opacity: 0.7; }
      50%       { transform: translate(-50%,-50%) scale(1.15); opacity: 1; }
    }
    .hero-eyebrow {
      font-family: var(--ff-head); font-size: 0.75rem; letter-spacing: 0.25em;
      text-transform: uppercase; color: var(--gold);
      border: 1px solid var(--border); padding: 0.35rem 1rem;
      border-radius: 2px; margin-bottom: 2rem;
      animation: fadein 0.8s ease both;
    }
    @keyframes fadein { from { opacity: 0; transform: translateY(12px); } to { opacity: 1; transform: none; } }

    h1 {
      font-family: var(--ff-head);
      font-size: clamp(2.5rem, 7vw, 5.5rem);
      font-weight: 900; line-height: 1.08;
      letter-spacing: -0.01em;
      background: linear-gradient(160deg, var(--gold-pale) 0%, var(--gold) 45%, var(--corona) 100%);
      -webkit-background-clip: text; -webkit-text-fill-color: transparent;
      background-clip: text;
      margin-bottom: 1.5rem;
      animation: fadein 0.9s 0.1s ease both;
    }
    .hero-sub {
      font-size: 1.25rem; color: var(--muted); max-width: 620px;
      margin: 0 auto 3rem; font-style: italic;
      animation: fadein 1s 0.2s ease both;
    }
    .hero-buttons {
      display: flex; gap: 1rem; flex-wrap: wrap; justify-content: center;
      animation: fadein 1s 0.35s ease both;
    }
    .btn-primary {
      display: inline-flex; align-items: center; gap: 0.5rem;
      background: linear-gradient(135deg, var(--gold), var(--corona));
      color: #0a0604; padding: 0.9rem 2rem;
      border-radius: 4px; font-family: var(--ff-head);
      font-size: 0.85rem; font-weight: 600; letter-spacing: 0.1em;
      text-transform: uppercase; text-decoration: none;
      box-shadow: 0 4px 24px rgba(240,170,58,0.3);
      transition: box-shadow 0.2s, transform 0.2s;
    }
    .btn-primary:hover { box-shadow: 0 8px 40px rgba(240,170,58,0.5); transform: translateY(-2px); }
    .btn-ghost {
      display: inline-flex; align-items: center; gap: 0.5rem;
      border: 1px solid var(--border); color: var(--gold-pale);
      padding: 0.9rem 2rem; border-radius: 4px;
      font-family: var(--ff-head); font-size: 0.85rem;
      font-weight: 400; letter-spacing: 0.1em;
      text-transform: uppercase; text-decoration: none;
      transition: border-color 0.2s, color 0.2s, background 0.2s;
    }
    .btn-ghost:hover { border-color: var(--gold); background: rgba(240,170,58,0.06); color: var(--gold); }

    .hero-stats {
      display: flex; gap: 3rem; flex-wrap: wrap; justify-content: center;
      margin-top: 5rem; padding-top: 3rem;
      border-top: 1px solid var(--border);
      animation: fadein 1s 0.5s ease both;
    }
    .stat { text-align: center; }
    .stat-num {
      font-family: var(--ff-head); font-size: 2rem; font-weight: 900;
      color: var(--gold); display: block;
    }
    .stat-label { font-size: 0.8rem; color: var(--muted); letter-spacing: 0.1em; text-transform: uppercase; font-family: var(--ff-head); }

    /* ════════════════════
       SECTION CHROME
    ════════════════════ */
    section { padding: 7rem 0; position: relative; z-index: 1; }
    .section-tag {
      font-family: var(--ff-head); font-size: 0.7rem;
      letter-spacing: 0.3em; text-transform: uppercase;
      color: var(--gold); margin-bottom: 0.75rem; display: block;
    }
    h2 {
      font-family: var(--ff-head); font-size: clamp(1.8rem, 4vw, 3rem);
      font-weight: 900; line-height: 1.15;
      color: var(--white); margin-bottom: 1.5rem;
    }
    h2 em { font-style: normal; color: var(--gold); }
    .section-lead { font-size: 1.1rem; color: var(--muted); max-width: 580px; }

    /* ════════════════════
       HOW IT WORKS
    ════════════════════ */
    .steps-grid {
      display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
      gap: 2px; margin-top: 4rem;
      border: 1px solid var(--border); border-radius: 8px; overflow: hidden;
    }
    .step {
      background: var(--bg2); padding: 2.5rem 2rem;
      border-right: 1px solid var(--border);
      position: relative; transition: background 0.3s;
    }
    .step:last-child { border-right: none; }
    .step:hover { background: var(--bg3); }
    .step-num {
      font-family: var(--ff-head); font-size: 3rem; font-weight: 900;
      color: var(--border); line-height: 1; margin-bottom: 1.25rem;
      display: block;
    }
    .step h3 {
      font-family: var(--ff-head); font-size: 1rem;
      color: var(--gold-pale); margin-bottom: 0.75rem; letter-spacing: 0.05em;
    }
    .step p { font-size: 0.9rem; color: var(--muted); line-height: 1.65; }

    /* ════════════════════
       FEATURES BENTO
    ════════════════════ */
    .bento {
      display: grid;
      grid-template-columns: 1fr 1fr 1fr;
      grid-template-rows: auto auto;
      gap: 16px; margin-top: 4rem;
    }
    .bento-card {
      background: var(--bg2); border: 1px solid var(--border);
      border-radius: 8px; padding: 2rem;
      transition: border-color 0.3s, transform 0.3s;
      position: relative; overflow: hidden;
    }
    .bento-card::before {
      content: ''; position: absolute; top: 0; left: 0; right: 0; height: 2px;
      background: linear-gradient(90deg, transparent, var(--gold), transparent);
      opacity: 0; transition: opacity 0.3s;
    }
    .bento-card:hover { border-color: var(--gold-dim); transform: translateY(-4px); }
    .bento-card:hover::before { opacity: 1; }
    .bento-card.wide { grid-column: span 2; }
    .bento-card.tall { grid-row: span 2; }
    .bento-icon { font-size: 2rem; margin-bottom: 1rem; display: block; }
    .bento-card h3 {
      font-family: var(--ff-head); font-size: 0.95rem;
      color: var(--gold-pale); margin-bottom: 0.6rem; letter-spacing: 0.05em;
    }
    .bento-card p { font-size: 0.88rem; color: var(--muted); line-height: 1.65; }
    .code-snippet {
      background: var(--bg); border: 1px solid rgba(240,170,58,0.12);
      border-radius: 6px; padding: 1.25rem;
      font-family: var(--ff-code); font-size: 0.78rem;
      color: var(--gold-pale); margin-top: 1rem;
      overflow-x: auto; line-height: 1.8;
    }
    .code-snippet .k { color: var(--corona); }
    .code-snippet .s { color: #7ec8a4; }
    .code-snippet .c { color: var(--muted); }

    /* ════════════════════
       USE CASES
    ════════════════════ */
    .usecases {
      display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 1rem; margin-top: 3rem;
    }
    .usecase {
      background: var(--bg2); border: 1px solid var(--border);
      border-radius: 8px; padding: 1.5rem;
      display: flex; flex-direction: column; gap: 0.5rem;
    }
    .usecase-icon { font-size: 1.5rem; }
    .usecase h3 {
      font-family: var(--ff-head); font-size: 0.85rem;
      color: var(--white); letter-spacing: 0.05em;
    }
    .usecase p { font-size: 0.82rem; color: var(--muted); }

    /* ════════════════════
       FAQ
    ════════════════════ */
    .faq-grid {
      display: grid; grid-template-columns: 1fr 1fr;
      gap: 1.5rem; margin-top: 3rem;
    }
    .faq-item {
      background: var(--bg2); border: 1px solid var(--border);
      border-radius: 8px; padding: 1.75rem;
    }
    .faq-item h3 {
      font-family: var(--ff-head); font-size: 0.9rem;
      color: var(--gold-pale); margin-bottom: 0.75rem;
      letter-spacing: 0.04em;
    }
    .faq-item p { font-size: 0.88rem; color: var(--muted); line-height: 1.7; }

    /* ════════════════════
       CTA BANNER
    ════════════════════ */
    .cta-section {
      background: linear-gradient(135deg, var(--bg2) 0%, var(--bg3) 100%);
      border: 1px solid var(--border); border-radius: 12px;
      padding: 5rem 3rem; text-align: center;
      position: relative; overflow: hidden;
    }
    .cta-section::before {
      content: '';
      position: absolute; top: -80px; left: 50%; transform: translateX(-50%);
      width: 400px; height: 160px; border-radius: 50%;
      background: radial-gradient(ellipse, rgba(240,170,58,0.15), transparent 70%);
      pointer-events: none;
    }
    .cta-section h2 { margin-bottom: 1rem; }
    .cta-section p { color: var(--muted); max-width: 520px; margin: 0 auto 2.5rem; }

    /* ════════════════════
       FOOTER
    ════════════════════ */
    footer {
      border-top: 1px solid var(--border); padding: 3rem 0;
      position: relative; z-index: 1;
    }
    .footer-inner {
      max-width: 1120px; margin: 0 auto; padding: 0 2rem;
      display: flex; justify-content: space-between; align-items: center;
      flex-wrap: wrap; gap: 1rem;
    }
    .footer-logo {
      font-family: var(--ff-head); color: var(--gold-dim);
      font-size: 0.9rem; letter-spacing: 0.1em; text-transform: uppercase;
      text-decoration: none;
    }
    .footer-links { display: flex; gap: 2rem; list-style: none; flex-wrap: wrap; }
    .footer-links a { color: var(--muted); text-decoration: none; font-size: 0.82rem; transition: color 0.2s; }
    .footer-links a:hover { color: var(--gold); }
    .footer-copy { color: var(--muted); font-size: 0.78rem; }

    /* ════════════════════
       DIVIDERS
    ════════════════════ */
    .divider {
      height: 1px;
      background: linear-gradient(90deg, transparent, var(--border), transparent);
      margin: 0 2rem;
    }

    /* ════════════════════
       RESPONSIVE
    ════════════════════ */
    /* ════════════════════
       SCROLL ANIMATIONS — content visible by default, animates when JS loads
    ════════════════════ */
    body.js-loaded .animate-on-scroll {
      opacity: 0;
      transform: translateY(20px);
      transition: opacity 0.6s ease, transform 0.6s ease;
    }
    body.js-loaded .animate-on-scroll.visible {
      opacity: 1;
      transform: translateY(0);
    }

    @media (max-width: 768px) {
      .bento { grid-template-columns: 1fr; }
      .bento-card.wide { grid-column: span 1; }
      .faq-grid { grid-template-columns: 1fr; }
      .nav-links { display: none; }
      .hero-stats { gap: 2rem; }
    }
  </style>
</head>

<body>

  <!-- ╔══════════════════════╗
       ║  NAV                ║
       ╚══════════════════════╝ -->
  <nav aria-label="Main navigation">
    <div class="nav-inner">
      <a href="/" class="nav-logo" aria-label="Helios Ledger home">HELIOS<span>◉</span></a>
      <ul class="nav-links" role="list">
        <li><a href="#how-it-works">How It Works</a></li>
        <li><a href="#features">Features</a></li>
        <li><a href="#use-cases">Use Cases</a></li>
        <li><a href="#faq">FAQ</a></li>
        <li><a href="https://github.com/heliosledger/helios-ledger" class="nav-cta" rel="noopener">GitHub ↗</a></li>
      </ul>
    </div>
  </nav>

  <!-- ╔══════════════════════╗
       ║  HERO               ║
       ╚══════════════════════╝ -->
  <header class="hero" role="banner">
    <div class="hero-sun" aria-hidden="true"></div>
    <div class="container">
      <p class="hero-eyebrow">Open-Source AI Provenance Platform</p>
      <h1>Know Where Your<br/>AI Content Came From</h1>
      <p class="hero-sub">
        Helios Ledger cryptographically seals the origin and integrity of AI-generated content — using Ed25519 signatures, Merkle-tree attestations, and a tamper-proof audit ledger.
      </p>
      <div class="hero-buttons">
        <a href="https://github.com/heliosledger/helios-ledger" class="btn-primary" rel="noopener noreferrer" aria-label="View Helios Ledger on GitHub">
          <svg width="16" height="16" fill="currentColor" viewBox="0 0 16 16" aria-hidden="true"><path d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.012 8.012 0 0 0 16 8c0-4.42-3.58-8-8-8z"/></svg>
          View on GitHub
        </a>
        <a href="#how-it-works" class="btn-ghost">See How It Works ↓</a>
      </div>
      <div class="hero-stats" aria-label="Project statistics">
        <div class="stat">
          <span class="stat-num">Ed25519</span>
          <span class="stat-label">Cryptography</span>
        </div>
        <div class="stat">
          <span class="stat-num">Merkle</span>
          <span class="stat-label">Attestations</span>
        </div>
        <div class="stat">
          <span class="stat-num">REST</span>
          <span class="stat-label">API</span>
        </div>
        <div class="stat">
          <span class="stat-num">MIT</span>
          <span class="stat-label">Open Source</span>
        </div>
        <div class="stat">
          <span class="stat-num">44</span>
          <span class="stat-label">Passing Tests</span>
        </div>
      </div>
    </div>
  </header>

  <div class="divider" role="separator"></div>

  <!-- ╔══════════════════════╗
       ║  HOW IT WORKS       ║
       ╚══════════════════════╝ -->
  <section id="how-it-works" aria-labelledby="hiw-heading">
    <div class="container">
      <span class="section-tag">The Process</span>
      <h2 id="hiw-heading">Provenance in <em>Four Steps</em></h2>
      <p class="section-lead">From raw AI output to cryptographically sealed, independently verifiable record — in under a second.</p>
      <div class="steps-grid" role="list">
        <article class="step animate-on-scroll" role="listitem">
          <span class="step-num">01</span>
          <h3>Submit Content</h3>
          <p>Send any AI-generated text, image hash, or code snippet to the Helios API. Metadata — model name, timestamp, author — is attached automatically.</p>
        </article>
        <article class="step animate-on-scroll" role="listitem">
          <span class="step-num">02</span>
          <h3>Hash &amp; Sign</h3>
          <p>Helios computes a SHA-256 content hash and signs it with Ed25519. The private key never leaves the signing node; only the public key is distributed.</p>
        </article>
        <article class="step animate-on-scroll" role="listitem">
          <span class="step-num">03</span>
          <h3>Merkle Inclusion</h3>
          <p>The signed hash is inserted into the append-only Merkle tree. Each new leaf produces an updated root hash — any tampering with historical entries breaks the root.</p>
        </article>
        <article class="step animate-on-scroll" role="listitem">
          <span class="step-num">04</span>
          <h3>Verify Anywhere</h3>
          <p>Anyone can independently verify a provenance record using the public key and Merkle proof — no trust in Helios required. Pure cryptographic truth.</p>
        </article>
      </div>
    </div>
  </section>

  <div class="divider" role="separator"></div>

  <!-- ╔══════════════════════╗
       ║  FEATURES BENTO     ║
       ╚══════════════════════╝ -->
  <section id="features" aria-labelledby="features-heading">
    <div class="container">
      <span class="section-tag">Capabilities</span>
      <h2 id="features-heading">Everything You Need for <em>AI Trust Infrastructure</em></h2>
      <div class="bento" role="list">

        <article class="bento-card wide animate-on-scroll" role="listitem" aria-labelledby="f-api">
          <span class="bento-icon" aria-hidden="true">⚡</span>
          <h3 id="f-api">REST API — Zero Friction Integration</h3>
          <p>Submit, verify, and audit provenance records from any language or platform. JSON in, JSON out.</p>
          <div class="code-snippet" role="img" aria-label="Code example: submit content to Helios API">
<span class="c"># Submit content for provenance</span>
curl -X POST https://ai.oooooooooo.se/api/records \
  -H <span class="s">"Authorization: Bearer $TOKEN"</span> \
  -d <span class="s">'{"content": "AI output here", "model": "claude-sonnet-4"}'</span>

<span class="c"># Verify a record</span>
curl https://ai.oooooooooo.se/api/records/<span class="k">{id}</span>/verify
          </div>
        </article>

        <article class="bento-card animate-on-scroll" role="listitem" aria-labelledby="f-sign">
          <span class="bento-icon" aria-hidden="true">🔑</span>
          <h3 id="f-sign">Ed25519 Signatures</h3>
          <p>Modern, fast, and battle-tested elliptic-curve cryptography. Signatures are 64 bytes and verify in microseconds.</p>
        </article>

        <article class="bento-card animate-on-scroll" role="listitem" aria-labelledby="f-merkle">
          <span class="bento-icon" aria-hidden="true">🌳</span>
          <h3 id="f-merkle">Merkle-Tree Attestations</h3>
          <p>Append-only Merkle structure. Historical records are mathematically immutable — no database admin can alter them silently.</p>
        </article>

        <article class="bento-card animate-on-scroll" role="listitem" aria-labelledby="f-reward">
          <span class="bento-icon" aria-hidden="true">🏅</span>
          <h3 id="f-reward">Reward System</h3>
          <p>Incentivize contributors who submit provenance records. Configurable reward logic with per-account balance tracking.</p>
        </article>

        <article class="bento-card animate-on-scroll" role="listitem" aria-labelledby="f-consensus">
          <span class="bento-icon" aria-hidden="true">🤝</span>
          <h3 id="f-consensus">Multi-Node Consensus</h3>
          <p>Run a network of Helios nodes. Consensus ensures the ledger state is agreed on before new records are committed.</p>
        </article>

        <article class="bento-card animate-on-scroll" role="listitem" aria-labelledby="f-oss">
          <span class="bento-icon" aria-hidden="true">📖</span>
          <h3 id="f-oss">Fully Open Source</h3>
          <p>MIT licensed. Audit every line. Self-host on your own infrastructure or contribute to the public instance.</p>
        </article>

      </div>
    </div>
  </section>

  <div class="divider" role="separator"></div>

  <!-- ╔══════════════════════╗
       ║  USE CASES          ║
       ╚══════════════════════╝ -->
  <section id="use-cases" aria-labelledby="uc-heading">
    <div class="container">
      <span class="section-tag">Applications</span>
      <h2 id="uc-heading">Built for Every Industry That Touches <em>AI Content</em></h2>
      <p class="section-lead">Wherever accountability for AI-generated material matters, Helios Ledger provides the cryptographic layer of truth.</p>
      <div class="usecases" role="list">
        <article class="usecase animate-on-scroll" role="listitem">
          <span class="usecase-icon" aria-hidden="true">📰</span>
          <h3>Journalism</h3>
          <p>Prove AI-assisted articles weren't altered after publication.</p>
        </article>
        <article class="usecase animate-on-scroll" role="listitem">
          <span class="usecase-icon" aria-hidden="true">⚖️</span>
          <h3>Legal</h3>
          <p>Provide court-admissible provenance chains for AI-generated evidence.</p>
        </article>
        <article class="usecase animate-on-scroll" role="listitem">
          <span class="usecase-icon" aria-hidden="true">🏥</span>
          <h3>Healthcare</h3>
          <p>Audit AI diagnostic outputs against their original generation context.</p>
        </article>
        <article class="usecase animate-on-scroll" role="listitem">
          <span class="usecase-icon" aria-hidden="true">🏦</span>
          <h3>Finance</h3>
          <p>Regulatory-ready audit trails for AI-generated reports and advisories.</p>
        </article>
        <article class="usecase animate-on-scroll" role="listitem">
          <span class="usecase-icon" aria-hidden="true">🎓</span>
          <h3>Academia</h3>
          <p>Verify AI disclosure in research papers with immutable provenance.</p>
        </article>
        <article class="usecase animate-on-scroll" role="listitem">
          <span class="usecase-icon" aria-hidden="true">🎨</span>
          <h3>Creative</h3>
          <p>Certify AI co-creation credit for artists and content studios.</p>
        </article>
      </div>
    </div>
  </section>

  <div class="divider" role="separator"></div>

  <!-- ╔══════════════════════╗
       ║  FAQ                ║
       ╚══════════════════════╝ -->
  <section id="faq" aria-labelledby="faq-heading">
    <div class="container">
      <span class="section-tag">Questions</span>
      <h2 id="faq-heading"><em>Frequently</em> Asked Questions</h2>
      <div class="faq-grid" role="list">
        <article class="faq-item animate-on-scroll" role="listitem">
          <h3>What is AI provenance?</h3>
          <p>AI provenance is the ability to cryptographically prove the origin, creation context, and post-creation integrity of AI-generated content. Helios Ledger records a tamper-proof signed entry for each piece of content, creating an immutable audit trail.</p>
        </article>
        <article class="faq-item animate-on-scroll" role="listitem">
          <h3>How does content verification work?</h3>
          <p>Helios hashes your content and signs the hash using Ed25519. The signature and metadata are stored in a Merkle tree, so any tampering is immediately detectable by anyone holding the public key.</p>
        </article>
        <article class="faq-item animate-on-scroll" role="listitem">
          <h3>Is Helios Ledger free and open source?</h3>
          <p>Yes. Helios Ledger is MIT-licensed and freely available on GitHub. You can self-host it on your own infrastructure or use the public instance at ai.oooooooooo.se.</p>
        </article>
        <article class="faq-item animate-on-scroll" role="listitem">
          <h3>Which AI models are supported?</h3>
          <p>All of them. Helios Ledger is model-agnostic — it works with output from GPT-4, Claude, Gemini, Llama, Mistral, or any custom model. Only the content hash matters, not how it was produced.</p>
        </article>
        <article class="faq-item animate-on-scroll" role="listitem">
          <h3>Can I run my own Helios node?</h3>
          <p>Absolutely. Clone the repo, configure your environment, and start a local or networked Helios node in minutes. Multi-node consensus lets you run a private provenance network within your organization.</p>
        </article>
        <article class="faq-item animate-on-scroll" role="listitem">
          <h3>Does Helios store the actual content?</h3>
          <p>No. Helios only stores cryptographic hashes and metadata — never the raw content itself. Your data stays with you; Helios only records proof of its existence and integrity.</p>
        </article>
      </div>
    </div>
  </section>

  <div class="divider" role="separator"></div>

  <!-- ╔══════════════════════╗
       ║  CTA                ║
       ╚══════════════════════╝ -->
  <section aria-labelledby="cta-heading">
    <div class="container">
      <div class="cta-section">
        <span class="section-tag">Get Started</span>
        <h2 id="cta-heading">Bring <em>Cryptographic Trust</em> to Your AI Stack</h2>
        <p>Join developers and organizations using Helios Ledger to prove the provenance of AI-generated content — no trust required, just math.</p>
        <div class="hero-buttons">
          <a href="https://github.com/heliosledger/helios-ledger" class="btn-primary" rel="noopener noreferrer">Star on GitHub</a>
          <a href="https://github.com/heliosledger/helios-ledger/blob/main/README.md" class="btn-ghost" rel="noopener noreferrer">Read the Docs</a>
        </div>
      </div>
    </div>
  </section>

  <!-- ╔══════════════════════╗
       ║  FOOTER             ║
       ╚══════════════════════╝ -->
  <footer role="contentinfo">
    <div class="footer-inner">
      <a href="/" class="footer-logo" aria-label="Helios Ledger home">Helios Ledger</a>
      <nav aria-label="Footer navigation">
        <ul class="footer-links" role="list">
          <li><a href="https://github.com/heliosledger/helios-ledger" rel="noopener noreferrer">GitHub</a></li>
          <li><a href="https://github.com/heliosledger/helios-ledger/blob/main/README.md" rel="noopener noreferrer">Docs</a></li>
          <li><a href="https://github.com/heliosledger/helios-ledger/issues" rel="noopener noreferrer">Issues</a></li>
          <li><a href="https://github.com/heliosledger/helios-ledger/blob/main/LICENSE" rel="noopener noreferrer">MIT License</a></li>
        </ul>
      </nav>
      <p class="footer-copy">© <span id="year"></span> Helios Ledger · MIT License · Built with cryptographic love ◉</p>
    </div>
  </footer>

  <script>
    document.getElementById('year').textContent = new Date().getFullYear();

    // Only animate if JS loads — content is visible by default via CSS
    // Add .js-loaded class to body, then CSS handles the rest
    document.body.classList.add('js-loaded');

    const io = new IntersectionObserver((entries) => {
      entries.forEach(e => {
        if (e.isIntersecting) {
          e.target.classList.add('visible');
        }
      });
    }, { threshold: 0.08 });

    document.querySelectorAll('.animate-on-scroll').forEach(el => io.observe(el));
  </script>
</body>
</html>
'@

git add docs\index.html
git commit -m "fix: content visible by default, animate only on scroll"
git push

Write-Host "Done! Refresh https://ai.oooooooooo.se in ~30 seconds" -ForegroundColor Green