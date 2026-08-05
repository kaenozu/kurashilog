# Beginner timeline setup contract

The setup flow must remain usable without relying on a private Google Maps activity or a manufacturer-specific deep link.

1. Explain local-only processing and the value of the report before asking for a file.
2. Open Android's public location settings action first and fall back to general settings when necessary.
3. Treat returning to the app as a continuation signal, not proof that any setting was changed.
4. Keep the existing SAF import flow available after cancel, fallback, or platform failure.
5. Do not display raw platform exceptions, content URIs, file paths, coordinates, or private Timeline data.
6. Show an explicitly anonymous sample so the user can understand the finished report before importing data.
7. Keep the flow scrollable at 200% text and expose the step description and each action as separate accessibility nodes.
