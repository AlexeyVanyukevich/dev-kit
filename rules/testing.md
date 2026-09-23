# Testing

**Tests are written before the implementation, for every slice.**

**Integration tests run against a real PostgreSQL, started by Testcontainers.** The guarantees
that matter — constraints, row locking, timezone arithmetic — cannot be verified against a
mock, and a suite that mocks them proves only that the mock agrees with itself.

**Test data lives in datasets, not in test bodies.** Cases go in typed tables consumed by a
parameterised runner. Extending coverage should mean adding a row, not copying a test. Where a
specific value *is* the point — a real DST transition, a boundary — it belongs in the dataset
as a named case carrying its expectation, not buried in an assertion.

**Facts about the outside world are derived, not remembered.** A date that came from the tz
database is regenerated from it; a constant transcribed by hand is a constant that goes stale
without anyone noticing.

Pure functions get unit tests. Anything with a clock or a network takes them as an injected
dependency, because otherwise every threshold, cooldown and backoff test has to sleep in real
time.
