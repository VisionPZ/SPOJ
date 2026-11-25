# FCTRL — Factorial (SPOJ)
<https://www.spoj.com/problems/FCTRL/>

## Problem

A phone-network technician visits radio stations, so he studies how fast a factorial grows. He records how many zeros sit at the end of N! for many values of N.

The first line holds one positive integer T. Then T lines each hold one positive integer N. Print one non-negative integer Z(N) per line, where Z(N) counts trailing zeros in decimal N!.

The judge limits are:

| Item | Value |
| --- | --- |
| Test cases T | about 100000 |
| Each N | 1 to 1000000000 |
| Time limit | 6 s |
| Memory limit | 1536 MB |

The large case count puts a premium on cheap work per query.

The sample input reads:

```text
6
3
60
100
1024
23456
8735373
```

The sample output reads:

```text
0
14
24
253
5861
2183837
```

## Idea

Count the fives hidden in the factorial, like counting matching pairs of socks in a drawer. A trailing zero needs one factor 2 and one factor 5, and every factorial holds more twos than fives. The program adds N div 5, N div 25, and each higher power of five that still fits. This divisor-count trick costs a handful of divisions per query. Building N! would cost O(N) work and overflow immediately. Each query uses at most 13 terms, so input and output dominate the run. Takeaway: count factors of five, never the factorial itself.

## Why It Works

1. A decimal trailing zero needs one factor pair (2, 5) in the product.
2. Among 1 through N, twos outnumber fives, so fives set the number of pairs.
3. Every multiple of 5 supplies one five, every multiple of 25 supplies a second one, and so on.
4. Summing N div 5^k over all powers of five counts each factor of five exactly once.
5. For N up to 10^9 the sum ends after 13 terms, because 5^13 exceeds the bound.

The table names each term in the sum.

| Term | Meaning |
| --- | --- |
| Z(N) | count of zeros at the end of N! |
| divisor | current power of five |
| N div divisor | multiples of that power not above N |
| zeros | running sum of those counts |

These four quantities drive the division loop.

A script computed the breakdown for N = 60.

| Divisor | 5 | 25 | 125 |
| --- | --- | --- | --- |
| N div divisor | 12 | 2 | 0 |
| Running sum | 12 | 14 | 14 |

The program prints 14, which matches the second sample line.

## Code

**Helpers.** The constants, parsers, and output writer prepare one buffered answer stream.

```nim
const flushBlockBytes = 1 shl 19

var line = ""
var outputBuffer = ""

proc flushBlock() =
  if outputBuffer.len >= flushBlockBytes:
    stdout.write(outputBuffer)
    outputBuffer.setLen(0)

proc parseCount(text: string): int =
  var value = 0
  for c in text:
    if c in {'0' .. '9'}:
      value = value * 10 + (c.ord - '0'.ord)
  return value

proc appendNumber(value: int) =
  if value == 0:
    outputBuffer.add('0')
  else:
    var digits: seq[int]
    var rest = value
    while rest > 0:
      digits.add(rest mod 10)
      rest = rest div 10
    for i in countdown(digits.len - 1, 0):
      outputBuffer.add((digits[i] + '0'.ord).chr)
```

`flushBlockBytes` sets a 512 KiB ceiling on buffered output. `parseCount` reads only digit characters, so blank lines need no special case. `appendNumber` writes the answer without a per-digit stream write. The helper cost is linear in the digits written.

**Main loop.** The driver reads the case count, then counts fives for every number.

```nim
while stdin.readLine(line):
  let caseCount = parseCount(line)
  for _ in 0 ..< caseCount:
    discard stdin.readLine(line)
    let number = parseCount(line)
    var zeros = 0
    var divisor = 5
    while divisor <= number:
      zeros = zeros + number div divisor
      let nextDivisor = divisor * 5
      if nextDivisor < divisor:
        break
      divisor = nextDivisor
    appendNumber(zeros)
    outputBuffer.add('\n')
    flushBlock()

if outputBuffer.len > 0:
  stdout.write(outputBuffer)
```

The inner loop runs once per power of five up to N. The overflow guard stops when the next power wraps below the current one. Each iteration adds one division and one comparison. The final write flushes any bytes below the block size.

## Complexity

| Phase | Time | Space |
| --- | --- | --- |
| Read one query | O(bytes in its line) | one line |
| Count fives | O(log N) | O(1) |
| Append and flush | O(digits of answer) | one block |

The division loop stays tiny for every query.

Each query touches only a few divisions, so the loop is cheap.

| Measure | Bound |
| --- | --- |
| Per query | O(log N) |
| All T queries | O(T log N + input bytes) |
| Extra space | O(1) plus the flush block |

The total stays linear in the input size. A program that builds each factorial would use O(N) work per query and overflow a machine integer almost at once.
