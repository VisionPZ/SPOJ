# VIP — VIP (SPOJ)
<https://www.spoj.com/problems/VIP/>

## Problem

Find the celebrity in each crowd: the person known by everyone else who knows nobody else. The answer prints that person's number for every data set.

Input starts with d from 1 to 100. Each data set gives n from 1 to 500, then n rows of n zeros and ones, where entry i j is 1 when person i knows person j. Every person knows themselves, and a VIP always exists. Output prints one person number per data set, each on its own line.

| item | bound |
|---|---|
| data sets d | 1 to 100 |
| people per set n | 1 to 500 |
| matrix entries | 0 or 1 |
| judge limit | 1000 ms, 1536 MB |

The VIP row holds a single 1 on the diagonal, and the VIP column is all ones.

Sample input:

```
2
3
1 0 1
1 1 1
0 0 1
5
1 0 0 1 1
1 1 0 1 0
0 0 1 1 1
0 0 0 1 0
1 1 0 1 1
```

Sample output:

```
3
4
```

## Idea

Eliminate candidates with one comparison at a time, like finding a team captain by asking who knows whom. If the current candidate knows someone, the candidate cannot be the VIP. If the candidate does not know someone, that someone cannot be the VIP. Each comparison removes one person, so finding a candidate costs n checks. Verifying it costs another n checks. Scanning every pair twice would cost n squared checks. Takeaway: eliminate first, then verify once.

## Why It Works

1. A VIP knows no one except themselves, so a candidate who knows someone else fails.
2. A VIP is known by everyone, so a person the candidate does not know fails.
3. Each comparison removes exactly one of the two people from consideration.
4. After n minus one comparisons, at most one candidate remains.
5. Checking the candidate's row and column confirms the VIP, which the input guarantees exists.

| term | meaning |
|---|---|
| `knowsMatrix` | flattened n by n knowledge table |
| `candidate` | surviving person index, zero based |
| `isVip` | true when the candidate passes the final row and column check |
| `peopleCount` | number of people in the current data set |

In the first sample set, person 1 knows person 3, so person 3 replaces person 1. Person 3 then has row 0 0 1 and column 1 1 1, so the answer is 3. The second sample set gives person 4.

## Code

**Input and scanning.** The reader loads all data sets and parses the matrix entries.

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

`inputData` holds every data set before parsing.
`nextInt` reads zeros, ones and the size values directly.

**Elimination and output.** Each set yields one candidate and one verified answer line.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let dataSetCount = nextInt(inputData, scanPos)
for dataSetIndex in 0 .. dataSetCount - 1:
  let peopleCount = nextInt(inputData, scanPos)
  var knowsMatrix = newSeq[int](peopleCount * peopleCount)
  for rowIndex in 0 .. peopleCount - 1:
    for columnIndex in 0 .. peopleCount - 1:
      knowsMatrix[rowIndex * peopleCount + columnIndex] = nextInt(inputData, scanPos)
  var candidate = 0
  for personIndex in 1 .. peopleCount - 1:
    if knowsMatrix[candidate * peopleCount + personIndex] == 1:
      candidate = personIndex
  var isVip = true
  for personIndex in 0 .. peopleCount - 1:
    if personIndex != candidate:
      if knowsMatrix[personIndex * peopleCount + candidate] != 1:
        isVip = false
      if knowsMatrix[candidate * peopleCount + personIndex] != 0:
        isVip = false
  if isVip:
    appendOutput($(candidate + 1))
  else:
    for personIndex in 0 .. peopleCount - 1:
      var knowsOnlySelf = true
      var knownByAll = true
      for otherIndex in 0 .. peopleCount - 1:
        if otherIndex != personIndex:
          if knowsMatrix[personIndex * peopleCount + otherIndex] != 0:
            knowsOnlySelf = false
          if knowsMatrix[otherIndex * peopleCount + personIndex] != 1:
            knownByAll = false
      if knowsOnlySelf and knownByAll:
        appendOutput($(personIndex + 1))
        break
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

`candidate` changes only when it knows the compared person.
`isVip` checks the candidate row and column in one pass.
The fallback scan handles any unexpected input where verification fails.

## Complexity

Each data set reads a matrix and finds one person.

| phase | time | space |
|---|---|---|
| input read | n squared entries per set | one input string |
| elimination | n comparisons | one candidate |
| verification | n comparisons | one matrix |
| output | one line per set | block buffer |

| measure | Big O |
|---|---|
| time | O(n^2) per data set, dominated by input |
| space | O(n^2) per data set |

Checking every candidate against every person would double the comparison work. Takeaway: elimination finds the only possible VIP in linear comparisons.
