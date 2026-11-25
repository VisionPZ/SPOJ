# FINFRAC — Finding Fractions (SPOJ)

<https://www.spoj.com/problems/FINFRAC/>

## Problem

Find the fraction with the smallest denominator strictly between two given fractions, breaking ties with the smallest numerator. Each input line gives one pair of bounds, and the output has one fraction per line.

Input runs to end of file. Each line holds four positive integers `a b c d` with a/b below c/d. Output `p/q` on its own line for every input line.

| Item | Bound |
|---|---|
| Values | 1 to 1000000000 |
| Input form | one quadruple per line until EOF |
| Judge limit | 3000 ms, 1536 MB |

The bound size rules out scanning denominators one by one.

Sample input:

```
1 3 1 2
2 1 3 1
2 1 4 1
1000 1001 1001 1002
```

These four lines give four open intervals.

Sample output:

```
2/5
5/2
3/1
2001/2003
```

Each printed fraction lies strictly inside its interval.

## Idea

Peel off whole numbers like counting floors before looking at the leftover crumbs. If a whole number lies inside the interval, denominator one wins. Otherwise the fractional remainders are flipped, which turns the same task into a smaller one.

The algorithm is the Euclidean-style recursion behind the Stern-Brocot tree, also called continued fraction descent. Each step removes a whole-number part and inverts the remainders, so every recursion costs a few integer divisions. Trying denominators from one upward takes as many steps as the answer's denominator, which reaches a billion here. Each recursive answer then folds back with one addition and one multiplication.

## Why It Works

1. The simplest fraction inside an interval either has a whole part inside it or shares a whole part with both bounds.
2. When an integer lies strictly inside, that integer has denominator one and is minimal.
3. Sharing a whole part means the fractional remainders keep the same order.
4. Inverting positive remainders reverses that order, so the recursive interval stays valid.
5. If a remainder is zero, the nearest unit fraction gives the smallest denominator directly.

| Term | Meaning |
|---|---|
| `lowWhole` | integer part of the lower bound |
| `lowRest` | remainder of the lower bound |
| `highRest` | remainder of the upper bound |
| `chosenDenominator` | smallest denominator for the unit-fraction case |

The terms above are exactly the values the recursion stores.

A trace for the interval (1000/1001, 1001/1002):

```
step 1: both parts 0, invert to (1002/1001, 1001/1000)
step 2: both parts 1, invert to (1000/1, 1001/1)
step 3: interval (1000, 1001) gives 2001/2
unwind: 2003/2001, then 2001/2003
```

The last line matches the sample answer.

## Code

**Input and scanner.** All stdin is read once and parsed by a digit scanner.

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

The scanner ignores the line breaks between quadruples.
Each digit contributes once to the value.

**Buffered output.** Completed lines collect in one string.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes only after many lines.
A single final flush clears the remainder.

**Fraction descent.** The recursion peels whole parts and inverts remainders.

```nim
proc simplestFraction(lowNumerator: int64, lowDenominator: int64,
                      highNumerator: int64, highDenominator: int64): (int64, int64) =
  let lowWhole = lowNumerator div lowDenominator
  let lowRest = lowNumerator mod lowDenominator
  let highWhole = highNumerator div highDenominator
  let highRest = highNumerator mod highDenominator
  if lowWhole + 1 < highWhole:
    return (lowWhole + 1, 1'i64)
  if lowWhole == highWhole:
    if lowRest == 0:
      let chosenDenominator = highDenominator div highRest + 1
      return (lowWhole * chosenDenominator + 1, chosenDenominator)
    let inner = simplestFraction(highDenominator, highRest, lowDenominator, lowRest)
    return (lowWhole * inner[0] + inner[1], inner[0])
  if highRest > 0:
    return (lowWhole + 1, 1'i64)
  if lowRest == 0:
    return (2 * lowWhole + 1, 2'i64)
  let inner = simplestFraction(1, 1, lowDenominator, lowRest)
  return (lowWhole * inner[0] + inner[1], inner[0])
```

Every product stays within 64-bit range.
Each call makes at most one recursive call.
The zero-remainder cases stop the descent.

**Driver.** Quadruples are read until input ends.

```nim
while true:
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  if scanPos >= inputData.len:
    break
  let lowNumerator = int64(nextInt(inputData, scanPos))
  let lowDenominator = int64(nextInt(inputData, scanPos))
  let highNumerator = int64(nextInt(inputData, scanPos))
  let highDenominator = int64(nextInt(inputData, scanPos))
  let answer = simplestFraction(lowNumerator, lowDenominator, highNumerator, highDenominator)
  appendOutput($answer[0] & "/" & $answer[1] & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

No test count appears in the input.
The loop stops once no digits remain.

## Complexity

The descent removes whole parts with a few divisions per level.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | one input string |
| Fraction descent | a few divisions per recursion level | one stack frame per level |
| Output | one write per block | block buffer |

The phase table shows that recursion depth sets the cost.

| Measure | Big O |
|---|---|
| Time | O(number of input values times digits per value) |
| Space | O(recursion depth) |

Scanning denominators costs O(answer denominator), which reaches a billion, while the descent finishes after a handful of divisions.
