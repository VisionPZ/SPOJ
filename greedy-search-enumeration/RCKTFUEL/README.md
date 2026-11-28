# RCKTFUEL — Getting a rocket off the ground (SPOJ)
<https://www.spoj.com/problems/RCKTFUEL/>

## Problem

A rocket and its payload have a total weight W. Each unit of weight needs one quarter of a unit of fuel. The fuel adds weight, which needs more fuel, and that fuel adds weight again. Report the whole number of fuel units needed to lift everything.

The input holds fewer than 100 integers, one per line. The first is the rocket weight and the rest are payload weights. Print one integer, the required fuel.

The bounds and judge limit are:

| Constraint | Value |
| --- | --- |
| Number of weights | fewer than 100 |
| Weight per line | integer |
| Judge limit | 1000 ms, 1536 MB |

The input count is small, so one pass over the weights is enough.

The sample input and its output follow byte for byte.

```
5 5
```

```
4
```

## Idea

Treat the fuel like a debt that charges interest on itself. Every quarter of weight creates another quarter of fuel, yet the whole endless chain settles on one simple total. Add the weights, then take one third of the sum.

Let F be the total fuel and W the total weight. The first round needs W/4. The fuel already counted weighs F, so it needs F/4 more. That gives F = W/4 + F/4, hence 3F = W and F = W/3. Fuel comes in whole units, so round up to `(W + 2) div 3`. Simulating every round would take many steps for a large W, while the closed form takes one division.

## Why It Works

1. Every unit of weight, including fuel weight, asks for one quarter of a unit of fuel.
2. Writing the endless sum as F = W/4 + F/4 captures all later rounds at once.
3. Rearranging gives 3F = W, so the exact real-valued fuel is W/3.
4. Whole fuel units require the ceiling, written as `(totalWeight + 2) div 3`.
5. Adding all input lines first gives W, because fuel is shared by the whole load.

The main quantities are:

| Term | Meaning |
| --- | --- |
| `totalWeight` | sum of the rocket and payload weights |
| `fuelRequired` | ceil of `totalWeight` divided by three |
| `weight` | one integer read from a line |

These terms show that one sum and one division decide the answer.

The oracle simulates the fuel chain with exact fractions. It prints these numbers for the two samples:

```
5 + 5 = 10
10 / 3 = 3.333... -> 4
1255 + 234 + 12555 + 45322342 + 32 = 45336418
45336418 / 3 = 15112139.333... -> 15112140
```

Both rounded answers match the published sample outputs.

## Code

**Whole-stream input and hand scanner.** The reader stores every line in one string, and the scanner skips whitespace between integers.

```nim
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
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value
```

`nextInt` skips non-digits before each value. Digit folding uses `int(data[pos]) - 48`. One string keeps parsing independent of line breaks.

**Output buffer.** The writer collects text and flushes whole blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`appendOutput` writes 131072-byte blocks. The answer still passes through the same buffer.

**Weight sum, closed form, and final write.** The loop reads every weight, then one division gives the fuel.

```nim
var totalWeight: int64 = 0
while scanPos < inputData.len:
  let weight = nextInt(inputData, scanPos)
  totalWeight = totalWeight + int64(weight)

let fuelRequired = (totalWeight + 2) div 3

appendOutput($fuelRequired)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

`totalWeight` is int64 to hold a long sum. Adding two before dividing builds the ceiling for positive weights. One formatted line is written at the end.

## Complexity

The cost comes from reading the weights and writing one answer.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | one pass over all lines | one input string |
| Weight sum | one addition per integer | one accumulator |
| Output | one line | block buffer |

Under 100 weights keep the sum and output work tiny.

| Measure | Big O |
| --- | --- |
| Time | O(k) for k input weights |
| Space | O(n) for the input string |

Simulating each fuel round would need O(log W) terms per case. The closed form replaces all those terms with one division.
