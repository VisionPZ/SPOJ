# POKER — Poker (SPOJ)

<https://www.spoj.com/problems/POKER/>

## Problem

Each line gives five cards, and the answer is the name of the poker hand they form.
The ten names run from royal flush down to high card.

The first input line gives the number of hands, at most 20. Each next line gives five
cards. A card is a rank followed by a suit. The ranks are A K Q J T 9 8 7 6 5 4 3 2.
The suits are S H D C. Cards in one hand never repeat. Output one lowercase name
per hand, on its own line.

The bounds from the statement:

| Item | Bound |
|---|---|
| Hands per input | at most 20 |
| Cards per hand | 5 |
| Ranks | A K Q J T 9 8 7 6 5 4 3 2 |
| Suits | S H D C |
| Judge limits | 7 s and 1536 MB |
| Source limit | 50 000 B |

The small case count puts the weight on correct classification, not on throughput.

The sample case:

```
3
AH KH QH TH JH
KH 5S 3C 5C 7D
QH QD 2S QC 2C
```

```
royal flush
pair
full house
```

The first hand runs ten through ace in hearts. The third holds three queens and two twos.

## Idea

Group the cards by rank, like sorting coins into piles by denomination, then name the
strongest pattern the piles make. The program counts ranks and suits in two fixed arrays.
It walks the 13 rank slots once to collect distinct ranks, then tests the ten types in order.
A straight is five distinct ranks whose ends differ by four, plus the ace-low wrap.

One hand costs five card reads and about 26 fixed checks. Checking each type with its own
search over card pairs repeats the same work ten times. One counting pass and one ordered
decision chain name every hand.

## Why It Works

The decision rests on four facts.

1. A rank counter of four means four of a kind; a three plus a two means a full house.
2. One suit counter reaching five means all cards share a suit, so the hand is a flush.
3. Five distinct ranks whose largest and smallest differ by four form a straight. The ranks A 2 3 4 5 form the one wrap-around straight.
4. Testing from strongest to weakest returns the right name when several descriptions fit. A royal flush is also a straight and a flush.

The terms used by the decision chain:

| Term | Meaning |
|---|---|
| `rankCounts[rank]` | number of cards with that rank |
| `suitCounts` | four suit counters, one per suit |
| `distinctRanks` | ranks that appear, in increasing order |
| `straightHigh` | largest rank of a straight, or 5 for A 2 3 4 5 |
| `threeCount` and `pairCount` | how many ranks appear three and two times |

Every test reads a counter or the distinct-rank list, so no card list is rebuilt.

A script-generated trace for the third sample hand and the royal flush:

```
hand: QH QD 2S QC 2C
rank counts: 2 -> 2, Q -> 3
suit counts: S -> 1, H -> 1, D -> 1, C -> 2
distinct ranks: 2, Q (2 of 5)
flush: False
fourCount: 0
threeCount: 1
pairCount: 1
answer: full house

hand: AH KH QH TH JH
rank counts: A -> 1, J -> 1, K -> 1, Q -> 1, T -> 1
suit counts: S -> 0, H -> 5, D -> 0, C -> 0
distinct ranks: T, J, Q, K, A (5 of 5)
flush: True
fourCount: 0
threeCount: 0
pairCount: 0
answer: royal flush
```

The full house has one triple and one pair. The royal flush has five distinct ranks in one suit.

## Code

**Constants.** Fixed sizes and byte values live at the top.

```nim
const flushBlockBytes = 1 shl 18
const firstDigitValue = 48
const cardsPerHand = 5
const lowestRank = 2
const aceRank = 14
const kingRank = 13
const queenRank = 12
const jackRank = 11
const tenRank = 10
const suitCount = 4
```

`cardsPerHand` is five, the hand size from the statement. `flushBlockBytes` sets a 256 KiB
output block. The rank constants keep `rankValue` readable.

**Integer scanner.** The case count comes from the input buffer by index.

```nim
proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value
```

The scan skips bytes below `'0'`, so blank lines cannot desync it. No token object is built.
The minus branch is absent because the input holds no negative numbers.

**Card scanner.** Each card is read as a short token from the same buffer.

```nim
proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token
```

Whitespace includes spaces and newlines. Five calls read one hand. Each call builds a
two-character string for one card.

**Rank lookup.** Face cards and tens become their numeric rank.

```nim
proc rankValue(rankChar: char): int =
  if rankChar == 'A': return aceRank
  if rankChar == 'K': return kingRank
  if rankChar == 'Q': return queenRank
  if rankChar == 'J': return jackRank
  if rankChar == 'T': return tenRank
  return int(rankChar) - firstDigitValue
```

Ace becomes 14, so it sorts above king. Digit ranks use their digit value minus
`firstDigitValue`. The return covers ranks 2 through 9.

**Hand classifier.** Two counter arrays and the distinct-rank list decide the type.

```nim
proc classifyHand(cardRanks: array[cardsPerHand, int], cardSuits: array[cardsPerHand, char]): string =
  var rankCounts: array[aceRank + 1, int]
  var suitCounts: array[suitCount, int]
  for cardIndex in 0 ..< cardsPerHand:
    rankCounts[cardRanks[cardIndex]] += 1
    case cardSuits[cardIndex]
    of 'S': suitCounts[0] += 1
    of 'H': suitCounts[1] += 1
    of 'D': suitCounts[2] += 1
    else: suitCounts[3] += 1
  var isFlush = false
  for suitIndex in 0 ..< suitCount:
    if suitCounts[suitIndex] == cardsPerHand: isFlush = true
  var distinctRanks: array[cardsPerHand, int]
  var distinctCount = 0
  for rank in lowestRank .. aceRank:
    if rankCounts[rank] > 0:
      distinctRanks[distinctCount] = rank
      distinctCount += 1
  var isStraight = false
  var straightHigh = 0
  if distinctCount == cardsPerHand:
    if distinctRanks[cardsPerHand - 1] - distinctRanks[0] == cardsPerHand - 1:
      isStraight = true
      straightHigh = distinctRanks[cardsPerHand - 1]
    elif distinctRanks[0] == lowestRank and distinctRanks[1] == lowestRank + 1 and
         distinctRanks[2] == lowestRank + 2 and distinctRanks[3] == lowestRank + 3 and
         distinctRanks[cardsPerHand - 1] == aceRank:
      isStraight = true
      straightHigh = lowestRank + 3
  if isFlush and isStraight and straightHigh == aceRank: return "royal flush"
  if isFlush and isStraight: return "straight flush"
  var fourCount = 0
  var threeCount = 0
  var pairCount = 0
  for rank in lowestRank .. aceRank:
    if rankCounts[rank] == 4: fourCount += 1
    elif rankCounts[rank] == 3: threeCount += 1
    elif rankCounts[rank] == 2: pairCount += 1
  if fourCount == 1: return "four of a kind"
  if threeCount == 1 and pairCount == 1: return "full house"
  if isFlush: return "flush"
  if isStraight: return "straight"
  if threeCount == 1: return "three of a kind"
  if pairCount == 2: return "two pairs"
  if pairCount == 1: return "pair"
  return "high card"
```

The rank loops visit slots 2 through 14, exactly 13 slots. The ace-low test handles
A 2 3 4 5 without a second sort. The ordered returns stop at the strongest matching type.

**Driver.** One input buffer, fixed card slots, and block output.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var cardRanks: array[cardsPerHand, int]
var cardSuits: array[cardsPerHand, char]
var outputBuffer = ""
for caseIndex in 0 ..< caseCount:
  for cardIndex in 0 ..< cardsPerHand:
    let cardToken = nextToken(inputData, scanPos)
    cardRanks[cardIndex] = rankValue(cardToken[0])
    cardSuits[cardIndex] = cardToken[1]
  outputBuffer.add classifyHand(cardRanks, cardSuits)
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
outputBuffer.setLen 0
```

All lines are appended to `inputData` before parsing. `cardRanks` and `cardSuits` are reused
for every case. The final write flushes the tail of `outputBuffer`.

## Complexity

Costs stay fixed because the hand size never changes.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over the input lines | input bytes |
| Token scan | five tokens per hand | two card slots |
| Classification | 13 rank visits and 13 count visits | 15 counters and 5 ranks |
| Output | one write per 256 KiB block | block buffer |
| Whole input | 20 times the per-hand cost | input plus block buffer |

The buffers hold the only space that grows with the input.

The asymptotic bounds:

| Measure | Big O |
|---|---|
| Time | O(t) for t hands, with a constant 26 checks per hand |
| Space | O(1) for classification, plus input and output bytes |

A per-type search over card pairs repeats those checks for each category. One counting pass
answers all ten types with a single set of counters.
