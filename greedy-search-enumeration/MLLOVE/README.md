# MLLOVE — Masud and Layla love story (SPOJ)

<https://www.spoj.com/problems/MLLOVE/>

## Problem

Layla walks indices 1, 1+k, 1+2k, 1+3k, ... forever. The gift at index i costs i mod n. She buys each distinct price only once. Add up the distinct prices.

The input is one line with n and k, where 1 ≤ n ≤ 10^9 and 1 ≤ k ≤ 10^9. The output is the total cost.

| item | bound |
|---|---|
| n, k | 1 ≤ n, k ≤ 10^9 |
| output | one integer |
| judge limit | 1000 ms, 1536 MB |

The walk visits only a few residues, so a closed formula replaces the endless loop.

Sample input:

```
6 3
```

Sample output:

```
5
```

## Idea

Walking around a clock with a fixed step lands only on marks that share a starting remainder. Stepping by k modulo n reaches exactly the n/g residues congruent to 1 modulo g, where g is gcd(n, k).

When g = 1 those residues are everything, so the sum is 0 + 1 + ... + (n-1). Otherwise the visited prices are 1, 1+g, 1+2g, ... up to 1+(np-1)g with np = n/g, an arithmetic progression that never wraps. Its sum is np + g·np·(np-1)/2.

Takeaway: the walk visits a coset, so count and sum it by formula.

## Why It Works

1. Adding k repeatedly changes the residue by k, so all visited residues are 1 plus multiples of g.
2. Every such residue is reached because k/g is invertible modulo n/g.
3. There are exactly n/g of them.
4. For g ≥ 2 the largest one, 1+(np-1)g = 1+n-g, is below n, so no wraparound hides a term.
5. For g = 1 the set is all residues 0..n-1, whose sum is n(n-1)/2.
6. Both sums are closed forms, so the answer needs no iteration.

For the sample, n = 6 and k = 3 give g = 3 and np = 2, so the prices are 1 and 4 and the total is 5.

The g = 1 branch matters because the progression then wraps: 1+(n-1)·1 = n becomes 0, and the plain progression formula would overcount.

## Code

**Input and scanning.** The hand reader loads the file and parses 64-bit values.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - 48)
    pos += 1
  return value
```

The scanner skips spaces and newlines.
Every value is positive, so no minus branch is needed.
`int64` keeps the products exact.

**Greatest common divisor.** The Euclidean loop finds the step size of the coset.

```nim
proc gcdValues(firstValue, secondValue: int64): int64 =
  var larger = firstValue
  var smaller = secondValue
  while smaller != 0:
    let remainder = larger mod smaller
    larger = smaller
    smaller = remainder
  return larger
```

Each turn replaces the pair with a smaller one.
The last nonzero value is the gcd.

**Buffered output.** One string collects the answer line.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Large outputs flush in blocks.
One final write closes the remaining text.

**Closed form.** The two branches cover wrap and no-wrap cases.

```nim
let moduloBase = nextInt(inputData, scanPos)
let visitStride = nextInt(inputData, scanPos)
let commonStep = gcdValues(moduloBase, visitStride)
var totalCost: int64 = 0
if commonStep == 1:
  totalCost = moduloBase * (moduloBase - 1) div 2
else:
  let distinctCount = moduloBase div commonStep
  totalCost = distinctCount + commonStep * distinctCount * (distinctCount - 1) div 2

appendOutput($totalCost)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The first branch sums all residues 0..n-1.
The second sums the progression 1, 1+g, ... without wraparound.
Both finish in constant time.

## Complexity

The program runs one gcd and a few multiplications.

| phase | time | space |
|---|---|---|
| read input | one pass over the file | one string |
| gcd | Euclid steps | none |
| output | one line | one block buffer |

| measure | Big O |
|---|---|
| time | O(log min(n, k)) |
| space | O(1) |

Simulating the walk would loop up to n/g times, far too many for 10^9.

Takeaway: number theory turns an infinite walk into one line of arithmetic.
