[![Tests](https://github.com/apakabarlabs/workcorpus-swift/actions/workflows/tests.yml/badge.svg)](https://github.com/apakabarlabs/workcorpus-swift/actions/workflows/tests.yml)
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
- **What a reading is held to**: the score a word counts as difficult at, the
  shortest attempt worth checking, and the bands a stage is coloured by.
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
