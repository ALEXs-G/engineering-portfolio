# Security Policy

## Secrets must never be committed

This repository is public. Credentials of any kind must not appear in source
files, notebooks, reports, images or commit history. This includes:

- Wi-Fi SSIDs and passwords
- Cloud/IoT API keys (e.g. ThingSpeak write keys)
- Access tokens, private keys, passwords

## How credentials are handled

Firmware that needs credentials reads them from a local header that is
excluded by `.gitignore`:

| Project | Template (committed) | Local file (ignored) |
|---|---|---|
| Smart irrigation firmware | `smart-irrigation-system/firmware/irrigation_controller/secrets.example.h` | `.../irrigation_controller/secrets.h` |

To build, copy the template to `secrets.h` and fill in your own values. The
sketch stops at compile time with an explicit `#error` if `secrets.h` is missing.

## Incident record

| Date | Finding | Status |
|---|---|---|
| 2026-10-04 | ThingSpeak **write** API key and Wi-Fi SSID hard-coded in `smart-irrigation-system/code.ino` (commits `0f26906`, `7e15367`). The same key is printed in Annex A of `smart-irrigation-system/RelatorioSISTEMAIrrigacaoFinal.pdf`. The Wi-Fi password was already masked (`************`). | Removed from current source. **Key rotation by the owner: pending.** Git history and the PDF still contain the old key. |

Rotating the key is the only effective fix. A rotated key stays exposed in git
history and in the PDF, but it no longer grants write access to the channel.

### Optional: purge the old key from git history

Rewriting history changes every commit hash and requires a force push. It does
**not** remove copies that are already in forks, clones or caches. Do this only
after rotating the key, and only if you want the history cleaned as well.

```bash
# Requires: pip install git-filter-repo   (work on a fresh mirror clone)
git clone --mirror https://github.com/ALEXs-G/engineering-portfolio.git
cd engineering-portfolio.git
# Write the OLD values into a local file (never commit this file):
#   <old ThingSpeak write key>==>REDACTED_THINGSPEAK_KEY
#   <old Wi-Fi SSID>==>REDACTED_SSID
nano ../replacements.txt
git filter-repo --replace-text ../replacements.txt
# The PDF is binary; --replace-text does not redact it. To remove the old
# PDF from history entirely, also run:
#   git filter-repo --invert-paths --path smart-irrigation-system/RelatorioSISTEMAIrrigacaoFinal.pdf
# and re-add a redacted PDF in a new commit.
git push --force --mirror
```

## Reporting

If you find a credential or other sensitive data in this repository, open an
issue without including the secret itself, or contact the owner via LinkedIn
(link in the root README).
