# Changelog

## 0.3.0

### Removed

- `Work.listening` and `ListeningThresholds`. How short an attempt may be before
  it counts as an accidental tap is the application's own setting, not something
  the work describes, so a work no longer carries it.
- `HeldReading.shortestAttemptSeconds`. Build a held reading without it:

  ```swift
  // 0.2
  HeldReading(untouchedBelow: 0.001, begunBelow: 0.5, mostBelow: 1,
              difficultWordScore: 3, shortestAttemptSeconds: 0.2, free: [1])
  // 0.3
  HeldReading(untouchedBelow: 0.001, begunBelow: 0.5, mostBelow: 1,
              difficultWordScore: 3, free: [1])
  ```

### Changed

- Decoding a work no longer throws for a missing or out-of-range
  `shortest_attempt_seconds`. A work file whose `reading` still carries that key,
  or a book that still has a `listening` mapping, is read as before, and those
  values are ignored.

## 0.2.0

### Changed

- The shape of a work comes from its file: each piece carries the title the work
  gives it, and the cuts that break a piece for one attempt are named there
  rather than computed, so a work of stanzas or scenes reads as well as a book of
  sonnets.

## 0.1.0

- Reads a work: its pieces, how each is cut, the parts it is divided into, and
  what a reading of it is held to.
- Knows nothing of any one book. How many pieces a work has and how long each is
  are read from its file, and how a piece is cut is named there too.
