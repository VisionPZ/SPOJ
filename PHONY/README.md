## Problem

Read pairs `Nmin Nmax` until `0 0`. For each pair, print every phony prime in the range, one per line. A phony prime is odd and squarefree, with at least three distinct prime factors. For each factor `p`, the value `p - 1` divides `N - 1`. Print `none` when the range holds no phony prime.

| Item | Bound |
| --- | --- |
| Test cases | about 2000 |
| Range width | `Nmax - Nmin < 10^6` |
| Range top | `Nmax < 2^31` |
| Time limit | 1200 ms |
| Memory limit | 1536 MB |
| Source limit | 2000 B |

The source ceiling rules out a stored table of answers.

## Idea

The program marks only numbers that can be phony multiples of a small prime. For a phony prime `n` and a prime factor `p`, the value `n` equals `p` plus a multiple of `p * (p - 1)`. Each prime therefore gives one sparse arithmetic progression instead of all of its multiples. The sieve counts factors on those positions, and one pass over the window finishes the test.

Marking touches about 0.3 times the window width. The final scan touches the window width once.

## Why It Works

Write `n = p * k` for a prime factor `p`. Now `p` is one more than a multiple of `p - 1`. The value `n - 1` leaves the same remainder as `k - 1` modulo `p - 1`.

The congruence gives the marker step:

```
n = p * k
n - 1 = p * k - 1 = k - 1  (mod p - 1)
k = 1 + t * (p - 1)
n = p + t * p * (p - 1)
```

The step `p * (p - 1)` replaces the usual step `p`.

A square factor is caught when `k` is a multiple of `p`. After the sieve, the multiplied primes divide `n`. The leftover is one or a single prime, since two primes above the square root would multiply past the range top. That leftover must divide `n - 1` after subtracting one, and it must be prime. Three factors in total finish the test.

A script checked the first phony prime:

```
p = 3  step = 6   progression 3, 9, 15, ..., 561  hit
p = 11 step = 110 progression 11, 121, 231, ..., 561  hit
p = 17 step = 272 progression 17, 289, 561  hit
marked product = 561, leftover = 1, factors = 3
```

All three prime factors land on their own progressions, and the leftover is one.

## Code

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

The scanner skips every non-digit byte and stops at the `0 0` pair. It reads the whole stream once. The cost is one pass over the input bytes.

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

The sieve runs over candidates up to the square root of the range top. The inner loop starts at the square of the prime. The table serves both the window sieve and the leftover primality test.

```nim
proc isPrime(value: int): bool =
  for prime in primes:
    if prime * prime > value: break
    if value mod prime == 0: return false
  return value > 1
```

Trial division stops at the square root of the value. The return checks the value itself, so one is not prime. The loop uses the stored prime table.

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
```

The outer loop stops at primes whose square passes `high`. Skipping prime two avoids marking even numbers. The marker starts at the first progression value inside the window, and bit seven flags a square factor. The cost is about 0.3 marks per window position.

```nim
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

The scan clears each mark as it reads it, so the next case needs no clearing pass. A mark below two or with bit seven set cannot pass. The last check rejects a composite leftover, and the buffer flushes in blocks. The cost is one pass over the window.

## Complexity

The prime sieve takes `O(L log log L)` time and `O(L)` memory for `L = 46341`.

For a window of width `W`, marking takes `sum(W / (p * (p - 1)))` steps over odd primes, which is `O(W)`. The final scan takes `O(W)` time and `O(W)` scratch memory.

Total time is `O(L log log L + sum of all W)`. Total memory is `O(L + maximum W)`.

Factoring every odd number in every window by trial division would take `O(sum of W times sqrt of the range top)` time.
