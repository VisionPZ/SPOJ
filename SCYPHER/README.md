# SCYPHER — Substitution Cipher (SPOJ)

<https://www.spoj.com/problems/SCYPHER/>

## Problem

Each case gives an alphabet size, a word count, encrypted words, and one encrypted message.
The hidden plain words sit in sorted dictionary order, and the encrypted words keep that order.
Print the decrypted message when the cipher is unique, or print the failure sentence.

The judge sets these limits.

| item | bound |
|---|---|
| cases | about 1000 |
| alphabet size | 1 to 26 |
| word count | positive |
| judge limits | 5 s, 1536 MB |

No case needs more than 26 graph nodes.

## Idea

Neighboring words reveal one letter order each. At the first difference, the earlier word carries the smaller plain letter, so add one edge. Uniqueness needs a total order; closure checks it in A^3 steps, and trying all permutations costs A! steps.

## Why It Works

Three facts carry the proof.

1. Before the first different position, two neighboring words share plain letters, so their encrypted letters match there too. The difference gives one true rank inequality.
2. A pair of non-neighboring words adds no new order. The ranks rise along the chain of neighbors between them, so transitivity already gives that inequality.
3. A cipher assigns ranks 0 to A-1 to the A letters. Exactly one assignment satisfies all inequalities when the order is total. Then each letter's rank is its count of smaller letters.

The program stores one boolean per ordered pair of letters.

| term | meaning |
|---|---|
| `leftLetter` | encrypted letter at the first difference in the earlier word |
| `rightLetter` | encrypted letter at the first difference in the later word |
| `reach[fromLetter * alphabetSize + toLetter]` | `fromLetter` ranks before `toLetter` |
| `predecessorCount` | count of letters ranked before one letter |
| `chr(baseLetterValue + rankTable[int(symbol) - baseLetterValue])` | plain letter that decrypts this encrypted letter |

A true `reach` entry means the row letter ranks before the column letter.

Sample case one gives this chain:

```
words:   cebdbac  cac  ecd  dca  aba  bac
pairs:   e/a  c/e  e/d  d/a  a/b
order:   c -> e -> d -> a -> b
ranks:   c=0  e=1  d=2  a=3  b=4
decode:  c e d a b -> abcde
```

The chain orders all five letters, so the message decodes.

Sample case two leaves one letter free:

```
words:  cca  cad  aac  bca
pairs:  c/a  c/a  a/b
edges:  c -> a -> b, with d unranked
```

Letter d fits in several places, so the message fails.

## Code

`flushBlockBytes` is the output block size. `firstDigitValue` and `baseLetterValue` name the two character offsets.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const baseLetterValue = 97
```

The block holds 128 KiB and one write flushes it. The two offsets name byte values used by the scanner.

**Integer reader.** Digits are scanned by index, so no token object is built.

```nim
proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and inputData[scanPos] <= ' ': scanPos = scanPos + 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos = scanPos + 1
  return value
```

`scanPos` is a `var` parameter, so the position survives each call. A digit byte becomes `int(inputData[scanPos]) - firstDigitValue`. Input values stay positive, so no sign branch is needed.

**Line readers.** The message keeps its spaces, and words keep their line ends.

```nim
proc skipToNextLine(inputData: string, scanPos: var int) =
  while scanPos < inputData.len and inputData[scanPos] != '\n': scanPos = scanPos + 1
  if scanPos < inputData.len: scanPos = scanPos + 1

proc readWord(inputData: string, scanPos: var int, wordBegin: var int, wordEnd: var int) =
  while scanPos < inputData.len and (inputData[scanPos] == '\n' or inputData[scanPos] == '\r' or inputData[scanPos] == ' '): scanPos = scanPos + 1
  wordBegin = scanPos
  while scanPos < inputData.len and inputData[scanPos] != '\n' and inputData[scanPos] != '\r' and inputData[scanPos] != ' ': scanPos = scanPos + 1
  wordEnd = scanPos
```

`skipToNextLine` consumes one line end and stops at the next line start. `readWord` records a word by index, so no substring is built. Both loops stop at the buffer end, so short input cannot overrun.

**Case solver.** One call handles one case and appends one output line.

```nim
proc solveCase(inputData: string, scanPos: var int, outputBuffer: var string) =
  let alphabetSize = nextInt(inputData, scanPos)
  let wordCount = nextInt(inputData, scanPos)
  skipToNextLine(inputData, scanPos)
  var reach = repeat(false, alphabetSize * alphabetSize)
  var havePrevious = false
  var previousBegin = 0
  var previousEnd = 0
  for wordIndex in 1 .. wordCount:
    var currentBegin = 0
    var currentEnd = 0
    readWord(inputData, scanPos, currentBegin, currentEnd)
    if havePrevious:
      let sharedLength = min(previousEnd - previousBegin, currentEnd - currentBegin)
      var diffPos = 0
      while diffPos < sharedLength and inputData[previousBegin + diffPos] == inputData[currentBegin + diffPos]:
        diffPos = diffPos + 1
      if diffPos < sharedLength:
        let leftLetter = int(inputData[previousBegin + diffPos]) - baseLetterValue
        let rightLetter = int(inputData[currentBegin + diffPos]) - baseLetterValue
        reach[leftLetter * alphabetSize + rightLetter] = true
    previousBegin = currentBegin
    previousEnd = currentEnd
    havePrevious = true
  skipToNextLine(inputData, scanPos)
  let messageBegin = scanPos
  while scanPos < inputData.len and inputData[scanPos] != '\n': scanPos = scanPos + 1
  let messageEnd = scanPos
  skipToNextLine(inputData, scanPos)
  for midLetter in 0 .. alphabetSize - 1:
    for fromLetter in 0 .. alphabetSize - 1:
      if reach[fromLetter * alphabetSize + midLetter]:
        for toLetter in 0 .. alphabetSize - 1:
          if reach[midLetter * alphabetSize + toLetter]:
            reach[fromLetter * alphabetSize + toLetter] = true
  var decryptable = true
  for letterIndex in 0 .. alphabetSize - 1:
    if reach[letterIndex * alphabetSize + letterIndex]: decryptable = false
  if decryptable:
    for fromLetter in 0 .. alphabetSize - 1:
      if fromLetter + 1 < alphabetSize:
        for toLetter in fromLetter + 1 .. alphabetSize - 1:
          if not reach[fromLetter * alphabetSize + toLetter] and not reach[toLetter * alphabetSize + fromLetter]:
            decryptable = false
  if not decryptable:
    outputBuffer.add "Message cannot be decrypted.\n"
  else:
    var rankTable = newSeq[int](alphabetSize)
    for toLetter in 0 .. alphabetSize - 1:
      var predecessorCount = 0
      for fromLetter in 0 .. alphabetSize - 1:
        if fromLetter != toLetter and reach[fromLetter * alphabetSize + toLetter]:
          predecessorCount = predecessorCount + 1
      rankTable[toLetter] = predecessorCount
    if messageEnd > messageBegin:
      for messagePos in messageBegin .. messageEnd - 1:
        let symbol = inputData[messagePos]
        if symbol >= 'a' and symbol <= chr(baseLetterValue + alphabetSize - 1):
          outputBuffer.add chr(baseLetterValue + rankTable[int(symbol) - baseLetterValue])
        else:
          outputBuffer.add symbol
    outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The word loop runs `wordCount` times and adds at most one edge per pair. The closure runs `alphabetSize` cubed times. The message loop runs once per message symbol.

**Driver.** One read gathers all input, and writes flush in blocks.

```nim
var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"
var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var outputBuffer: string
for caseIndex in 1 .. caseCount:
  solveCase(inputData, scanPos, outputBuffer)
stdout.write outputBuffer
```

`readLine` adds each line plus its newline, so blank lines and spaces survive. The final write covers the tail and does nothing on an empty buffer.

## Complexity

The phases cost the following.

| phase | time | space |
|---|---|---|
| input read | one pass over all lines | input bytes |
| one case | A^3 boolean steps | A^2 booleans |
| output write | one write per 128 KiB block | 128 KiB |
| total at 1000 cases | about 1.8 * 10^7 steps | input bytes plus 128 KiB |

The table shows that the closure dominates each case.

The same costs in Big O notation.

| measure | Big O |
|---|---|
| time | O(N * A^3 + message bytes) |
| space | O(input bytes + A^2 + 128 KiB) |

A permutation search costs O(A!) per case, which grows far faster.
