# SORTING — Sorting is easy (SPOJ)
<https://www.spoj.com/problems/SORTING/>

## Problem

A line of uppercase letters arrives scrambled. Print the same letters in alphabetical order. The judge restricts submission to an esoteric language, but exact output bytes are all that matter.

Input: one line of at most 1000 uppercase letters, ended by a newline. Output: the same letters in nondecreasing order, followed by a newline.

The statement sets these bounds.

| Item | Bound |
| --- | --- |
| Line length | at most 1000 uppercase letters |
| Alphabet | A through Z |
| Input ending | one newline |
| Judge time limit | 1000 ms |
| Judge memory limit | 1536 MB |

The alphabet has only 26 letters, so counting beats comparison sorting.

The sample input:

```
BRAINFUCK
```

The sample output:

```
ABCFIKNRU
```

## Idea

Count the letters like tally marks on a sheet, then rewrite the alphabet from A to Z. You never move a letter more than once. That is counting sort, and it fits the 26-letter alphabet perfectly.

The program scans the input once and increments one of 26 counters. It then writes each letter as many times as its counter says. Counting costs O(N) for N input characters, and writing costs O(N) again. A comparison sort costs O(N log N) and still handles only 1000 letters.

Twenty-six counters replace a comparison sort.

## Why It Works

Three facts carry the program.

1. Each uppercase letter maps to a counter index by subtracting the code of A. The index runs from 0 through 25.
2. Counting preserves multiplicity, so writing counters in index order produces sorted output. Equal letters stay together automatically.
3. Non-uppercase bytes are ignored, so the trailing newline never becomes a letter. The output always ends with one newline.

Each term has one job.

| Term | Meaning |
| --- | --- |
| `letterCounts` | 26 tallies, one per uppercase letter |
| `firstUpperValue` | character code of A |
| `letterKinds` | size of the alphabet, 26 |
| `appendLetter` | writes one byte through the output buffer |

No numeric rounding appears because the program handles only characters.

A script tallies the sample word BRAINFUCK.

```text
letters: B R A I N F U C K
tallies: A=1 B=1 C=1 F=1 I=1 K=1 N=1 R=1 U=1
write A B C F I K N R U
output ABCFIKNRU
```

Every letter appears once, so the sorted word has nine characters.

## Code

**Reader and tallies.** One pass counts uppercase bytes only.

```nim
{.passC: "-O2".}
{.push checks: off.}

const firstUpperValue = 65
const letterKinds = 26
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var letterCounts: array[0..letterKinds - 1, int]
var scanPos = 0
while scanPos < inputData.len:
  let ch = inputData[scanPos]
  if ch >= 'A' and ch <= 'Z':
    letterCounts[int(ch) - firstUpperValue] += 1
  scanPos += 1
```

The read loop collects the whole stream into one buffer. The `if` test excludes the newline. The cost is one pass over the input bytes.

**Buffered writer.** Each letter goes into one output buffer.

```nim
var outputBuffer = ""

proc appendLetter(letter: char) =
  outputBuffer.add letter
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`setLen 0` reuses one allocation after each flush. No write happens per letter unless the buffer fills.

**Sorted output.** Counters are read in alphabetical order.

```nim
for i in 0..<letterKinds:
  let repeatCount = letterCounts[i]
  for j in 0..<repeatCount:
    appendLetter(char(i + firstUpperValue))

appendLetter('\n')
stdout.write outputBuffer
outputBuffer.setLen 0
{.pop.}
```

The outer loop has exactly 26 steps. The inner loop runs once per occurrence of one letter. The final call adds the required newline.

## Complexity

Counting and writing each scan the input once.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | O(N) for N bytes | N bytes |
| Letter tally | O(N) | 26 counters |
| Sorted write | O(N) | one block |
| Total | O(N) | O(N) |

N is at most 1000, so the run is tiny.

| Measure | Big O |
| --- | --- |
| Time | O(N) |
| Space | O(N) input plus constant counters |

A comparison sort costs O(N log N) and needs extra work to move letters around.
