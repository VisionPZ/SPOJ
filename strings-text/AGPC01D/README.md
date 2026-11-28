<https://www.spoj.com/problems/AGPC01D/>

## Problem

Mina owns string A and Tina owns string B. Tina wants the largest number of complete copies of B that the letters of A can build. Every letter of A may be used only once.

| item | bound |
|---|---|
| test cases | 1 to 100 |
| string lengths | 1 to 100000 each |
| alphabet | lowercase English letters |
| judge limit | 1000 ms, 1536 MB |

The count is limited by whichever required letter runs out first. Extra blank lines may appear in the input, so token parsing must ignore them.

Sample input:

```
2
4 2
abcd
ca
4 1
abcd
e
```

Sample output:

```
1
0
```

## Idea

Count letters first, like checking ingredients before baking several cakes. For each letter of B, divide its count in A by its count in B. The smallest quotient is the number of complete copies. A missing letter forces a quotient of zero.

## Why It Works

1. One copy of B consumes exactly the multiset of letters in B.
2. The letter with the smallest quotient limits the total number of copies.
3. Two arrays of 26 slots store every count, so each case costs linear time.
4. The word scanner skips whitespace, which absorbs stray blank lines.

| term | meaning |
|---|---|
| `available` | count of each letter in string A |
| `required` | count of each letter in string B |
| `copyCount` | smallest quotient over the required letters |
| `flushBlockBytes` | output block size of 128 KiB |

Fixed-size counting gives a direct answer without constructing any candidate strings.

## Code

**Input and token scanning.** One string holds all input; the scanner walks it by index.

```nim
const flushBlockBytes = 1 shl 17
const alphabetSize = 26
const lowercaseOrigin = 97

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var word = ""
  while pos < data.len and data[pos] > ' ':
    word.add data[pos]
    pos += 1
  return word
```

The loop appends a newline after every read line.
nextWord skips whitespace, so empty lines are harmless.
Both passes together scan each byte once.

**Letter counting and answer.** Two 26-slot arrays turn strings into counts.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let sizeA = nextInt(inputData, scanPos)
  let sizeB = nextInt(inputData, scanPos)
  discard sizeA
  discard sizeB
  let sourceWord = nextWord(inputData, scanPos)
  let targetWord = nextWord(inputData, scanPos)
  var available: array[alphabetSize, int]
  var required: array[alphabetSize, int]
  for letterIndex in 0 .. sourceWord.len - 1:
    let slot = int(sourceWord[letterIndex]) - lowercaseOrigin
    if slot >= 0 and slot < alphabetSize:
      available[slot] += 1
  for letterIndex in 0 .. targetWord.len - 1:
    let slot = int(targetWord[letterIndex]) - lowercaseOrigin
    if slot >= 0 and slot < alphabetSize:
      required[slot] += 1
  var copyCount = -1
  for slot in 0 .. alphabetSize - 1:
    if required[slot] > 0:
      let possible = available[slot] div required[slot]
      if copyCount < 0 or possible < copyCount:
        copyCount = possible
  if copyCount < 0:
    copyCount = 0
  appendOutput($copyCount)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Only letters required by B are tested as limits.
A missing letter yields zero copies immediately.
Output is written in blocks of 128 KiB.

## Complexity

Each phase touches the input or output once.

| phase | time | space |
|---|---|---|
| input read | one pass over all input bytes | one input string |
| counting | one pass over each string | two 26-slot arrays |
| output | one write per 128 KiB block | block buffer |

| measure | Big O |
|---|---|
| time | O(|A| + |B|) per test case |
| space | O(1) besides the input buffer |

Generating every substring of A would cost far more than counting letters once.

