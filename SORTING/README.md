## Problem

Read one line of at most 1000 uppercase letters from standard input. Print the same letters in non-descending order, with a trailing newline. The judge page lists BF as the only allowed language.

The statement and judge page give these bounds.

| Quantity | Bound |
| --- | --- |
| Line length | at most 1000 letters |
| Alphabet | A through Z |
| Time limit | 1000 ms |
| Memory limit | 1536 MB |

The line length sets the whole workload; the other bounds never bind.

## Idea

Count how often each of the 26 letters appears. Write the letters from A to Z, each repeated its counted number of times. Counting reads each character once, while a comparison sort spends O(n log n) comparisons on the same line.

Cost per input character: one array increment. Cost per output character: one buffer append.

## Why It Works

Only 26 characters can appear, so one counter per letter captures the whole line. Letter order is fixed, so emitting the counters in order produces the sorted line.

`ch` is the current input character.
`int(ch) - firstUpperValue` maps A to slot 0 and Z to slot 25.
`letterCounts` holds one count for each letter.
`char(i + firstUpperValue)` turns a slot index back into a letter.

The generator prints this trace for the sample:

```
input: BRAINFUCK
A 1
B 1
C 1
F 1
I 1
K 1
N 1
R 1
U 1
output: ABCFIKNRU
```

Writing every letter its counted number of times gives the answer line.

## Code

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
```

The read loop runs once per input line and fills one buffer. It restores the newline that `readLine` strips. One read pass costs time linear in the input size.

```nim
var letterCounts: array[0..letterKinds - 1, int]
var scanPos = 0
while scanPos < inputData.len:
  let ch = inputData[scanPos]
  if ch >= 'A' and ch <= 'Z':
    letterCounts[int(ch) - firstUpperValue] += 1
  scanPos += 1
```

The index `scanPos` walks every byte once and skips characters outside A to Z. The range test keeps the array index inside its 26 slots. The pass costs one step per input byte.

```nim
var outputBuffer = ""

proc appendLetter(letter: char) =
  outputBuffer.add letter
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The flush fires once per 256 KiB of answer text, not once per letter. Reusing the buffer avoids an allocation on every flush. The cost is one write per full block.

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

The first index walks the 26 letters in order; the second repeats each letter its counted number of times. The final append adds the required trailing newline. One last write emits the bytes left below `flushBlockBytes`.

## Complexity

Counting takes O(n) time for n input characters and uses 26 counters. Output takes O(n) time and stays under one block for this problem.

Total time is O(n) and total space is O(1). A comparison sort takes O(n log n) time for contrast.
