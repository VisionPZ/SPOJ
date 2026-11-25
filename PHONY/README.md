# PHONY — Phony Primes (SPOJ)
<https://www.spoj.com/problems/PHONY/>

## Problem

A buggy generator reports composite numbers as primes. Its mistakes are odd, squarefree numbers with at least three prime factors, and every factor p satisfies p − 1 dividing N − 1.

Given about 2000 intervals, list every such fake prime in each one. These numbers are Carmichael numbers in number theory; the example 561 = 3 × 11 × 17 is the smallest.

Input: each line holds Nmin and Nmax; a line `0 0` ends the input. Output: the fake primes in increasing order, one per line, or the single word `none`.

These are the bounds and the judge limits:

| Item | Bound |
| --- | --- |
| Interval endpoints | 1 ≤ Nmin < Nmax < 2³¹ |
| Interval width | Nmax − Nmin < 10⁶ |
| Test cases | about 2000 |
| Source size | 2000 bytes |
| Time limit | 1200 ms |
| Memory limit | 1536 MB |

The sample asks about two intervals:

```
10 2000
20000 21000
0 0
```

```
561
1105
1729
none
```

The first interval contains three fake primes; the second contains none.

## Idea

Mark numbers by a congruence for each small prime, then test only the marked ones. Picture walking down a street. Put a sticker on each door whose number fits a pattern for prime 3, then prime 5. Doors with three or more distinct stickers are the suspects.

The program sieves primes up to 46341, the square root of 2³¹. For each odd prime p, it steps through numbers N with N ≡ p mod p(p − 1). That single pattern enforces both p | N and p − 1 | N − 1.

Each mark raises a factor counter and multiplies a product of distinct factors. A number qualifies when it has at least three factors, is squarefree, and any leftover cofactor is prime and satisfies the same divisibility rule.

Sieving costs O(√2³¹ log log) once. A query costs O(π(√Nmax) × steps + width), with width under 10⁶. Trial division on every number would cost O(width × √Nmax).

Takeaway: congruence stepping visits only plausible candidates, so a million-wide window stays cheap.

## Why It Works

Four facts make the scan correct.

1. If p | N and p − 1 | N − 1, then N ≡ p mod p(p − 1). The number p itself is 0 mod p and 1 mod p − 1, and adding p(p − 1) preserves both conditions.
2. Starting the step at max(p², low) skips p itself and all smaller multiples where p would not be a proper factor. The first legal value is computed with one ceiling division.
3. A marked number collects each distinct prime factor once in `prods` and once in `marks`. The bit 128 in `marks` records that p² divides N, which rejects non-squarefree numbers.
4. After dividing out the collected product, the leftover `rest` must be prime and satisfy (N − 1) mod (rest − 1) = 0. With at least three factors total, the number is a phony prime.

These are the pieces of one query:

| Term | Meaning |
| --- | --- |
| `limit` | 46341, the largest prime needed for the sieve |
| `step` | p × (p − 1), the spacing of candidates for prime p |
| `marks[index]` | factor count for a value, with bit 128 set when not squarefree |
| `prods[index]` | product of the distinct factors found |
| `rest` | leftover cofactor after dividing out that product |
| `total` | number of distinct prime factors |

A script checks the three sample numbers:

```
561 = 3*11*17; squarefree=True; k=3; (N-1)/(p-1)=[280, 56, 35]
1105 = 5*13*17; squarefree=True; k=3; (N-1)/(p-1)=[276, 92, 69]
1729 = 7*13*19; squarefree=True; k=3; (N-1)/(p-1)=[288, 144, 96]
```

Every quotient is an integer, so each number passes the divisibility rule. The factor count reaches exactly three in each case.

## Code

**Input.** Lines go into one buffer, and a small scanner returns integers.

```nim
var data = ""
var row = ""
while readLine(stdin, row):
  data.add row
  data.add '\n'
var pos = 0
proc getNum(): int =
  while pos < data.len and data[pos] < '0': pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value
```

The scanner advances `pos` past non-digits, then builds each number. The `0 0` terminator is handled in the main loop. Cost is one pass over the input.

**Sieve.** A small sieve lists primes up to the square root bound.

```nim
const limit = 46341
var flags = newSeq[bool](limit + 1)
var primes: seq[int] = @[]
for i in 2..limit:
  if not flags[i]:
    primes.add i
    if i * i <= limit:
      var j = i * i
      while j <= limit:
        flags[j] = true
        j += i
```

Crossing off starts at i × i, so each composite is marked once. The bound 46341 exceeds √2³¹, enough for every factorization below 2³¹. This runs once at O(limit log log limit).

**Primality.** The leftover cofactor needs a prime check.

```nim
proc isPrime(value: int): bool =
  for prime in primes:
    if prime * prime > value: break
    if value mod prime == 0: return false
  return value > 1
```

Trials stop at √value, so at most a few dozen divisions occur. The `value > 1` guard rejects zero and one. Cost is O(π(√value)) per candidate that survives marking.

**Query scan.** Each interval is marked, checked, and printed.

```nim
var marks = newSeq[byte](1100000)
var prods = newSeq[int](1100000)
var ob = ""
while true:
  let low = getNum()
  let high = getNum()
  if low + high == 0: break
  let width = high - low + 1
  if width > marks.len:
    marks.setLen width
    prods.setLen width
  for prime in primes:
    if prime == 2: continue
    if prime * prime > high: break
    let step = prime * (prime - 1)
    var value = prime + ((max(prime * prime, low) - prime + step - 1) div step) * step
    while value <= high:
      let index = value - low
      prods[index] = if marks[index] == 0: prime else: prods[index] * prime
      marks[index] += 1
      if (value div prime) mod prime == 0: marks[index] = marks[index] or 128'u8
      value += step
  var found = false
  for index in 0..<width:
    let mark = int(marks[index])
    marks[index] = 0
    if mark < 2 or mark > 127: continue
    let value = low + index
    let rest = value div prods[index]
    var total = mark
    if rest > 1:
      total += 1
      if (value - 1) mod (rest - 1) != 0 or not isPrime(rest): continue
    if total < 3: continue
    ob.add $value
    ob.add '\n'
    if ob.len >= (1 shl 18):
      stdout.write ob
      ob.setLen 0
    found = true
  if not found: ob.add "none\n"
stdout.write ob
```

The ceiling division computes the first candidate at or above `max(prime × prime, low)`. Both arrays grow only when a wider interval appears. The second loop clears every `marks` entry, so no state leaks into the next case. Output is flushed in blocks.

## Complexity

Sieving runs once; each interval costs marking plus a width scan.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | O(total tokens) | O(input size) |
| Prime sieve | O(46341 log log 46341) | O(46341) |
| Marking one interval | O(π(√Nmax) + marked values) | O(width) |
| Decision scan | O(width) | O(width) |
| Output | O(results) | O(block size) |

The marking and decision passes dominate, with O(width) work per interval.

| Measure | Big O |
| --- | --- |
| Precomputation | O(√Nmax log log Nmax) |
| Time per interval | O(width + marked values) |
| Working space | O(width) |

Trial dividing every value in the window costs O(width × √Nmax), far more than stepping through congruence classes.
