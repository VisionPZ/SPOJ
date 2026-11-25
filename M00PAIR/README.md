# M00PAIR — 0 0 Pairs (SPOJ)

<https://www.spoj.com/problems/M00PAIR/>

## Problem

A sequence starts as the single digit 1. Each step replaces every 0 by 10 and every 1 by 01, and we count the adjacent zero pairs after n steps. The input lists step counts in any order, so each count gets its own answer.

The input is a stream of step counts separated by whitespace. Each count lies between 1 and 999. Print one decimal count per input value, in the same order, on its own line.

| item | bound |
|---|---|
| step count n | 1 to 999 |
| input order | arbitrary, values may repeat |
| output size | about 1.45 MB in the largest case |
| judge limit | 1000 ms, 1536 MB |

The output size drives the design, not the step count.

Sample input:

```
1
2
3
4
5
```

Sample output:

```
0
1
1
3
5
```

## Idea

Think of each digit as a domino that flips into a two-character tile, so zero pairs can only appear where two tiles touch. The recurrence a(n) = a(n-2) + 2^(n-3) counts those touching edges with ordinary integer arithmetic. We precompute all 999 answers once as big integers, then answer every query by table lookup. Building the string for each query would need 2^n characters and cannot finish.

Precomputation pays for itself as soon as a second query arrives.

## Why It Works

1. Each digit becomes one tile: 0 becomes 10 and 1 becomes 01.
2. No tile holds two zeroes, so every zero pair crosses a tile boundary.
3. A crossing reads 00 when the left tile is 10 and the right tile is 01.
4. Those tiles come from a 01 pair in the previous sequence.
5. Each rewrite puts one zero in every tile, so half of all digits are zeroes.
6. Counting 01 pairs gives one power of two plus the earlier zero-pair count.
7. Hence a(n) equals a(n-2) plus 2 raised to n minus three, for n at least 3.

| term | meaning |
|---|---|
| `answerTable` | precomputed decimal answer for one step count |
| `powerOfTwo` | running value of two raised to the step count minus three |
| `evenAnswer` | most recent answer with an even step count |
| `oddAnswer` | most recent answer with an odd step count |

The two answer slots separate the even and odd halves of the recurrence.

A script traces the first five sequences and their zero-pair counts:

```
steps 1 -> 01             -> 0 pairs
steps 2 -> 1001           -> 1 pair
steps 3 -> 01101001       -> 1 pair
steps 4 -> 1001011001101001 -> 3 pairs
steps 5 -> 01101001100101101001011001101001 -> 5 pairs
```

The trace matches the sample output line for line.

Every value is a whole number, so no rounding occurs. Decimal digits are stored least significant first, which makes carry propagation local.

## Code

**Input and hand scanner.** The reader loads stdin once and skips all non-digit separators.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const maxSteps = 999

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

The loop covers every line until stdin ends.
The scanner builds each value from single digits.
It needs no sign branch because all inputs are positive.

**Big integer helpers.** Each answer is a list of decimal digits with a small carry.

```nim
proc addDigits(target: var seq[int], source: seq[int]) =
  var carry = 0
  var digitIndex = 0
  while digitIndex < source.len:
    if digitIndex >= target.len:
      target.add 0
    let digitTotal = target[digitIndex] + source[digitIndex] + carry
    target[digitIndex] = digitTotal mod 10
    carry = digitTotal div 10
    digitIndex += 1
  while carry > 0:
    if digitIndex >= target.len:
      target.add 0
    let digitTotal = target[digitIndex] + carry
    target[digitIndex] = digitTotal mod 10
    carry = digitTotal div 10
    digitIndex += 1

proc doubleDigits(target: var seq[int]) =
  var carry = 0
  var digitIndex = 0
  while digitIndex < target.len:
    let digitTotal = target[digitIndex] * 2 + carry
    target[digitIndex] = digitTotal mod 10
    carry = digitTotal div 10
    digitIndex += 1
  if carry > 0:
    target.add carry

proc digitsToString(digits: seq[int]): string =
  var text = ""
  var digitIndex = digits.len
  while digitIndex > 0:
    digitIndex -= 1
    text.add chr(firstDigitValue + digits[digitIndex])
  return text
```

Addition walks only the source digits, then drains any carry.
Doubling walks the target digits once and appends at most one digit.
String conversion reverses the stored digit order.

**Table build and output.** One sweep fills every answer, then each query writes one line.

```nim
var answerTable = newSeq[string](maxSteps + 1)
var powerOfTwo: seq[int] = @[1]
var evenAnswer: seq[int] = @[1]
var oddAnswer: seq[int] = @[0]
answerTable[1] = "0"
answerTable[2] = "1"
for stepCount in 3 .. maxSteps:
  var currentAnswer: seq[int]
  if stepCount mod 2 == 0:
    currentAnswer = evenAnswer
    addDigits(currentAnswer, powerOfTwo)
    evenAnswer = currentAnswer
  else:
    currentAnswer = oddAnswer
    addDigits(currentAnswer, powerOfTwo)
    oddAnswer = currentAnswer
  answerTable[stepCount] = digitsToString(currentAnswer)
  doubleDigits(powerOfTwo)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while scanPos < inputData.len:
  let stepCount = nextInt(inputData, scanPos)
  if stepCount >= 1 and stepCount <= maxSteps:
    appendOutput(answerTable[stepCount])
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The sweep performs one addition and one doubling per step.
The buffer flushes only after many kilobytes accumulate.
A final write emits any remaining bytes.

## Complexity

Precomputation touches each answer once, and queries only read the table.

| phase | time | space |
|---|---|---|
| input read | one pass over tokens | one input string |
| table build | 999 additions of up to 300 digits | 999 answer strings |
| output | one append per query | block buffer |

The table build dominates memory, while output dominates time for large streams.

| measure | Big O |
|---|---|
| time | O(999 d + q) with d answer digits and q queries |
| space | O(999 d) |

Generating each sequence instead would cost O(2^n) time per query.
