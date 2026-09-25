# ``WorkCorpus``

Decode a portable reading work, validate its shape, and derive the pieces, stages,
assets, and progress a reading application needs.

## Load a work

Use ``WorkCorpus/decodeWork(_:)`` for the nested work-file format or
``WorkCorpus/decodeWorkFromBook(_:)`` for the assembled book format. Both entry
points validate numbering, parts, free pieces, and progress thresholds before
returning a ``Work``.

```swift
let work = try WorkCorpus.decodeWork(yaml)
let firstPiece = work.pieces[0]
let lineCuts = firstPiece.cuts(for: .line)
```

The nested work-file format groups pieces under sections and keeps reading settings
in one `reading` mapping:

```yaml
slug: poems
title: Poems
reading:
  untouched_below: 0.001
  begun_below: 0.5
  most_below: 1.0
  difficult_word_score: 3
  free: ['1']
sections:
  - title: Opening poems
    summary: The first part.
    pieces:
      - id: '1'
        title: First poem
        lines: [The first line.]
```

The assembled book format supplies the resulting pieces and parts directly:

```yaml
pieces:
  - number: 1
    title: First poem
    lines: [The first line.]
parts:
  - title: Opening poems
    summary: The first part.
    first: 1
    last: 1
free: [1]
stage_field:
  untouched_below: 0.001
  begun_below: 0.5
  most_below: 1.0
difficult_words:
  score_threshold: 3
```

## Name its assets

``PieceAsset`` gives recordings, alignments, and shared attempts deterministic names.
``NarrationVoice`` identifies the voice variant used by those names.

## Topics

### Decode and validate

- ``WorkCorpus``
- ``Work``
- ``Piece``
- ``Part``

### Configure reading behavior

- ``ReadingStage``
- ``StageFieldScale``
- ``DifficultWordsConfiguration``

### Name files

- ``PieceAsset``
- ``NarrationVoice``

### Track progress

- ``PieceStanding``

### Assemble from held values

- ``HeldPiece``
- ``HeldReading``
