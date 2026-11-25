# SERI07 — Strange But Easy

## Problem

Print the first `n` terms of the prime-combination series for each test case. Term `k` multiplies two consecutive primes and adds the next prime.

Input: a test count `t`, then `t` lines, each holding one integer `n`.
Output: one line per case, holding `n` terms separated by single spaces and no trailing space.

| item | bound |
|---|---|
| requested term count `n` | less than 10000 |
| primes needed | 3 times the largest `n`, at most 29997 |
| largest needed prime | 350293 |
| judge limit | 100 ms |
| memory | 1536 MB |

Verbatim sample from the statement:

```
3
1
2
3
```

```
11
11 90
11 90 346
```

## Idea

Think of cooking a large batch once, then serving it by the spoonful. The sieve and all term strings are prepared before any query is read.

The real algorithm is a sieve of Eratosthenes up to 351000, followed by precomputation of all 10000 term strings. Each query costs one string append per requested term.

## Why It Works

1. Term `k` uses primes at positions `3k`, `3k+1`, and `3k+2` in zero-based indexing.
2. The smallest bound that supplies 29997 primes is 351000, so one fixed sieve is enough.
3. A composite below the bound has a prime factor below its square root, so the sieve marks every composite.
4. Precomputing term strings removes all integer to text conversions from the query loop.
5. Writing a space only when the index is positive avoids a trailing space on every line.

| term | meaning |
|---|---|
| `composite` | sieve flags, one per candidate value |
| `primes` | collected primes in increasing order |
| `termTexts` | all 10000 pre-rendered term strings |
| `termIndex` | n, the number of terms to print |

Script-generated example for the first five terms:

```
primes:  2  3   5 | 7  11  13 | 17  19  23 | 29  31  37 | 41  43  47
term 1:  2 * 3 + 5   = 11
term 2:  7 * 11 + 13 = 90
term 3:  17 * 19 + 23 = 346
term 4:  29 * 31 + 37 = 936
term 5:  41 * 43 + 47 = 1810
```

For `n = 3`, the writer emits `11 90 346` and a newline, exactly as in the sample.

## Code

**Constants and scanner.** The sieve bound covers the 29997 primes the largest answer needs.

```nim
const primeLimit = 351000
const termCount = 10000
const flushBlockBytes = 1 shl 17

proc nextInt(inputData: string, pos: var int): int =
  while pos < inputData.len and (inputData[pos] < '0' or inputData[pos] > '9'):
    pos += 1
  var value = 0
  while pos < inputData.len and inputData[pos] >= '0' and inputData[pos] <= '9':
    value = value * 10 + int(inputData[pos]) - 48
    pos += 1
  return value
```

The scanner skips whitespace by testing for digits, so line breaks are harmless. The block size is 128 KiB.

**Sieve and term table.** Builds every answer once before reading the query list.

```nim
proc buildTermTexts(): seq[string] =
  var composite = newSeq[bool](primeLimit + 1)
  var primes: seq[int] = @[]
  for value in 2 .. primeLimit:
    if not composite[value]:
      primes.add value
      if primes.len >= 3 * termCount:
        break
      var multiple = value * value
      while multiple <= primeLimit:
        composite[multiple] = true
        multiple += value
  result = @[]
  for index in 0 ..< termCount:
    let baseIndex = 3 * index
    let termValue = primes[baseIndex] * primes[baseIndex + 1] + primes[baseIndex + 2]
    result.add $termValue

var termTexts = buildTermTexts()
```

Marking starts at the square of each prime. The loop stops as soon as the last required prime is collected, so no extra sieve work is done.

**Query writer.** Emits the requested prefix of the precomputed strings.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var pos = 0
let caseCount = nextInt(inputData, pos)
var outputBuffer = ""
for _ in 0 ..< caseCount:
  let termIndex = nextInt(inputData, pos)
  for index in 0 ..< termIndex:
    if index > 0:
      outputBuffer.add ' '
    outputBuffer.add termTexts[index]
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
```

The index test places separators between terms only. Reusing `outputBuffer` after each flush keeps memory flat even for large output.

## Complexity

| phase | time | space |
|---|---|---|
| sieve | O(L log log L) with L equal to 351000 | about 351 KB |
| term table | O(10000) multiplications and conversions | about 120 KB |
| query output | O(n) string appends per case | 128 KiB buffer |
| input read | one pass over all lines | input bytes |

| measure | Big O |
|---|---|
| time | O(L log log L + total printed terms) |
| space | O(L + total terms) |

Generating primes again for every case would repeat the sieve many times. Precomputing once makes each case cost only the bytes it prints.
