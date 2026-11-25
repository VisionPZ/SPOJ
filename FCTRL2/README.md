# FCTRL2 — Small factorials (SPOJ)
<https://www.spoj.com/problems/FCTRL2/>

## Problem

The input gives several small positive integers n.
For each, print every digit of n! on its own line.

The first line holds an integer t from 1 to 100. Each of the next t lines holds one integer n from 1 to 100. Print n! on its own line, with no leading zeros.

The judge limits are:

| Item | Value |
| --- | --- |
| Test cases t | 1 to 100 |
| Each n | 1 to 100 |
| Longest answer | 158 digits (100!) |
| Time limit | 1 s |
| Memory limit | 1536 MB |

The fixed upper bound makes one precomputation pass worthwhile.

The sample input reads:

```text
4
1
2
5
3
```

The sample output reads:

```text
1
2
120
6
```

## Idea

Build every factorial once, like filling a multiplication table whose cells you can read later. Store each huge value as a list of base-10^9 limbs, which are ordinary integers holding nine decimal digits each. Multiply the previous list by the next small factor with schoolbook carry propagation. Each precomputation step touches one limb per digit group, and each query only prints a stored list. A fresh multiplication per query would repeat work and could overflow. Takeaway: precompute once, then print the stored result.

## Why It Works

1. A factorial fits in 158 digits, so 18 limbs of nine digits each hold it.
2. One limb times a factor below 100, plus a carry, stays far below 2^63.
3. Schoolbook multiplication carries the overflow into the next limb, exactly as paper arithmetic carries into the next column.
4. Printing writes the most significant limb as is and pads every lower limb to nine digits with leading zeros.
5. The whole table is built before any query, so query order cannot change the work.

The table defines the terms used in the multiplication.

| Term | Meaning |
| --- | --- |
| limb | one integer storing nine decimal digits |
| baseValue | 10^9, the radix of each limb |
| product | limb times factor plus carry |
| carry | product div baseValue, passed to the next limb |

These four terms describe one multiplication pass.

A script replayed the precomputation. The first values fit in one limb.

| Value | Limb list (base 10^9) | Printed |
| --- | --- | --- |
| 1! | [1] | 1 |
| 2! | [2] | 2 |
| 3! | [6] | 6 |
| 4! | [24] | 24 |
| 5! | [120] | 120 |

The sample asks for 5! and prints 120, which matches the table.

## Code

**Constants and writer.** The code fixes the limb radix and buffers decimal output.

```nim
const baseValue = 1000000000
const limbWidth = 9

var outputBuffer = ""

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

`appendNumber` writes the leading limb without leading zeros. The digit loop runs once per decimal digit. One output buffer collects every answer line. The helper cost is linear in the digits printed.

**Limb printing and multiplication.** These two procedures restore padding and carry the product forward.

```nim
proc appendLimb(limb: int, width: int) =
  var digits: seq[int]
  var rest = limb
  for _ in 0 ..< width:
    digits.add(rest mod 10)
    rest = rest div 10
  for i in countdown(digits.len - 1, 0):
    outputBuffer.add((digits[i] + '0'.ord).chr)

proc multiplyLimbList(limbs: seq[int], factor: int): seq[int] =
  var answer: seq[int]
  var carry = 0
  for i in 0 ..< limbs.len:
    let product = limbs[i] * factor + carry
    answer.add(product mod baseValue)
    carry = product div baseValue
  while carry > 0:
    answer.add(carry mod baseValue)
    carry = carry div baseValue
  return answer
```

`appendLimb` emits exactly nine digits, including leading zeros. `multiplyLimbList` walks each limb once and appends a new one only when a carry remains. The product stays inside a signed 64-bit integer. Both loops are linear in the limb count.

**Precomputation and driver.** The table is built from 1! through 100!, then the queries print it.

```nim
var factorials: seq[seq[int]]
var firstLimbs: seq[int]
firstLimbs.add(1)
factorials.add(firstLimbs)
for value in 1 .. 100:
  factorials.add(multiplyLimbList(factorials[^1], value))

proc appendBigNumber(limbs: seq[int]) =
  appendNumber(limbs[^1])
  for i in countdown(limbs.len - 2, 0):
    appendLimb(limbs[i], limbWidth)

proc parseCount(text: string): int =
  var value = 0
  for c in text:
    if c in {'0' .. '9'}:
      value = value * 10 + (c.ord - '0'.ord)
  return value

var line = ""
while stdin.readLine(line):
  let caseCount = parseCount(line)
  for _ in 0 ..< caseCount:
    discard stdin.readLine(line)
    let number = parseCount(line)
    appendBigNumber(factorials[number])
    outputBuffer.add('\n')

stdout.write(outputBuffer)
```

The precomputation loop has a fixed bound of 100 steps. `appendBigNumber` indexes the stored list by the requested n. Parsing ignores non-digit characters, so blank lines need no branch. The final write emits the whole output buffer at once.

## Complexity

| Phase | Time | Space |
| --- | --- | --- |
| Precompute 100 factorials | O(sum of limb counts) | O(digits of 100!) |
| Print one answer | O(digits of n!) | O(1) extra |
| Final write | O(total output bytes) | one buffer |

Most work happens before the first query.

The precomputation runs a fixed 100 times regardless of the queries.

| Measure | Bound |
| --- | --- |
| Precomputation | O(100 · 18) limb operations |
| Per query | O(158) characters at most |
| Total space | O(158) limbs and digits |

A fresh multiplication for every query would redo the same work and could overflow a machine integer.
