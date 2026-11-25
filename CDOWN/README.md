<https://www.spoj.com/problems/CDOWN/>

## Problem

Given a family tree, list the people with the most descendants exactly `d` generations below them. Show three names, or more when a tie reaches the third place, and omit people with zero.

Input begins with the test count. Each case starts with `n d`, where `n` is the number of description lines and `d` is the generation distance. Each of the next `n` lines holds a name, a child count, and the child names. Output starts with `Tree i:`, then one `name count` line per selected person, then a blank line.

| item | bound |
|---|---|
| people per tree | at most 1000 |
| name length | at most 10 characters |
| description lines | `n` per case |
| judge limit | 1000 ms, 1536 MB |

Lines arrive in any order, and each person has one fixed generation distance from any descendant.

Sample input:

```
3
8 2
Barney 2 Fred Ginger
Ingrid 1 Nolan
Cindy 1 Hal
Jeff 2 Oliva Peter
Don 2 Ingrid Jeff
Fred 1 Kathy
Andrea 4 Barney Cindy Don Eloise
Hal 2 Lionel Mary
6 1
Phillip 5 Jim Phil Jane Joe Paul
Jim 1 Jimmy
Phil 1 Philly
Jane 1 Janey
Joe 1 Joey
Paul 1 Pauly
6 2
Phillip 5 Jim Phil Jane Joe Paul
Jim 1 Jimmy
Phil 1 Philly
Jane 1 Janey
Joe 1 Joey
Paul 1 Pauly
```

Sample output:

```
Tree 1:
Andrea 5
Don 3
Cindy 2

Tree 2:
Phillip 5
Jane 1
Jim 1
Joe 1
Paul 1
Phil 1

Tree 3:
Phillip 5

```

## Idea

Walk upward from every person like tracing a family tree back through named parents. The person reached after exactly `d` steps is the ancestor who counts that person as a descendant. One pass over the people builds every count. Sorting the nonzero counts gives the report. The takeaway is that upward walks replace a downward search from each candidate.

## Why It Works

1. Each child name gets a parent index while the description lines are read.
2. A name appearing first as a child still receives an index immediately.
3. Walking `d` parent links from a person finds the ancestor `d` generations above.
4. Adding one for each successful walk gives that ancestor's descendant count.
5. Sorting by count descending and name ascending produces the required order.

| term | meaning |
|---|---|
| `parentIndex` | parent of each person, minus one at the root |
| `depthTarget` | required number of generations |
| `descendantCounts` | descendants at the target depth for each person |
| `candidates` | people with a positive count |
| `cutoffCount` | count of the third listed person |

Only positive counts are reported, so people with no matching descendants are skipped.

In the first sample tree, the counts at depth two are Andrea `5`, Don `3`, Cindy `2`, and Barney `1`. The first three become the report because no tie reaches the third place.

A blank line closes every case, including the final one.

## Code

**Input and scanning.** The reader loads all input, then parses whitespace-separated tokens.

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

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  result = ""
  while pos < data.len and data[pos] > ' ':
    result.add data[pos]
    pos += 1

proc tokenInt(token: string): int =
  result = 0
  for charIndex in 0 .. token.len - 1:
    result = result * 10 + int(token[charIndex]) - 48
```

Numeric tokens are converted separately from names.
Names may appear before their own description line.
Blank lines in the input do not affect token order.

**Report record and output helper.** A small record holds one result line, and one buffer collects the output.

```nim
type PersonResult = object
  personName: string
  descendantCount: int

proc comesBefore(left: PersonResult, right: PersonResult): bool =
  if left.descendantCount != right.descendantCount:
    return left.descendantCount > right.descendantCount
  return left.personName < right.personName

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The comparator sorts by count first and name second.
Large reports flush through one block write.
The remaining text flushes at the end.

**Tree assembly and counts.** Names receive indexes, parent links are stored, and upward walks fill the counts.

```nim
var personNames = newSeq[string]()
var parentIndex = newSeq[int]()
var descendantCounts = newSeq[int]()

proc findPerson(name: string): int =
  for personIndex in 0 .. personNames.len - 1:
    if personNames[personIndex] == name:
      return personIndex
  personNames.add name
  parentIndex.add -1
  descendantCounts.add 0
  return personNames.len - 1

let testCount = tokenInt(nextWord(inputData, scanPos))
for caseIndex in 1 .. testCount:
  let lineCount = tokenInt(nextWord(inputData, scanPos))
  let depthTarget = tokenInt(nextWord(inputData, scanPos))
  personNames = newSeq[string]()
  parentIndex = newSeq[int]()
  descendantCounts = newSeq[int]()
  for lineIndex in 0 .. lineCount - 1:
    let ownerName = nextWord(inputData, scanPos)
    let ownerIndex = findPerson(ownerName)
    let childTotal = tokenInt(nextWord(inputData, scanPos))
    for childIndex in 0 .. childTotal - 1:
      let childName = nextWord(inputData, scanPos)
      let childPerson = findPerson(childName)
      parentIndex[childPerson] = ownerIndex
  for personIndex in 0 .. personNames.len - 1:
    var ancestor = personIndex
    for stepIndex in 0 .. depthTarget - 1:
      ancestor = parentIndex[ancestor]
      if ancestor == -1:
        break
    if ancestor != -1:
      descendantCounts[ancestor] += 1
  var candidates = newSeq[PersonResult]()
  for personIndex in 0 .. personNames.len - 1:
    if descendantCounts[personIndex] > 0:
      candidates.add PersonResult(personName: personNames[personIndex],
                                   descendantCount: descendantCounts[personIndex])
  for sortIndex in 1 .. candidates.len - 1:
    let currentPerson = candidates[sortIndex]
    var insertIndex = sortIndex - 1
    while insertIndex >= 0 and comesBefore(currentPerson, candidates[insertIndex]):
      candidates[insertIndex + 1] = candidates[insertIndex]
      insertIndex -= 1
    candidates[insertIndex + 1] = currentPerson
  appendOutput("Tree " & $caseIndex & ":\n")
  var cutoffCount = -1
  if candidates.len >= 3:
    cutoffCount = candidates[2].descendantCount
  var printedCount = 0
  for candidate in candidates:
    if printedCount < 3 or (cutoffCount != -1 and candidate.descendantCount == cutoffCount):
      appendOutput(candidate.personName & " " & $candidate.descendantCount & "\n")
      printedCount += 1
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

A missing ancestor stops the walk early.
Ties below third place are included through `cutoffCount`.
Each case ends with one blank line.

## Complexity

Each person contributes one upward walk, and the candidate list is sorted by insertion.

| phase | time | space |
|---|---|---|
| input read | one pass over tokens | one input string |
| tree assembly | one index lookup per name | names and parent links |
| descendant counts | `d` parent steps per person | count array |
| output | up to a few lines per case | block buffer |

| measure | Big O |
|---|---|
| time per case | `O(p*d + p^2 + p log p)` |
| space per case | `O(p)` |

A downward search from every person would rebuild the same subtree counts many times.

The parent index turns each generation step into one array lookup.
