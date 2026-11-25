# GCJ1C09A — All Your Base (SPOJ)

<https://www.spoj.com/problems/GCJ1C09A/>

## Problem

An alien message uses unknown symbols for digits in an unknown base. Choose a digit meaning for each symbol and a base to make the decoded positive number as small as possible. Report one minimum per message.

Input starts with T, then T lines, each a string of lowercase letters and digits with length from 1 to 60. Numbers never start with a zero digit, and base one is forbidden. Output `Case #X: V` per line, where X starts at one.

| item | bound |
|---|---|
| test cases T | 1 to 100 |
| message length | 1 to 60 |
| decoded answer | at most 10^18 |
| judge limit | 20000 ms, 1536 MB |

The answer bound keeps every decoded value inside a signed 64-bit integer.

The sample input:

```
3
11001001
cats
zig
```

The sample output:

```
Case #1: 201
Case #2: 75
Case #3: 11
```

## Idea

Treat each new symbol as a fresh digit, like handing out the smallest unused number tag to each new guest in a queue. The base is the smallest that fits all distinct symbols, and never one. The first symbol gets one so the number has no leading zero. Each later new symbol gets the smallest digit still free. This greedy assignment plus positional evaluation settles one message in linear time. Trying every base and every digit permutation would be far slower. Smallest tags on the earliest positions give the smallest number.

## Why It Works

1. Distinct symbols need distinct digits, so the base is at least the symbol count.
2. The base is also at least two because base one is forbidden.
3. The leading symbol cannot get zero, so its smallest choice is one.
4. A digit change on an earlier position outweighs any change on later positions, so earliest symbols get the smallest free digits.
5. Horner evaluation then turns the digit string into the decoded value.

| term | meaning |
|---|---|
| `distinctCount` | number of different symbols in one message |
| `numberBase` | smallest legal base, at least `minimumBase` |
| `symbolDigit` | chosen digit for each symbol code |
| `smallestValue` | decoded value after positional evaluation |

The table lists the values that drive the greedy assignment.

A script trace of the sample message cats:

```
symbols c a t s -> count 4 -> base 4
first symbol c  -> digit 1
new symbol a    -> smallest free digit 0
new symbol t    -> smallest free digit 2
new symbol s    -> smallest free digit 3
weights         64 16 4 1
contributions   64 0 8 3
total           75
```

The trace totals 75, which matches the second sample answer.

No rounding applies. The guard is the answer bound, which keeps the running value inside `int64`.

## Code

**Input and token reader.** The reader loads all lines and pulls messages as whitespace-free tokens.

```nim
const flushBlockBytes = 1 shl 17
const minimumBase = 2

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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token
```

`nextInt` reads the case count, and `nextToken` reads each message.
Both scanners skip separators without copying the whole input again.
The scan position advances once per token.

**Output helper.** One buffer collects all answer lines.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes only after reaching `flushBlockBytes`.
A final flush writes the remainder.
No per-line write reaches the console.

**Greedy decoding.** Each case assigns digits and evaluates the message once.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseNumber in 1 .. caseCount:
  let message = nextToken(inputData, scanPos)
  var symbolSeen = newSeq[bool](256)
  var symbolDigit = newSeq[int](256)
  for symbolCode in 0 .. 255:
    symbolDigit[symbolCode] = -1
  var distinctCount = 0
  for messageIndex in 0 .. message.len - 1:
    let symbolCode = int(message[messageIndex])
    if not symbolSeen[symbolCode]:
      symbolSeen[symbolCode] = true
      distinctCount += 1
  var numberBase = distinctCount
  if numberBase < minimumBase:
    numberBase = minimumBase
  for symbolCode in 0 .. 255:
    symbolSeen[symbolCode] = false
  var usedDigits = newSeq[bool](numberBase)
  var firstSymbol = true
  for messageIndex in 0 .. message.len - 1:
    let symbolCode = int(message[messageIndex])
    if not symbolSeen[symbolCode]:
      symbolSeen[symbolCode] = true
      var chosenDigit = 0
      if firstSymbol:
        chosenDigit = 1
      else:
        while usedDigits[chosenDigit]:
          chosenDigit += 1
      symbolDigit[symbolCode] = chosenDigit
      usedDigits[chosenDigit] = true
      firstSymbol = false
  var smallestValue: int64 = 0
  for messageIndex in 0 .. message.len - 1:
    let digitValue = symbolDigit[int(message[messageIndex])]
    smallestValue = smallestValue * int64(numberBase) + int64(digitValue)
  appendOutput("Case #" & $caseNumber & ": " & $smallestValue & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The first pass counts symbols, and the second pass hands out digits.
The leading symbol takes one to respect the no-leading-zero rule.
Horner evaluation keeps the whole pass in `int64`.

## Complexity

Each message costs a fixed number of scans of its own characters.

| phase | time | space |
|---|---|---|
| input read | one pass over the input bytes | one input string |
| symbol count | one pass per message | two tables of 256 slots |
| digit assignment | one pass per message | one digit table |
| evaluation | one pass per message | one buffer |

Each phase scans a message at most twice.

| measure | Big O |
|---|---|
| time | O(L) per message |
| space | O(L + 256) |

L is the message length, at most 60.

Enumerating bases and digit permutations costs factorial time per message. Greedy assignment finishes after three linear passes instead.
