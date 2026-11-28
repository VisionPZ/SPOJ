# CODWRECK4 — Alien Language (SPOJ)

<https://www.spoj.com/problems/CODWRECK4/>

## Problem

Restore the space in each alien message by splitting it into exactly two dictionary words. When several splits work, print the one with the shortest first word.

The input gives `N` dictionary words, one per line, then `T` alien messages. Every message contains only lowercase letters and has a valid split. Print one line per message: first word, a space, then second word.

| item | bound |
|---|---|
| dictionary size N | 1 to 100000 |
| word length | 1 to 20 |
| messages T | 1 to 1000 |
| alien message length | 1 to 40 |
| judge limit | 500 ms, 1536 MB |

The dictionary size drives the design: each split check must avoid a linear scan.

Sample input:

```
6
coding
code
wreck
dechef
co
chef
2
codingwreck
codechef
```

Sample output:

```
coding wreck
co dechef
```

## Idea

A sorted dictionary makes each split check a phone-book lookup, so trying short prefixes first lands on the shortest answer directly. The algorithm sorts the words and tests membership with binary search. Each side of a split costs O(log N), and a message has at most 39 splits. Comparing a piece against every word would cost O(N) per check, which is too slow at N = 100000. Scan prefixes from left to right and stop at the first valid pair.

## Why It Works

1. A valid split has a prefix and a suffix that are both dictionary words.
2. Trying split positions in increasing order tests prefixes by increasing length.
3. `containsWord` answers each membership test by binary search in O(log N).
4. The first successful split therefore has the shortest possible first word.
5. The code prints the two pieces in that order with one space between them.

| term | meaning |
|---|---|
| `dictionary` | sorted list of all known words |
| `alienMessage` | current message with the space removed |
| `splitIndex` | candidate boundary position inside the message |
| `firstWord` | prefix before the boundary |
| `secondWord` | suffix after the boundary |

For `codechef`, the split after `code` gives `code chef`, and the split after `co` gives `co dechef`. Both pairs are in the dictionary, but `co` is shorter, so the answer is `co dechef`.

## Code

**Input and lookup.** The reader loads the words and messages, and binary search tests membership.

```nim
import algorithm

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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc compareWords(leftWord: string, rightWord: string): int =
  cmp(leftWord, rightWord)

proc containsWord(sortedWords: seq[string], target: string): bool =
  var lowIndex = 0
  var highIndex = sortedWords.len - 1
  while lowIndex <= highIndex:
    let middleIndex = (lowIndex + highIndex) div 2
    let comparison = cmp(sortedWords[middleIndex], target)
    if comparison < 0:
      lowIndex = middleIndex + 1
    elif comparison > 0:
      highIndex = middleIndex - 1
    else:
      return true
  return false
```

The token reader stops at any whitespace character.
String comparison orders the dictionary for binary search.
Each lookup halves the remaining range on every step.

**Split scan.** Each message is tested at every boundary until a pair succeeds.

```nim
let wordCount = nextInt(inputData, scanPos)
var dictionary = newSeq[string](wordCount)
for wordIndex in 0 .. wordCount - 1:
  dictionary[wordIndex] = nextToken(inputData, scanPos)
dictionary.sort(compareWords)

let messageCount = nextInt(inputData, scanPos)
for messageIndex in 0 .. messageCount - 1:
  let alienMessage = nextToken(inputData, scanPos)
  for splitIndex in 1 .. alienMessage.len - 1:
    let firstWord = alienMessage[0 .. splitIndex - 1]
    let secondWord = alienMessage[splitIndex .. alienMessage.len - 1]
    if containsWord(dictionary, firstWord) and containsWord(dictionary, secondWord):
      appendOutput(firstWord)
      outputBuffer.add ' '
      appendOutput(secondWord)
      outputBuffer.add '\n'
      break

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop starts at the shortest possible prefix.
The suffix occupies the rest of the message at each boundary.
The first match is printed and the inner loop stops.

## Complexity

Sorting the dictionary once and looking up each candidate piece dominate the running time.

| phase | time | space |
|---|---|---|
| input read | one pass over words and messages | one input string |
| dictionary sort | `O(N log N)` | `N` strings |
| message split scan | up to 40 lookups per message | two temporary strings |
| output | one pass over answers | block buffer |

The lookup work per message stays small even for a large dictionary.

| measure | Big O |
|---|---|
| time | `O(N log N + T * 40 * log N)` |
| space | `O(N)` |

Comparing each piece with every dictionary word would cost `O(N)` per check, so binary search is the deciding gain. The increasing split order fixes the shortest-first rule without extra comparisons.
