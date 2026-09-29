# Changelog

WorkCorpus reads the text a read-aloud practice app is built on, such as a book
of poems, from a YAML or JSON file: what is read, how it is divided for practice,
and the app's settings for it.

Terms used below. A *work* is the whole text, such as Shakespeare's sonnets. A
*piece* is what a reader practises in one sitting: a sonnet, a stanza, a scene. A
*part* is a run of consecutive pieces, such as a chapter or an act. A *stage* is
how much of a piece is attempted at once: `line`, one line, or `block`, a group of
lines. A piece's *cuts* say how many lines each `block` group has. A work comes as
a *work file*, sections holding pieces as an author writes them, as an assembled
*book*, the flat form with `pieces`, `parts`, `stage_field` and `difficult_words`,
or is built in code with `WorkCorpus.work` from values the app already holds.

## 0.5.0

### Added

- `Work.language`, the language the work is written in, read from its `language`
  key. It must be a language tag: two or three lowercase letters, optionally
  followed by `-` and subtags of two to eight ASCII letters or digits, such as
  `en`, `eng` or `en-GB`. Two- and three-letter codes are equally accepted and
  kept as written. Any other value is refused with
  `WorkShapeError.invalidLanguage`, which names the value.
- `WorkCorpus.WorkShapeError` is public, so a caller can tell what in a work is
  malformed. It and the already public `WorkCorpus.CorpusError` and
  `WorkCorpus.WorkError` are named below without the `WorkCorpus.` prefix.
  `decodeWork`, `decodeWorkFromBook`, `work` and `Piece`'s initialisers document
  what they throw.

### Changed

- A work file and a book need a `language` key; one without it no longer
  decodes:

  ```yaml
  # 0.4
  slug: sonnets
  title: Sonnets
  # 0.5
  slug: sonnets
  language: eng
  title: Sonnets
  ```
- `WorkCorpus.work` takes the language first, since values held in code have no
  file to read it from:

  ```swift
  // 0.4
  try WorkCorpus.work(pieces: pieces, reading: reading)
  // 0.5
  try WorkCorpus.work(language: "eng", pieces: pieces, reading: reading)
  ```
- A piece's cuts are checked when the piece is made or decoded: the `block`
  sizes must each be at least one and add up to exactly the piece's number of
  lines, and cuts for `line` or for a stage the library does not know are
  refused. The errors, `WorkShapeError.cutsDoNotCoverThePiece`,
  `WorkShapeError.emptyCut`, `WorkShapeError.cutsForLineStage` and
  `WorkShapeError.cutsForUnknownStage`, name the piece and the stage. Until now sizes past
  the end of the piece were cut short, a shortfall got one more group of the
  remaining lines, and cuts for `line` or an unknown stage were ignored. A piece
  without `cuts`, or with `cuts: null`, is still read line by line. So
  `Piece.init(number:title:lines:cutSizes:)` throws:

  ```swift
  // 0.4
  let piece = Piece(number: 1, title: "Sonnet 1", lines: lines)
  // 0.5
  let piece = try Piece(number: 1, title: "Sonnet 1", lines: lines)
  ```
- `Part.init` throws `WorkShapeError.partOutOfRange` for a part that starts
  before piece one, ends before it starts, or does not fit in 32 bits, and a work
  whose last part runs past its last piece is refused with the same error:

  ```swift
  // 0.4
  let part = Part(title: "Sonnets", summary: "", first: 1, last: 154)
  // 0.5
  let part = try Part(title: "Sonnets", summary: "", first: 1, last: 154)
  ```
- Pieces, in a work file or passed to `WorkCorpus.work`, that are not numbered
  from one in order are refused with `CorpusError.outOfOrder` before their parts
  are checked, so a piece numbered `0` is reported as out of order rather than
  as a part out of range.
- Every whole number in a work — piece numbers, cut sizes, a part's `first` and
  `last`, the `free` pieces (those readable without purchase) and the score at
  which a word counts as difficult — must be a YAML integer that fits in 32 bits,
  written as plain decimal digits with an optional `-` and no leading zero. A
  larger value, a quoted string, a float, a boolean, null, a list or a mapping,
  or a number written with `+`, a leading zero, as `-0`, with underscores,
  `0x`/`0o`/`0b` or as sexagesimal `1:30` is refused with
  `WorkShapeError.invalidNumber`, naming the field, such as
  `pieces[0].cuts.block[1]`. A work file writes piece ids and `free` entries as
  strings, such as `'3'`; one that is not written that way within 32 bits, such
  as `'+3'`, `'03'` or `'-0'`, is refused with `WorkError.pieceIsNotNumbered`.
  `PieceAsset.number(inName:)` returns `nil` for a file name whose number does
  not fit in 32 bits.
- The progress bounds — `stage_field.untouched_below`, `begun_below` and
  `most_below` in a book, `reading.*_below` in a work file, which split a
  stage's completion into the bands untouched, begun, most and whole — must be
  written in YAML as plain decimal digits with an optional `-` and fractional
  part, such as `0.001` or `1`. A quoted value, a boolean, null, `0.5_0`, `.5`,
  `5e-1` or sexagesimal `1:00` is refused with `WorkShapeError.invalidFraction`,
  naming the field.
- A text a work needs — its language, a piece's title, id and lines, a part's
  title and summary, a work file's `slug` and `title` — is refused with
  `WorkShapeError.nullText`, naming the field, when it is YAML null: `null`,
  `Null`, `NULL`, `~`, or nothing after its key or dash. Until now it read as the
  text it was written as, or as nothing. Write empty text as `""`, as for a blank
  line of a poem. A null `short` (a part's short title), a null `summary` of a
  work-file section and a null `cuts` still read as none.
- `decodeWork` and `decodeWorkFromBook` refuse YAML that could read differently
  in another YAML reader:
  - an anchor, an alias or a `<<` merge key, quoted or not, with
    `WorkShapeError.yamlReference`, naming the anchored value or the merging
    mapping, such as `parts[0]`; an alias with no anchor, such as `*nowhere`,
    names its field, or the enclosing mapping when the alias is a key. These were
    resolved until now;
  - an explicit tag — `!!str 3`, `!!int 3`, `!poem`, `!`, or a tag on a list or
    mapping — with `WorkShapeError.explicitTag`, naming the field, so
    `score_threshold: !!str 3` no longer reads as 3. The YAML parser does not
    report `!!str` on a quoted value, or `!!str` or `!` on a key, so those are
    read as if untagged;
  - a key repeated in one mapping with `WorkShapeError.repeatedKey`, naming the
    key, rather than with `DecodingError`. Keys that differ only in how their
    accented letters are composed in Unicode count as the same key.

  Of several such problems the first in the document is reported, even when a
  syntax error follows it; of several keys repeated on one line, in a flow
  mapping `{…}`, the one whose name sorts first by Unicode code point is named.
  Inside a flow collection (`[…]` or `{…}`) a later problem may occasionally be
  named before an earlier one. A document whose first fault is a syntax error, and
  a key that is a list or a mapping, are refused with `DecodingError`. A key the
  work does not know is skipped, in YAML and JSON alike.
- Decoded from JSON with `JSONDecoder`, `Work` holds its numbers, progress bounds
  and texts to the rules above; the YAML-only rules and the checks between fields,
  such as parts covering the pieces, apply only through `decodeWork` and
  `decodeWorkFromBook`. A JSON number is judged by its value: a whole number
  within 32 bits reads, so `5.0` reads as 5 and `1e2` as 100, while a string such
  as `"5"`, a boolean, null, a fraction, a value past 32 bits or `-0` is refused
  with `WorkShapeError.invalidNumber`, naming the field. The value is read as a
  `Decimal`, not a binary float, so `5.000000000000000001` and
  `4.9999999999999999999` are fractions and refused. Before the library sees a
  number, Foundation cuts it, without rounding, to the significant digits
  `Decimal` can hold: the first 39 when those 39, read as a whole number, are at
  most 2^128 − 1 (about 3.4 × 10^38), otherwise the first 38. The library then
  refuses the number if what was kept has 38 or more significant digits,
  trailing zeros aside: a whole number with `invalidNumber`, a progress bound
  with `invalidFraction`. So `5.0000000000000000000000000000000000001` (38
  digits) and `1.00000000000000000000000000000000000001` (39 digits, all kept)
  are refused, while `5.00000000000000000000000000000000000001` (39 digits, cut
  to a 5 and 37 zeros) reads as 5. A progress bound a
  `Double` cannot hold, such as `1e-400` or `1e400`, is refused with
  `invalidFraction`. A JSON syntax error is `JSONDecoder`'s own `DecodingError`.
  A key repeated in one JSON object is not refused; `JSONDecoder` keeps one of its
  values.
- `PieceAsset` compares its stem with a file name in Unicode normalization form C,
  and reads only the ASCII digits `0` to `9` as digits, both in a piece number
  and when telling a narration voice suffix, such as `onyx` in
  `s-001-onyx.json`, from a number. `s-12三` now reads as piece 12, and
  `s-001-三` names the voice `三`.

### Fixed

- `PieceAsset.name` writes the stem as it is. It was used as a format string, so
  a stem containing `%` produced a wrong name.
- `PieceAsset.name` and `PieceAsset.sharedReading`, which names the file of a
  line attempt a reader shares, such as `s004-l09-then-beauty-is-sniggered`,
  write a number that does not fit in 32 bits in full; it was written wrongly.
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
