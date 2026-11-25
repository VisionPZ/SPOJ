# CRAZYSK — Crazy Shopkeeper (SPOJ)

<https://www.spoj.com/problems/CRAZYSK/>

## Problem

A shopper starts with one card for each item bought. Each trade spends a fixed bundle of cards and returns one card with a new item. Report the largest item count after every possible trade.

Input starts with a positive integer T below 100. Each following line holds two positive integers X and N, with 1 < X <= 2^64 and 1 < N <= X. Output one total per line in input order.

| item | bound |
|---|---|
| test cases T | 1 to 99 |
| bought items X | 2 to 2^64 |
| cards per trade N | 2 to X |
| judge limit | 1000 ms, 1536 MB |

The answer can reach about twice 2^64, so the final sum needs decimal string arithmetic.

The sample input:

```
5
15 3
2147483647 2
34 3
231 2
5 2
```

The sample output:

```
22
4294967293
50
461
9
```

## Idea

Each trade keeps one card and spends the rest, like paying a toll with a bundle of tickets and getting one ticket back. The net card loss per trade is N - 1. Divide the starting stock minus one by that loss to count the trades, then add the count to X. A replay would loop once per trade; the division jumps straight to the last one. Decimal string addition avoids overflow when the total passes the 64-bit ceiling. One division and one short string addition settle each case.

## Why It Works

1. A shopper begins with X cards and X items.
2. A trade spends N cards and returns one card, so cards drop by N - 1 and items rise by one.
3. After k trades the card stock equals X - k * (N - 1).
4. One more trade needs at least one card left, which holds when k <= (X - 1) / (N - 1).
5. Integer division gives the largest valid k, and the answer equals X + k.

| term | meaning |
|---|---|
| `itemsBought` | starting items and cards, called X in the statement |
| `returnCards` | cards spent per trade, called N in the statement |
| `extraItems` | largest number of trades, computed by integer division |
| `addDecimalStrings` | column addition of two decimal strings |

The table names every value used in the calculation.

A script trace of the first sample case with the generator's simulation:

```
start    items=15 cards=15
trade 1  items=16 cards=13
trade 2  items=17 cards=11
trade 3  items=18 cards=9
trade 4  items=19 cards=7
trade 5  items=20 cards=5
trade 6  items=21 cards=3
trade 7  items=22 cards=1
stop     cards=1 is below N=3
```

The trace ends at 22 items, which matches the first sample answer.

No rounding applies here. The only guard is the decimal sum, which handles totals above unsigned 64-bit range.

## Code

**Input and scanner.** The reader loads all lines and parses unsigned 64-bit values by hand.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextUInt(data: string, pos: var int): uint64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value: uint64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * uint64(10) + uint64(int(data[pos]) - 48)
    pos += 1
  return value
```

The scanner skips separators and accumulates digits in `uint64`.
It handles the full X upper bound without a signed conversion.
The scan position advances once per number.

**Output and decimal addition.** Column addition avoids an overflowing machine integer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc addDecimalStrings(left: string, right: string): string =
  var leftPos = left.len - 1
  var rightPos = right.len - 1
  var carry = 0
  var reversedDigits = newSeq[char]()
  while leftPos >= 0 or rightPos >= 0 or carry > 0:
    var sum = carry
    if leftPos >= 0:
      sum = sum + int(left[leftPos]) - 48
      leftPos -= 1
    if rightPos >= 0:
      sum = sum + int(right[rightPos]) - 48
      rightPos -= 1
    reversedDigits.add char(sum mod 10 + 48)
    carry = sum div 10
  var sumText = ""
  for digitIndex in 0 .. reversedDigits.len - 1:
    sumText.add reversedDigits[reversedDigits.len - 1 - digitIndex]
  return sumText
```

The loop runs once per output digit plus any final carry.
It never stores a value larger than nine plus two digits plus a carry.
The buffer flushes in blocks instead of once per line.

**Main loop.** Each case divides once and writes one decimal total.

```nim
let caseCount = int(nextUInt(inputData, scanPos))
for caseNumber in 1 .. caseCount:
  let itemsBought = nextUInt(inputData, scanPos)
  let returnCards = nextUInt(inputData, scanPos)
  let extraItems = (itemsBought - uint64(1)) div (returnCards - uint64(1))
  appendOutput(addDecimalStrings($itemsBought, $extraItems))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

`extraItems` uses `uint64` division, which fits because both operands fit the type.
The loop runs exactly T times.
A final flush writes the remaining buffer after the loop.

## Complexity

Each case costs a fixed number of digit operations.

| phase | time | space |
|---|---|---|
| input read | one pass over the input bytes | one input string |
| division | one 64-bit division per case | constant |
| output | one decimal sum per case | block buffer |

The phases are constant time per case apart from input size.

| measure | Big O |
|---|---|
| time | O(T * D) |
| space | O(D) |

Here D is the number of decimal digits in one answer, at most 21.

Replaying each trade would take O(X) time per case and fail near 2^64. Division replaces the replay with one operation and keeps every case fast.
