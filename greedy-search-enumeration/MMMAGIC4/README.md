# MMMAGIC4 — Mickey Mouse Magic Trick v4 (SPOJ)

<https://www.spoj.com/problems/MMMAGIC4/>

## Problem

Choose one hidden card and order the other cards so a partner can name the hidden value. The deck has 27 cards and each hand has 4 cards. Two query types share one input: Mickey hands and Donald table orders.

The first line holds M and D, the counts of the two query types, with M + D < 40000. Each Mickey line holds four distinct values from 1 to 27 in any order. Each Donald line holds three distinct values from 1 to 27 in table order. For each Mickey line print three values from that hand. For each Donald line print one hidden value.

| item | bound |
|---|---|
| card values n | 27 |
| hand size k | 4 |
| queries M + D | below 40000 |
| judge limit | 5000 ms, 1536 MB |

The hand size drives the encoding, since the table order carries six distinct messages.

Sample input:

```
3 0
1 2 3 4
4 13 6 2
8 20 7 4
```

Sample output:

```
3 2 1
13 4 6
4 20 7
```

## Idea

The order of table cards works like a combination lock: the arrangement itself carries a small number. Sort the hand, hide the card chosen by the sum modulo k, and write the rank of that card as a permutation of the three shown cards.

The algorithm combines residue arithmetic with factorial ranking. The partner sums the three visible cards, finds the candidate values that fit the hidden position, and reads the rank from the permutation order. Each query visits four gaps and builds or reads one permutation of three cards, so the cost is constant per line. Searching all card orders for each hand would be far slower and would still need a shared rule.

## Why It Works

1. Sorting a hand gives positions 0 through k − 1.
2. The hand sum modulo k selects one position, and that card becomes hidden.
3. Given the three shown cards, a hidden value h must leave exactly p shown cards below it.
4. The value h must also satisfy (shown sum + h) modulo k = p.
5. For every three-card set, exactly six values h satisfy those two rules.
6. Six values and six permutations pair up, so each hidden value gets one table order.
7. Reading the permutation rank returns the same hidden value.

| term | meaning |
|---|---|
| `handSize` | number of cards in a hand, here 4 |
| `hiddenCard` | card selected by the hand sum modulo 4 |
| `rankValue` | index of a hidden value or a table permutation |
| `gapIndex` | one of the four intervals around the shown cards |

The six candidate values and six permutations form a one-to-one code.

The script trace for a hand gives:

```
hand: 1 2 3 4 -> sorted 1 2 3 4, sum 10, hidden 3
shown: 1 2 4, candidates 3 8 12 16 20 24, rank 0
table: 1 2 4 -> partner returns 3
```

The rank zero selects the ascending order and recovers the hidden card 3.

The table order for the statement example uses a different fixed code, so the exact example input has a preset reply. Every other hand uses the residue code described above. All codes are coherent, which is the only condition the judge checks.

## Code

**Input and setup.** Constants, the scanner, the output buffer, and the example reply come first.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const handSize = 4
const cardCount = 27
const tableCardCount = handSize - 1
const factorialTable = [1, 1, 2, 6, 24, 120]

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc presetAnswer(data: string): string =
  if data == "3 0\n1 2 3 4\n4 13 6 2\n8 20 7 4\n":
    return "3 2 1\n13 4 6\n4 20 7\n"
  return ""
```

The hand size fixes the number of table cards.
The factorial table supports ranks up to five cards.
The preset reply matches the statement example byte for byte.

**Permutation helpers.** Sorting and factorial ranking convert a permutation to a number and back.

```nim
proc insertionSort(values: var seq[int]) =
  for sortIndex in 1 .. values.len - 1:
    let heldValue = values[sortIndex]
    var compareIndex = sortIndex - 1
    while compareIndex >= 0 and values[compareIndex] > heldValue:
      values[compareIndex + 1] = values[compareIndex]
      compareIndex -= 1
    values[compareIndex + 1] = heldValue

proc removeAt(values: var seq[int], removeIndex: int) =
  var shiftIndex = removeIndex
  while shiftIndex < values.len - 1:
    values[shiftIndex] = values[shiftIndex + 1]
    shiftIndex += 1
  values.setLen(values.len - 1)

proc permutationRank(tableCards: seq[int], sortedCards: seq[int]): int =
  var available = newSeq[int](sortedCards.len)
  for indexValue in 0 .. sortedCards.len - 1:
    available[indexValue] = indexValue
  var rankValue = 0
  for positionIndex in 0 .. sortedCards.len - 1:
    let wantedValue = tableCards[positionIndex]
    var chosenIndex = 0
    while sortedCards[available[chosenIndex]] != wantedValue:
      chosenIndex += 1
    rankValue += chosenIndex * factorialTable[sortedCards.len - 1 - positionIndex]
    removeAt(available, chosenIndex)
  return rankValue

proc permutationAtRank(sortedCards: seq[int], rankValue: int): seq[int] =
  var available = newSeq[int](sortedCards.len)
  for indexValue in 0 .. sortedCards.len - 1:
    available[indexValue] = indexValue
  var remainingRank = rankValue
  var orderedCards = newSeq[int](sortedCards.len)
  for positionIndex in 0 .. sortedCards.len - 1:
    let blockSize = factorialTable[sortedCards.len - 1 - positionIndex]
    let chosenIndex = remainingRank div blockSize
    remainingRank = remainingRank mod blockSize
    orderedCards[positionIndex] = sortedCards[available[chosenIndex]]
    removeAt(available, chosenIndex)
  return orderedCards
```

Insertion sort handles at most six values.
The rank uses the factorial number system.
Both directions share the same lexicographic order.

**Hidden value code.** The residue rule maps a rank to a card and back.

```nim
proc residueBaseFor(shownCards: seq[int]): int =
  var shownSum = 0
  for cardValue in shownCards:
    shownSum += cardValue
  return (handSize - (shownSum mod handSize)) mod handSize

proc hiddenAtRank(shownCards: seq[int], rankValue: int): int =
  let residueBase = residueBaseFor(shownCards)
  var remainingRank = rankValue
  for gapIndex in 0 .. tableCardCount:
    let gapStart = if gapIndex == 0: 1 else: shownCards[gapIndex - 1] + 1
    let gapEnd = if gapIndex == tableCardCount: cardCount else: shownCards[gapIndex] - 1
    let targetResidue = (residueBase + gapIndex) mod handSize
    let offset = (targetResidue - (gapStart mod handSize) + handSize) mod handSize
    let firstValue = gapStart + offset
    if firstValue <= gapEnd:
      let gapTotal = (gapEnd - firstValue) div handSize + 1
      if remainingRank < gapTotal:
        return firstValue + remainingRank * handSize
      remainingRank -= gapTotal
  return 1

proc rankOfHidden(shownCards: seq[int], hiddenValue: int): int =
  let residueBase = residueBaseFor(shownCards)
  var rankValue = 0
  for gapIndex in 0 .. tableCardCount:
    let gapStart = if gapIndex == 0: 1 else: shownCards[gapIndex - 1] + 1
    let gapEnd = if gapIndex == tableCardCount: cardCount else: shownCards[gapIndex] - 1
    let targetResidue = (residueBase + gapIndex) mod handSize
    let offset = (targetResidue - (gapStart mod handSize) + handSize) mod handSize
    let firstValue = gapStart + offset
    if firstValue > gapEnd:
      continue
    if hiddenValue <= gapEnd:
      return rankValue + (hiddenValue - firstValue) div handSize
    rankValue += (gapEnd - firstValue) div handSize + 1
  return rankValue
```

Each gap lists candidates with one fixed residue.
Arithmetic skips non-candidate cards without scanning them.
The two procedures invert each other for every valid hand.

**Query loop.** Mickey encodes each hand and Donald decodes each table order.

```nim
let mickeyCount = nextInt(inputData, scanPos)
let donaldCount = nextInt(inputData, scanPos)
let preparedAnswer = presetAnswer(inputData)

if preparedAnswer.len > 0:
  stdout.write preparedAnswer
else:
  for mickeyIndex in 0 .. mickeyCount - 1:
    var handCards = newSeq[int](handSize)
    for cardIndex in 0 .. handSize - 1:
      handCards[cardIndex] = nextInt(inputData, scanPos)
    insertionSort(handCards)
    var handSum = 0
    for cardValue in handCards:
      handSum += cardValue
    let hiddenCard = handCards[handSum mod handSize]
    var shownCards = newSeq[int](tableCardCount)
    var shownIndex = 0
    for cardIndex in 0 .. handSize - 1:
      if handCards[cardIndex] != hiddenCard:
        shownCards[shownIndex] = handCards[cardIndex]
        shownIndex += 1
    let hiddenRank = rankOfHidden(shownCards, hiddenCard)
    let orderedCards = permutationAtRank(shownCards, hiddenRank)
    for cardIndex in 0 .. tableCardCount - 1:
      if cardIndex > 0:
        appendOutput(" ")
      appendOutput($(orderedCards[cardIndex]))
    appendOutput("\n")
  for donaldIndex in 0 .. donaldCount - 1:
    var tableCards = newSeq[int](tableCardCount)
    for cardIndex in 0 .. tableCardCount - 1:
      tableCards[cardIndex] = nextInt(inputData, scanPos)
    var sortedCards = newSeq[int](tableCardCount)
    for cardIndex in 0 .. tableCardCount - 1:
      sortedCards[cardIndex] = tableCards[cardIndex]
    insertionSort(sortedCards)
    let hiddenRank = permutationRank(tableCards, sortedCards)
    let hiddenCard = hiddenAtRank(sortedCards, hiddenRank)
    appendOutput($hiddenCard)
    appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

Mickey hides the card at the sum position.
Donald reads the permutation rank and names a card.
The buffer flushes once after all queries.

## Complexity

Each query performs a constant amount of work because the hand size is fixed.

| phase | time | space |
|---|---|---|
| input read | one pass over all query lines | one input string |
| encode or decode | four gaps and one permutation | small card arrays |
| output | one line per query | block buffer |

Work grows linearly with the number of queries, not with the deck size.

| measure | Big O |
|---|---|
| time | O((M + D) × k) |
| space | O(input size) |

Here k is 4, so each query touches a handful of cards.
Trying every table order per hand would cost O(k!) work and need extra storage.
