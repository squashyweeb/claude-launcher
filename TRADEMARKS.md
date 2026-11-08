# Trademarks and non-affiliation

This project is **independent, unofficial, and not affiliated with,
endorsed by, or sponsored by Anthropic PBC**.

## Names used

- **Claude** and **Claude Desktop** are trademarks of **Anthropic PBC**.
- **Chromium** and **Electron** are trademarks of their respective
  projects and foundations.
- **Windows** is a trademark of **Microsoft Corporation**.

Use of these names in this project is purely descriptive — they identify
the software this launcher interoperates with. They are not a claim of
ownership, partnership, or endorsement.

## Scope — what this project is and is NOT

This project **is**:

- A small Electron + PowerShell wrapper that invokes your existing,
  independently obtained copy of Claude Desktop via standard Chromium
  CLI flags (`--user-data-dir`, `--profile`).
- An MIT-licensed collection of original source code authored by this
  project's contributors.
- A UI around functionality your copy of Claude Desktop already has.

This project **does NOT**:

- Redistribute any part of Claude Desktop, in source or binary form.
- Modify Claude Desktop outside of the optional, reversible shim at
  [shim/profile-shim.js](shim/profile-shim.js), which is an original
  MIT-licensed file that an end user may elect to install into their
  own local copy of Claude Desktop on their own machine. The shim
  contains no bytes from Anthropic's software.
- Intercept, store, forward, or transmit OAuth tokens, user content,
  or any identifying data to any third party. The launcher reads only
  the files inside its own directory and the profile directories the
  user explicitly attaches.
- Rotate, pool, share, or route authentication across accounts. Each
  profile signs in as itself.
- Bypass, extend, or evade any rate limit or quota imposed by
  Anthropic.
- Imitate Anthropic's branding, mimic any official Anthropic UI, or
  present itself as an official Anthropic product.

## License and trademark grant

The source code in this repository is licensed under the [MIT License](LICENSE).

The MIT License **does not** grant any rights to use the trademarks of
Anthropic PBC, the Electron Foundation, the Chromium project, Microsoft,
or any other third-party trademark holder. If you fork this project and
distribute it, you are responsible for making sure your fork's naming
and branding comply with those parties' trademark policies.

## Reporting

If you believe this project is misusing a trademark, please open a
private [GitHub Security
Advisory](https://github.com/squashyweeb/claude-launcher/security/advisories/new)
on this repository and we will respond in good faith.

If you represent Anthropic PBC and would prefer the project use
different wording or distance itself further from the "Claude" name,
open an issue or advisory and we will cooperate.
