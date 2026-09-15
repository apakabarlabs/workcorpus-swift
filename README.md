[![Tests](https://github.com/apakabarlabs/sonnetcorpus-swift/actions/workflows/tests.yml/badge.svg)](https://github.com/apakabarlabs/sonnetcorpus-swift/actions/workflows/tests.yml)
# sonnetcorpus-swift

Reads the book a reading exercise is built on: the printed text, how it is cut
into what a person reads in one sitting, and the thresholds a reading is held to.

The book is written once and read by everything that touches it — the tool that
records it, the tool that measures it, and the app a reader holds. Keeping the
one reading of that file here is what stops the three from disagreeing about
what is written.

## What it holds

- **The work file**, refused rather than half-read when it is short of the
  sequence it claims: a book missing a piece would silently teach a shorter one.
- **A piece**, the lines a reader takes in one sitting, and the cuts that say how
  a piece is broken for a single attempt.
- **What a reading is held to**: the score a word counts as difficult at, the
  shortest attempt worth checking, and the stages a reader goes through.
- **A reader's standing** in those stages.

## Use

```swift
let book = try WorkFile.book(fromYAML: text)
let piece = book.sonnets[0].pieces(for: .line)[0]
```
