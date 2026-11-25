# AVRG — Simple Average (SPOJ)

<https://www.spoj.com/problems/AVRG/>

## Problem

A shopper buys six different products and only finishes choosing when their prices add up to an exact whole-number average. Given the six prices, print that average.

The input has exactly six lines, each holding one integer price. The output has one integer: the average of the six prices.

| Item | Bound |
|---|---|
| Prices read | 6 |
| Average | guaranteed to be a whole number |
| Judge limit | 1000 ms |
| Memory | 1536 MB |

No test count appears, so the program reads six numbers and stops.

The sample input:

```
3
7
5
2
1
6
```

The sample output:

```
4
```

## Idea

Like splitting a restaurant bill evenly among six friends, add the six amounts and divide the total by six. The statement promises the answer has no fractional part, so integer division is exact.

The scanner reads one integer at a time from the input string. A running total in `int64` avoids overflow on large prices, and one division produces the answer.

Each price costs one scan and one addition, so the whole case is constant work.

## Why It Works

1. The input contains six prices, one per line, so a loop with six steps reads them all.
2. Adding the six values gives a total that is divisible by six by problem guarantee.
3. Integer division of that total by six returns the exact average.
4. `int64` holds the total even when each price is close to a billion.

| Term | Meaning |
|---|---|
| `totalCost` | running sum of the six prices |
| `productIndex` | loop counter from zero to five |
| `nextInt` | hand scanner that skips non-digits |

The guarantee on divisibility removes any need for floating point.

A script-generated view of the sample sum:

```
prices  3 + 7 + 5 + 2 + 1 + 6
total   24
average 24 div 6 = 4
```

The last row is the sample output.

## Code

**Input and scanner.** All lines enter one string and the scanner walks it by index.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value
```

`inputLine` is reused for every row, so only `inputData` grows. The minus sign never occurs here because prices are costs.

**Output buffer.** One buffer collects the single answer line.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The flush rule is shared with every other solution in this set. The final write handles the unused tail.

**Six prices.** The loop reads six values and divides once.

```nim
var totalCost: int64 = 0
for productIndex in 0 ..< 6:
  totalCost += int64(nextInt(inputData, scanPos))
appendOutput($(totalCost div 6))
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The bound six is fixed by the statement. The final write flushes the small remaining buffer.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over six lines | input bytes |
| Core work | six additions and one division | one integer |
| Output | one write | one buffer |

The work does not grow with any external parameter.

| Measure | Big O |
|---|---|
| Time | O(1) |
| Space | O(1) beyond the input string |

A floating-point average would add conversion work without changing the guaranteed answer.
