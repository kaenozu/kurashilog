# Life-journal design contract

Kurashilog presents analysis as a readable life journal rather than a uniform operations dashboard.

- Hero cards introduce a chapter or the strongest high-confidence finding.
- Insight cards explain one finding with its evidence and quality.
- Map cards provide spatial context without making coordinates the primary content.
- Mini cards hold supporting facts and never compete with the chapter headline.
- Empty, loading, insufficient-data, error, and private states use explicit copy and semantics rather than color alone.
- Major actions remain at least 48 dp and layouts remain scrollable at 200% text.
- Material 3 ColorScheme remains the source of truth; journal-specific semantic colors live in a ThemeExtension.
