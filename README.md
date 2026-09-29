[![Tests](https://github.com/apakabarlabs/workcorpus-swift/actions/workflows/tests.yml/badge.svg)](https://github.com/apakabarlabs/workcorpus-swift/actions/workflows/tests.yml)
[![Documentation](https://github.com/apakabarlabs/workcorpus-swift/actions/workflows/documentation.yml/badge.svg)](https://apakabarlabs.github.io/workcorpus-swift/documentation/workcorpus/)
# workcorpus-swift

Reads the work a reading exercise is built on: its text, how it is divided, and
what a reading of it is held to.

A work is written once, as one file, and read by everything that touches it —
the tool that records it, the tool that measures the recording, and the app a
reader holds. One reading of that file, in one place, is what keeps the three
from disagreeing about what is written.

## What it holds

- **A piece**, what a reader takes in one sitting: a sonnet, a stanza, a scene.
  It carries its own title, because only the work knows what to call it.
- **How a piece is cut** for a single attempt. The work says it; nothing here
  computes it, since how a sonnet falls into quatrains or a scene into speeches
  is the work's own shape. A stage the work says nothing about is read line by
  line.
- **A part**, a run of pieces the work is divided into.
- **What a reading is held to**: the score a word counts as difficult at and the
  bands a stage is coloured by.
- **A reader's standing** in the stages of one piece.

What it does not hold is how long a piece should be, or how many pieces a work
has. Those belong to the work file, and a library that knew them could serve
only one book.

## Use

```swift
let work = try WorkCorpus.decodeWork(yaml)
let piece = work.pieces[0]
let firstBlock = piece.cuts(for: .block)[0]
```

`decodeWork` reads a work file and `decodeWorkFromBook` an assembled book. Both
parse the YAML themselves, so they are the way to have a work held to every
rule: numbers written as plain decimal digits within 32 bits, stage bounds as
plain decimal fractions, no null where text belongs, and no YAML anchors,
aliases, merge keys or repeated keys. `Work` is also `Decodable`, and decoded
with another decoder, such as `JSONDecoder`, its numbers, fractions and texts
are held to the same rules as far as that decoder shows how each was written.

## Documentation

The [Swift-DocC API reference](https://apakabarlabs.github.io/workcorpus-swift/documentation/workcorpus/)
is generated from the public API on every push to `main`.

## Lines of Code

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/apakabarlabs/workcorpus-swift/main/.github/loc-history-dark.svg">
  <source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/apakabarlabs/workcorpus-swift/main/.github/loc-history-light.svg">
  <img src="https://raw.githubusercontent.com/apakabarlabs/workcorpus-swift/main/.github/loc-history.svg" alt="Lines of code over time">
</picture>
