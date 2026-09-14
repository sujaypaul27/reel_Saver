# Coding Conventions & Security Rules

## 1. Sensitive Information & Security
- Never hardcode or commit sensitive information, API keys, tokens, credentials, or private keystores.
- Always ensure sensitive files (`.env`, `key.properties`, `google-services.json`, `credentials.json`, `*.jks`, `*.keystore`, etc.) are included in `.gitignore`.
- Use environment variables or configuration loaders for any runtime secrets.

## 2. Naming Conventions (Simple English)
- Use clear, simple, descriptive English for all identifiers (variables, functions, classes, files).
- Avoid cryptic abbreviations, single-letter variables (except standard loop indices), or overly dense shorthand.
- Strive for self-documenting code so that any developer can understand what each variable represents at a glance.
  - Examples:
    - Prefer `videoDownloadUrl` over `vUrl` or `v_u`.
    - Prefer `isDownloading` over `dlFlg`.
    - Prefer `downloadProgressPercentage` over `prgPct`.
    - Prefer `copiedText` over `cTxt`.
