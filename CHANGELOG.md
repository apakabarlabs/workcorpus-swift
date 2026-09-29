# Changelog

## 0.5.0

### Added

- `Work.language`: the language the work names itself as written in. It is read
  from the `language` key of a work file or an assembled book, and has to be a
  language tag: two or three lowercase letters, then any number of `-` and two to
  eight ASCII letters or digits, such as `en`, `eng` or `en-GB`. Anything else is
  refused with `WorkShapeError.invalidLanguage`, which names the value.
- `WorkCorpus.WorkShapeError` is public, so a caller can tell which part of a work
  is malformed. `decodeWork`, `decodeWorkFromBook`, `work` and `Piece`'s
  initialisers document what they throw.

### Changed

- `WorkCorpus.work` takes the work's language first, since a held work has no
  file to read it from:

  ```swift
  // 0.4
  try WorkCorpus.work(pieces: pieces, reading: reading)
  // 0.5
  try WorkCorpus.work(language: "eng", pieces: pieces, reading: reading)
  ```
- An assembled book needs a `language` key; one without it no longer decodes.
- A piece's `cuts` table is validated when the piece is made, so no `Piece`
  exists with cuts that do not divide its lines. The sizes a stage is cut into
  have to add up to exactly the lines of the piece. A cut of zero or fewer lines,
  sizes that add up to more or fewer lines than the piece has, cuts for a stage
  that does not exist, and cuts for the `line` stage are refused, naming the
  piece and the stage. Until now sizes past the end of the piece were cut short,
  a shortfall was made up with one more cut of the remaining lines, and cuts for
  an unknown or the `line` stage were ignored. A stage the work says nothing
  about, or a `cuts` of `null`, is still read line by line.
- Every number a work carries — piece numbers, cut sizes, part bounds, free
  pieces and the difficult-word threshold — is a YAML integer that fits in 32
  bits, written as plain decimal digits with an optional `-` and no leading zero,
  so that every port reads the same work. A larger value, a quoted string, a
  float, a boolean, null, a list or a mapping in place of the number, or a number
  written with `+`, a leading zero, as `-0`, with underscores, `0x`/`0o`/`0b` or
  as sexagesimal `1:30` is refused with `WorkShapeError.invalidNumber`, naming
  the field, such as `pieces[0].cuts.block[1]`. The piece and free-piece
  identifiers of a work file are held to the same writing and the same 32 bits,
  and one that is not, such as `'+3'`, `'03'` or `'-0'`, is refused with
  `WorkError.pieceIsNotNumbered`. `PieceAsset.number(inName:)` reads no number
  past 32 bits.
- A work decoded from JSON through `Decodable` holds its numbers to their value:
  a JSON number that is a whole number within 32 bits reads, so `5.0` reads as
  5, while a string such as `"5"`, a boolean, null, a fraction, a value past 32
  bits or `-0` is refused with `WorkShapeError.invalidNumber`, naming the field.
  The value is read as a `Decimal` rather than through a binary float, so
  `5.000000000000000001` and `4.9999999999999999999` are fractions and refused. A
  JSON number that `Decimal` holds with 38 or more significant digits is refused,
  a whole number with `invalidNumber` and a bound with `invalidFraction`, since
  not every port can hold it exactly; digits past the ones `Decimal` keeps are
  dropped by Foundation before the library sees the number.
- A text a work needs — its language, a piece's title, identifier and lines, a
  part's title and summary, a work file's slug and title — is refused with
  `WorkShapeError.nullText`, naming the field, when it is null as the YAML 1.2
  core schema reads null: written as `null`, `Null`, `NULL` or `~`, or left empty
  after its key or dash. Until now YAML null read as the text it was written as,
  or nothing. Empty text is written as `""`, as a blank line of
  a poem is. A null `short`, `summary` of a work-file section or `cuts` still
  reads as none.
- The stage field bounds, `stage_field.*` in a book and `reading.*_below` in a
  work file, follow the one writing numbers follow: in YAML plain decimal digits
  with an optional `-` and fractional part, such as `0.001` or `1`; in JSON a
  JSON number. A quoted value, a boolean, null, or in YAML `0.5_0`, `.5`, `5e-1`
  or sexagesimal `1:00` is refused with the new
  `WorkShapeError.invalidFraction`, naming the field, and so is a JSON bound a
  `Double` cannot hold, such as `1e-400` or `1e400`.
- A YAML mapping that names a key twice is refused with the new
  `WorkShapeError.repeatedKey`, naming the key, rather than with the parser's
  `DecodingError`; of several, the key repeated first in the document is named. A key the work does not know is skipped, in YAML and JSON
  alike. A key repeated in one JSON object is not refused: `JSONDecoder` keeps
  one of the values before a `Decodable` type sees the object.
- `Part.init` throws `WorkShapeError.partOutOfRange` for a part that starts before
  piece one, ends before it starts, or does not fit in 32 bits, and a work whose
  part runs past its last piece is refused with the same error rather than
  counting past it:

  ```swift
  // 0.4
  let part = Part(title: "Sonnets", summary: "", first: 1, last: 154)
  // 0.5
  let part = try Part(title: "Sonnets", summary: "", first: 1, last: 154)
  ```
- A work file or held pieces whose numbering does not run from one in order are
  refused with `CorpusError.outOfOrder` before their parts are assembled, so a
  piece numbered `0` is named as out of order rather than as a part out of range.
- A work file or book that gives a value a YAML anchor, takes one from an alias,
  or merges a mapping in with a `<<` key is refused with the new
  `WorkShapeError.yamlReference`, naming the anchored value or the merging
  mapping, such as `parts[0]`. They were resolved until now, but YAML readers do
  not resolve them alike, so the same file could read differently on another
  port. A `<<` key is refused in quotes too, since some readers merge it all
  the same, and whatever it holds. These YAML rules, and the naming of a repeated
  key, hold through `decodeWork` and `decodeWorkFromBook`, which parse the YAML
  themselves; `Work` decoded with a caller's own `YAMLDecoder` leaves anchors,
  aliases and merges to Yams, while its numbers, fractions and texts are held to
  the same rules as far as the decoder shows how a value was written.
- A value written with an explicit YAML tag — `!!str 3`, `!!int 3`, `!poem`, the
  non-specific `!`, or a tag on a list or mapping — is refused with the new
  `WorkShapeError.explicitTag`, naming the field, so that `score_threshold:
  !!str 3` no longer reads as 3. Yams cannot tell `!!str` on a quoted value or on
  a key from no tag at all, so those two alone are read as if untagged; the
  Kotlin port refuses them too.
- `PieceAsset` compares a stem and a file name in Unicode normalization form C,
  and reads only the ASCII digits `0` to `9` as the digits of a piece number or
  of a numeric voice suffix. A name such as `s-12三` now reads as piece 12, and
  `s-001-三` names the voice `三`.
- `Piece.init(number:title:lines:cutSizes:)` throws, since it is where the cuts
  are refused. Calls need `try`:

  ```swift
  // 0.4
  let piece = Piece(number: 1, title: "Sonnet 1", lines: lines)
  // 0.5
  let piece = try Piece(number: 1, title: "Sonnet 1", lines: lines)
  ```

### Fixed

- `PieceAsset.name` writes the stem as it is. It was used as a format string, so
  a stem containing `%` produced a wrong name.
- `PieceAsset.name` and `sharedReading` pad numbers themselves rather than through
  `%d`, which reads only 32 bits of an `Int`.
- A work without pieces is refused with `WorkShapeError.invalidFreePieces`,
  since no piece of it can be free. Until now its free list could name piece 1.

## 0.4.0

### Changed

- `DrillStage` is now `ReadingStage`. The `line` and `block` cases, raw values,
  work cut names, and stored progress order are unchanged. The new name keeps
  reading a work separate from apakabar.fm's unrelated `Drill` entity.

## 0.3.1

### Fixed

- `PieceAsset.number(inName:)` and `voice(inName:)` read a bare file name again,
  as in 0.2.0. 0.3.0 read the name as a path on disk, so a recording path such as
  `onyx/sonnet-004.mp3` matched piece 4 and an empty name read the current
  directory.

### Changed

- Building the documentation brings in `swift-docc-plugin` as a package
  dependency, so `Package.resolved` gains it and `swift-docc-symbolkit`. Neither
  is linked into the library.

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

- `HeldPiece.init` takes `cutSizes` last, after the part it belongs to, where a
  defaulted argument sits in the rest of the library. Calls that pass it need the
  new order:

  ```swift
  // 0.2
  HeldPiece(number: 1, title: "Sonnet 1", lines: lines, cutSizes: cuts,
            partTitle: "Sonnets", partShort: nil, partSummary: "")
  // 0.3
  HeldPiece(number: 1, title: "Sonnet 1", lines: lines,
            partTitle: "Sonnets", partShort: nil, partSummary: "", cutSizes: cuts)
  ```
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
