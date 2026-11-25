# MOZMSLM — Sharmeen Loves Mozahid Loves Sharmeen [MEDIUM] (SPOJ)

<https://www.spoj.com/problems/MOZMSLM/>

## Problem

Long lowercase strings hide many copies of the pattern `sms`.
The task counts distinct subsequences, which are chosen positions in order.
The first line holds the test count t, with 1 ≤ t ≤ 2.
Each test case holds one string of length n, with 1 ≤ n ≤ 7000.
For each case, print the number of `sms` subsequences on its own line.
The count can exceed 32 bits, so the program must use a wide integer.

| Item | Bound |
|---|---|
| Test cases | 1 ≤ t ≤ 2 |
| String length | 1 ≤ n ≤ 7000 |
| Alphabet | lowercase English letters |
| Judge limit | 1000 ms, 1536 MB |

The sample case:

```
2
asdfmnsmdsms
ssmssmjm
```

```
10
4
```

## Idea

Count unfinished patterns while walking the string once.
Think of counting stage seats: each m is the stage, with s seats on both sides.
`leadingS` counts s characters already seen.
Each m creates that many `sm` pairs, stored in `smPairs`.
Each later s completes one `sms` for every stored pair.
One pass costs linear time, even at the maximum length.
A naive triple loop would examine every three positions and cost cubic time.

## Why It Works

1. Every `sms` subsequence has one middle m and two surrounding s characters.
2. `leadingS` records all s characters before the current position.
3. Reading an m adds `leadingS` to `smPairs`, since every earlier s pairs with it.
4. Reading an s adds `smPairs` to the answer, since each stored pair closes.
5. Characters other than s and m change no counter.
6. The answer uses int64, so counts above two billion still print exactly.

| Term | Meaning |
|---|---|
| `leadingS` | number of s characters seen before the current position |
| `smPairs` | number of `sm` subsequences seen so far |
| `answer` | number of completed `sms` subsequences |
| `nextToken` | hand scanner for one lowercase string |

For `skmjssm`, the first m sees one earlier s.
The two later s characters close two copies, so the answer is 2.

## Code

**Input and hand scanners.** This block loads input and reads integers and tokens.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and data[position] <= ' ':
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + ord(data[position]) - firstDigitValue
    position += 1
  return value

proc nextToken(data: string, position: var int): string =
  while position < data.len and data[position] <= ' ':
    position += 1
  var token = ""
  while position < data.len and data[position] > ' ':
    token.add data[position]
    position += 1
  return token
```

The read loop stores every input line in one string.
`nextInt` reads the case count by digit.
`nextToken` reads one lowercase string.

**Buffered output helper.** This block collects finished lines.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer writes to stdout once every 128 KiB.
A final write flushes any remaining bytes.

**Single-pass count.** This block counts `sms` subsequences.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let text = nextToken(inputData, scanPos)
  var leadingS = 0
  var smPairs = 0
  var answer: int64 = 0
  for character in text:
    if character == 's':
      answer += int64(smPairs)
      leadingS += 1
    elif character == 'm':
      smPairs += leadingS
  appendOutput($(answer) & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

An m adds earlier s characters to the pair count.
An s closes every stored pair.
The int64 answer handles the largest strings.

## Complexity

Each case scans its string once.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Scanning | one pass over integers and tokens | constant |
| Counting | one pass over string characters | constant |
| Output | one write per 128 KiB block | block buffer |

| Measure | Big O |
|---|---|
| Time | O(sum of string lengths) |
| Space | O(n) for the longest string |

A naive triple loop costs O(n³) per case.
The running pair count reduces that to one pass.
