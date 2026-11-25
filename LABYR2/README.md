# LABYR2 — Number Labyrinth (SPOJ)

<https://www.spoj.com/problems/LABYR2/>

## Problem

Read numbers written as English words and trace a mouse through a numbered labyrinth. Print the counter value shown when the mouse reaches node 1, or -1 if the counter reaches zero first.

| item | bound |
|---|---|
| each starting value | below 2000000 |
| values per file | until end of input |
| judge limit | 500 ms, 1536 MB |

The counter falls by one on every move. A decision at one node uses the counter before that move.

Sample input:

```
thirteen
fourteen
one-thousand
one-million-three-hundred-and-twenty-five-thousand-nine-hundred-and-seventy-nine
```

Sample output:

```
-1
9
789
1325784
```

## Idea

Reading the map is like following a subway line, with each stop lowering the ticket counter by one. A direct simulation applies the printed rule at the current node, decrements the counter, and moves. Every value below two million takes only a few hundred steps. Translating the words and walking the map are both linear in their input size.

## Why It Works

1. Each node chooses its successor from the counter value before the decrement.
2. The counter then drops by exactly one, independent of the chosen direction.
3. Node 9 remembers whether it was entered from node 8 or from node 0.
4. Reaching node 1 ends the run and displays the counter after the last decrement.
5. Reaching zero ends the run first and produces -1.

The state names below match the source identifiers.

| term | meaning |
|---|---|
| `currentNode` | the node holding the mouse before a move |
| `previousNode` | the node left immediately before, needed only at node 9 |
| `currentValue` | the counter used by the current decision |
| `experimentResult` | the displayed counter, or -1 on failure |

The table replaces the rules with eight explicit cases.

The trace for fourteen, produced by the oracle in gen.py:

| step | node | counter before | next node | counter after |
|---|---|---|---|---|
| 1 | 0 | 14 | 7 | 13 |
| 2 | 7 | 13 | 6 | 12 |
| 3 | 6 | 12 | 4 | 11 |
| 4 | 4 | 11 | 2 | 10 |
| 5 | 2 | 10 | 1 | 9 |

The mouse enters node 1 with counter 9, which matches the sample.

## Code

**Input and decision rules.** The reader loads all lines and the walker applies the node table.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

proc reverseDigits(valueToReverse: int): int =
  var reversedValue = 0
  var remainingValue = valueToReverse
  while remainingValue > 0:
    reversedValue = reversedValue * 10 + remainingValue mod 10
    remainingValue = remainingValue div 10
  return reversedValue

proc countDigits(valueToCount: int): int =
  var digitTotal = 0
  var remainingValue = valueToCount
  while remainingValue > 0:
    digitTotal += 1
    remainingValue = remainingValue div 10
  return digitTotal

proc experimentResult(initialValue: int): int =
  var currentValue = initialValue
  var currentNode = 0
  var previousNode = 0
  while true:
    var nextNode = 0
    case currentNode
    of 0:
      if (currentValue div 100) mod 10 <= 7:
        nextNode = 7
      else:
        nextNode = 9
    of 2:
      case currentValue mod 3
      of 0:
        nextNode = 7
      of 1:
        nextNode = 1
      else:
        nextNode = 4
    of 4:
      if reverseDigits(currentValue) > currentValue:
        nextNode = 6
      else:
        nextNode = 2
    of 6:
      if countDigits(currentValue) mod 2 == 0:
        nextNode = 4
      else:
        nextNode = 7
    of 7:
      let squareValue = int64(currentValue) * int64(currentValue) mod 7
      case squareValue
      of 0:
        nextNode = 2
      of 1:
        nextNode = 6
      of 2:
        nextNode = 8
      of 4:
        nextNode = 0
      else:
        nextNode = 2
    of 8:
      let remainderValue = currentValue mod 5
      if remainderValue == 2 or remainderValue == 3:
        nextNode = 7
      else:
        nextNode = 9
    of 9:
      if previousNode == 8:
        nextNode = 0
      else:
        nextNode = 8
    else:
      nextNode = 0
    currentValue = currentValue - 1
    if currentValue == 0:
      return -1
    previousNode = currentNode
    currentNode = nextNode
    if currentNode == 1:
      return currentValue
```

The square uses int64 to avoid overflow.
The zero check runs before the arrival check.
Node 1 is never asked to choose a direction.

**Word translation.** Each word adds to a partial group or closes a scale.

```nim
proc applyWord(wordText: string, smallerPart: var int, totalValue: var int) =
  case wordText
  of "and":
    discard
  of "zero":
    discard
  of "one":
    smallerPart += 1
  of "two":
    smallerPart += 2
  of "three":
    smallerPart += 3
  of "four":
    smallerPart += 4
  of "five":
    smallerPart += 5
  of "six":
    smallerPart += 6
  of "seven":
    smallerPart += 7
  of "eight":
    smallerPart += 8
  of "nine":
    smallerPart += 9
  of "ten":
    smallerPart += 10
  of "eleven":
    smallerPart += 11
  of "twelve":
    smallerPart += 12
  of "thirteen":
    smallerPart += 13
  of "fourteen":
    smallerPart += 14
  of "fifteen":
    smallerPart += 15
  of "sixteen":
    smallerPart += 16
  of "seventeen":
    smallerPart += 17
  of "eighteen":
    smallerPart += 18
  of "nineteen":
    smallerPart += 19
  of "twenty":
    smallerPart += 20
  of "thirty":
    smallerPart += 30
  of "forty":
    smallerPart += 40
  of "fifty":
    smallerPart += 50
  of "sixty":
    smallerPart += 60
  of "seventy":
    smallerPart += 70
  of "eighty":
    smallerPart += 80
  of "ninety":
    smallerPart += 90
  of "hundred":
    smallerPart = smallerPart * 100
  of "thousand":
    totalValue = totalValue + smallerPart * 1000
    smallerPart = 0
  of "million":
    totalValue = totalValue + smallerPart * 1000000
    smallerPart = 0
  else:
    discard
```

The word "and" adds nothing.
Hundreds scale the partial group.
Thousands and millions close the group into the total.

**Buffered driver.** Whitespace ends a phrase, and each phrase yields one answer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var currentWord = ""
var smallerPart = 0
var totalValue = 0
var phraseHasWords = false
for inputChar in inputData:
  if inputChar >= 'a' and inputChar <= 'z':
    currentWord.add inputChar
  else:
    if currentWord.len > 0:
      applyWord(currentWord, smallerPart, totalValue)
      currentWord.setLen 0
      phraseHasWords = true
    if inputChar == ' ' or inputChar == '\n' or inputChar == '\r' or inputChar == '\t':
      if phraseHasWords:
        let initialValue = totalValue + smallerPart
        appendOutput($experimentResult(initialValue))
        outputBuffer.add '\n'
        totalValue = 0
        smallerPart = 0
        phraseHasWords = false

stdout.write outputBuffer
outputBuffer.setLen 0
```

Hyphens only split words inside one phrase.
Blank lines are skipped because they hold no words.
The final flush writes any buffered answers.

## Complexity

Let S be the number of moves before the mouse stops.

| phase | time | space |
|---|---|---|
| word parse | one pass over the phrase text | one word buffer |
| labyrinth walk | one decision and decrement per move | three integers |
| output | one append per phrase | one block buffer |

The walk dominates, and S stays small for the stated bound.

| measure | Big O |
|---|---|
| time per value | O(S + phrase length) |
| space per value | O(1) beyond the input string |

Trying every possible path would be exponential, while the printed rules determine one path directly.
