# Vayl legal pages — publish checklist

Two tailored drafts live here: `privacy.html` (required by Apple) and `terms.html` (custom, includes the "not therapy" disclaimer). Both are dark-themed to match the app and render cleanly in the in-app legal sheet.

## Step 1 — Fill the blanks (both files)
Find-and-replace every bracketed placeholder in **both** HTML files:

| Placeholder | Replace with |
|---|---|
| `[LEGAL ENTITY]` | Your legal name or company (e.g. `Bryan Jorden` or `Vayl LLC`) |
| `[CONTACT EMAIL]` | A real support/privacy email you actually monitor |
| `[JURISDICTION]` | Your state/country for governing law (e.g. `California, USA`) |
| `[EFFECTIVE DATE]` | The date you publish (e.g. `July 14, 2026`) |

## Step 2 — Publish on GitHub Pages (free)
Your app repo is private, and private-repo Pages needs a paid plan, so use a **separate public repo** just for these two files (keeps your app source private):

1. Create a new **public** GitHub repo, e.g. `vayl-legal`.
2. Copy `privacy.html` and `terms.html` into its root and push.
3. In the repo: **Settings → Pages → Source: "Deploy from a branch" → Branch: `main` / `(root)` → Save.**
4. Wait ~1 minute. Your URLs will be:
   - `https://<your-github-username>.github.io/vayl-legal/privacy.html`
   - `https://<your-github-username>.github.io/vayl-legal/terms.html`
5. Open both URLs to confirm they render.

## Step 3 — Wire the URLs into the app
In `Vayl/Core/Services/LegalLinks.swift`, replace the two placeholder Apple URLs with your published URLs (`static let terms` and `static let privacy`). Delete the ⚠️ PLACEHOLDER comment block once done.

## Step 4 — App Store Connect
Paste the **privacy** URL into App Store Connect → your app → **App Privacy → Privacy Policy URL**. (Terms is optional in ASC; the in-app link is enough.)

---
**Not legal advice.** These are solid, tailored starting drafts. For a sensitive (intimacy/relationships) app it's worth having a lawyer skim the disclaimer and liability sections before you rely on them.
