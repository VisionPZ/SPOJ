# SORTOUT — Mahammad and strings (SPOJ)

<https://www.spoj.com/problems/SORTOUT/>

## Problem

Given a collection of strings and several query strings, report how many collection strings are lexicographically smaller than or equal to each query. Treat the collection like a sorted dictionary and locate the last entry that does not pass the query word.

| item | bound |
|---|---|
| input strings N | positive, total length at most 200000 |
| queries Q | positive, total length at most 200000 |
| characters | lowercase English letters |
| judge limit | 100 ms, 1536 MB |

All strings are whitespace-free, and the first line holds `N` then `Q`.

Sample input:

```
4 3
fury
fuzzy
dizzy
future
fuzz
evil
freeze
```

Sample output:

```
3
1
1
```

## Idea

Sort the collection once, like alphabetising a card index, then use a binary search to find the insertion point of each query. The insertion point equals the number of strings not greater than the query. A linear scan compares the query with every string and is much slower on large collections. The takeaway is that one sort plus one binary search per query replaces repeated full scans.

## Why It Works

1. Lexicographic order gives a total order on the lowercase strings.
2. Sorting the collection groups every string smaller than or equal to a query into one prefix.
3. The length of that prefix is the required count.
4. Binary search finds the prefix length in logarithmic comparisons.
5. Equal strings stay inside the prefix because the comparison is inclusive.

| term | meaning |
|---|---|
| `wordList` | sorted collection of input strings |
| `queryWord` | one string from the query section |
| `lowBound` | first index that may be greater than the query |
| `highBound` | exclusive upper bound of the search |
| `middleIndex` | midpoint tested during one iteration |

The worked example uses the sample collection sorted by the generator's brute-force count.

| query | sorted collection | midpoint tests | count |
|---|---|---|---|
| `fuzz` | dizzy, future, fury, fuzzy | fury passes, fuzzy fails | 3 |
| `evil` | dizzy, future, fury, fuzzy | fury fails, dizzy passes | 1 |
| `freeze` | dizzy, future, fury, fuzzy | fury fails, dizzy passes | 1 |

For `fuzz`, the search moves `lowBound` past `fury` and then moves `highBound` down to index 3, so three strings qualify.

The scanner accepts any spacing because it reads tokens, not fixed columns. The output buffer batches all answer lines into one write path.

## Code

**Input and sort.** The reader loads both sections as words and sorts the collection.

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

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < 'a' or data[pos] > 'z'):
    pos += 1
  var word = ""
  while pos < data.len and data[pos] >= 'a' and data[pos] <= 'z':
    word.add data[pos]
    pos += 1
  return word

proc compareWords(leftWord, rightWord: string): int =
  return cmp(leftWord, rightWord)
```

The integer scanner reads the two counts.
The word scanner stops at any separator.
The comparator uses the built-in string order.

**Buffered output.** One string collects the answer lines before a final write.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Large blocks flush during the loop.
Small outputs flush once at the end.

**Binary search.** Each query locates its inclusive upper bound in the sorted collection.

```nim
let inputCount = nextInt(inputData, scanPos)
let queryCount = nextInt(inputData, scanPos)
var wordList = newSeq[string](inputCount)
for wordIndex in 0 .. inputCount - 1:
  wordList[wordIndex] = nextWord(inputData, scanPos)
wordList.sort(compareWords)

for queryIndex in 0 .. queryCount - 1:
  let queryWord = nextWord(inputData, scanPos)
  var lowBound = 0
  var highBound = wordList.len
  while lowBound < highBound:
    let middleIndex = (lowBound + highBound) div 2
    if wordList[middleIndex] <= queryWord:
      lowBound = middleIndex + 1
    else:
      highBound = middleIndex
  appendOutput($lowBound)
  appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

The inclusive comparison keeps equal strings inside the prefix.
The final `lowBound` is printed for every query.
The buffer flushes after the last answer.

## Complexity

Sorting dominates preprocessing, and each query uses one logarithmic search.

| phase | time | space |
|---|---|---|
| input read | one pass over the whole text | one input string |
| sort | N log N comparisons | array of N strings |
| queries | Q log N comparisons | block buffer |

| measure | Big O |
|---|---|
| time | O(N log N + Q log N) |
| space | O(N) |

Scanning every input string for every query would cost O(NQ). The takeaway is that sorting converts each query into a short binary search.
