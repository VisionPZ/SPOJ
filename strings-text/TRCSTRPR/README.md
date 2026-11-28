# TRCSTRPR — Prime Names (SPOJ)

<https://www.spoj.com/problems/TRCSTRPR/>

## Problem

Mina and Raju shift every letter of a name by a number. If any shifted ASCII value is prime, the name is a prime name.

Input: a list size `L`, then `L` lines of `S N`, where `S` is a name and `N` is a number. Output: `YES` or `NO` per name, on its own line.

| Item | Bound |
|---|---|
| List size `L` | less than 100 |
| Name length | less than 20 characters |
| Added number `N` | less than 10 000 |
| Judge limit | 0.5 s, 1536 MB |

The largest shifted value is about 10 121, so a small sieve covers every case.

Sample input:

```
2
Mina 20
Shimul 60
```

Sample output:

```
YES
NO
```

## Idea

Treat primality like a pre-stamped checklist: mark every composite once before reading names.
The sieve fills a boolean table up to 30 000. Then each shifted letter is a single array lookup.
Trial division per letter would repeat the same small divisions many times.
The sieve pays once and answers every later question in constant time.

## Why It Works

1. Every ASCII letter is at most 122, so adding `N < 10 000` stays below 30 000.
2. A composite below 30 000 has a prime factor at most its square root, so crossing off multiples from `p * p` marks every composite.
3. A name is prime when at least one shifted letter is prime, so the inner loop stops at the first hit.

| Term | Meaning |
|---|---|
| `isPrimeTable` | boolean lookup table, true for prime values |
| `shiftedValue` | ASCII code of a letter plus the added number |
| `hasPrime` | flag set when a prime shifted value is seen |

The trace below comes from `gen.py` on the sample case:

```
trace: Mina+20 -> 97 prime -> YES; Shimul+60 -> no prime -> NO
```

The first shifted value, 97, is prime, so `Mina` earns `YES`.

## Code

**Prime table.** A sieve marks composites once, before any input is parsed.

```nim
const maxPrimeValue = 30000
const flushBlockBytes = 1 shl 17

var isPrimeTable = newSeq[bool](maxPrimeValue + 1)
var tablePos = 2
while tablePos <= maxPrimeValue:
  isPrimeTable[tablePos] = true
  tablePos += 1
var baseValue = 2
while baseValue * baseValue <= maxPrimeValue:
  if isPrimeTable[baseValue]:
    var multiple = baseValue * baseValue
    while multiple <= maxPrimeValue:
      isPrimeTable[multiple] = false
      multiple += baseValue
  baseValue += 1
```

`maxPrimeValue` exceeds the largest possible shifted value. Marking starts at `baseValue * baseValue` to preserve the prime itself. Cost is about 30 000 log log 30 000 steps.

**Token reader.** Integers and names are scanned by index, with no token objects.

```nim
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
  let startPos = pos
  while pos < data.len and data[pos] > ' ':
    pos += 1
  return data[startPos ..< pos]
```

All lines go into one buffer, so blank lines cannot desync the reader. `nextToken` returns a slice of the buffer, not a parsed copy.

**Driver.** Shifts each letter, then writes one verdict per name.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let listSize = nextInt(inputData, scanPos)
for _ in 0..<listSize:
  let personName = nextToken(inputData, scanPos)
  let addedNumber = nextInt(inputData, scanPos)
  var hasPrime = false
  for k in 0..<personName.len:
    let shiftedValue = int(personName[k]) + addedNumber
    if shiftedValue <= maxPrimeValue and isPrimeTable[shiftedValue]:
      hasPrime = true
      break
  if hasPrime:
    appendOutput("YES\n")
  else:
    appendOutput("NO\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

`appendOutput` flushes in 128 KiB blocks, though this output is tiny. The guard on `shiftedValue` keeps the lookup in range. Cost is at most 19 lookups per name.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Sieve | O(30 000 log log 30 000) steps | 30 001 booleans |
| Input read | one pass over input bytes | input bytes |
| Name check | up to 19 lookups per name | none |
| Output | one final write | answer bytes |

The sieve dominates setup, and each name adds only a short loop.

| Measure | Big O |
|---|---|
| Time | O(P log log P + L * K), where P = 30 000 and K is name length |
| Space | O(P) for the table |

Trial division for every letter costs O(K * sqrt(offsetValue)) per name. The sieve removes that repeated work and fits well inside the 0.5 s limit.
