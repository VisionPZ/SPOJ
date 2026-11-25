# FRNDS — Friends (SPOJ)
<https://www.spoj.com/problems/FRNDS/>

## Problem

Friendship is mutual and transitive, so friends form groups. Count seating orders with at least one adjacent pair from the same group, modulo 1000000007.

The first line holds the case count. Each case gives `peopleCount` and `friendshipCount`, followed by that many pairs of friend numbers.

Print `Case #X: P` per case with the count modulo 1000000007.

The table lists the input and judge limits.

| item | bound |
|---|---|
| cases | 1 to 600 |
| people N | 2 to 40 |
| friendships M | 0 to 800 |
| answer modulus | 1000000007 |
| judge limit | 8386 ms, 1536 MB |

Every friendship joins two distinct people.

The sample below is verbatim from the statement.

```
3
2 1
2 1
3 2
2 1
1 3
4 0
```

```
Case #1: 2
Case #2: 6
Case #3: 0
```

The third case has no friends, so no order can be good.

## Idea

Count the opposite event first, like arranging colored books so that no two books of one color touch.

The algorithm builds friendship groups with a union-find, then counts words with no equal adjacent group using a generating-function DP. The answer is all permutations minus those bad words.

Each group adds O(N squared) work, so a case costs O(N cubed) at worst. Listing all N factorial orders would be far larger.

The subtraction gives the answer with one DP pass.

## Why It Works

1. Transitive friendship makes the input a partition into connected groups.
2. A bad order is a word over group labels with no equal neighbours.
3. The generating function for such words is 1 divided by 1 minus the sum of x over 1 plus x.
4. Its coefficient uses compositions of each group size into part counts, with alternating signs.
5. The answer is `factorials[peopleCount]` minus the bad count, reduced modulo `answerModulus`.

The table names the DP values.

| term | meaning |
|---|---|
| `groupSizes` | number of people in each friendship group |
| `possibilities` | signed weighted sum by number of label blocks |
| `factorials` | precomputed factorials up to 40 |
| `inverseFactorials` | modular inverses of those factorials |

The transition divides by `partCount` factorial and uses the binomial of `groupSize - 1`.

For one group of size 3, the signed sum of compositions is 1 minus 2 plus 1, which is 0. No bad order exists, so all 6 orders are good.

For groups of sizes 2 and 1, the bad count is 2 and the answer is 4.

Fermat inversion needs a prime modulus, which 1000000007 is. All products stay in `int64`.

## Code

**Factorials and inverses.** Modular inverses support the division in the DP.

```nim
const flushBlockBytes = 1 shl 17
const answerModulus = 100000007.int64
const maximumPeople = 40

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

proc modularPower(baseValue: int64, exponentValue: int): int64 =
  var powerResult: int64 = 1
  var current = baseValue mod answerModulus
  var exponent = exponentValue
  while exponent > 0:
    if (exponent and 1) == 1:
      powerResult = powerResult * current mod answerModulus
    current = current * current mod answerModulus
    exponent = exponent div 2
  return powerResult

var factorials = newSeq[int64](maximumPeople + 1)
var inverseFactorials = newSeq[int64](maximumPeople + 1)
factorials[0] = 1
for indexValue in 1 .. maximumPeople:
  factorials[indexValue] = factorials[indexValue - 1] * int64(indexValue) mod answerModulus
inverseFactorials[maximumPeople] = modularPower(factorials[maximumPeople], int(answerModulus) - 2)
for indexValue in countdown(maximumPeople, 1):
  inverseFactorials[indexValue - 1] = inverseFactorials[indexValue] * int64(indexValue) mod answerModulus
```

Factorials run up to `maximumPeople`. The largest inverse comes from one modular power.

The rest come from a descending pass.

**Groups and DP.** Union-find builds groups, then the signed DP counts bad orders.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. testCount:
  let peopleCount = nextInt(inputData, scanPos)
  let friendshipCount = nextInt(inputData, scanPos)
  var parent = newSeq[int](peopleCount)
  for personIndex in 0 .. peopleCount - 1:
    parent[personIndex] = personIndex

  proc findRoot(person: int): int =
    var current = person
    while parent[current] != current:
      current = parent[current]
    return current

  for friendshipIndex in 0 .. friendshipCount - 1:
    let firstPerson = nextInt(inputData, scanPos) - 1
    let secondPerson = nextInt(inputData, scanPos) - 1
    let firstRoot = findRoot(firstPerson)
    let secondRoot = findRoot(secondPerson)
    if firstRoot != secondRoot:
      parent[firstRoot] = secondRoot

  var groupSizes = newSeq[int](peopleCount + 1)
  for personIndex in 0 .. peopleCount - 1:
    groupSizes[findRoot(personIndex)] += 1
  var sizes = newSeq[int]()
  for groupIndex in 0 .. peopleCount:
    if groupSizes[groupIndex] > 0:
      sizes.add groupSizes[groupIndex]

  var possibilities = newSeq[int64](peopleCount + 1)
  possibilities[0] = 1
  for groupSize in sizes:
    var updated = newSeq[int64](peopleCount + 1)
    for usedCount in 0 .. peopleCount:
      if possibilities[usedCount] == 0:
        continue
      for partCount in 1 .. groupSize:
        if usedCount + partCount > peopleCount:
          break
```

Each friendship merges two roots. Group sizes become the DP stages.

Each stage adds one block count dimension.

**Final subtraction.** The good count is all orders minus bad orders.

```nim
        var combinations = factorials[groupSize - 1]
        combinations = combinations * inverseFactorials[partCount - 1] mod answerModulus
        combinations = combinations * inverseFactorials[groupSize - partCount] mod answerModulus
        var contribution = possibilities[usedCount] * combinations mod answerModulus
        contribution = contribution * inverseFactorials[partCount] mod answerModulus
        if (groupSize - partCount) mod 2 == 1:
          contribution = (answerModulus - contribution) mod answerModulus
        updated[usedCount + partCount] = (updated[usedCount + partCount] + contribution) mod answerModulus
    possibilities = updated

  var separatorCount: int64 = 0
  for usedCount in 1 .. peopleCount:
    separatorCount = (separatorCount + possibilities[usedCount] * factorials[usedCount]) mod answerModulus
  var badArrangements = separatorCount
  for groupSize in sizes:
    badArrangements = badArrangements * factorials[groupSize] mod answerModulus
  let goodArrangements = (factorials[peopleCount] - badArrangements + answerModulus) mod answerModulus
  appendOutput("Case #" & $caseIndex & ": " & $goodArrangements & "\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

`separatorCount` expands block counts into labelled words. Each group multiplies by its own factorial.

The subtraction wraps into the modulus range.

## Complexity

The table shows the work in each phase.

| phase | time | space |
|---|---|---|
| input read | M friendship pairs | one input string |
| union-find | one find per endpoint | N parent entries |
| DP | N times N times N operations | N prefix sums |
| output | one line per case | block buffer |

N is the number of people.

| measure | Big O |
|---|---|
| time | O(N cubed) per case |
| space | O(N) |

Listing all seating orders costs N factorial steps. The label DP counts them without listing any order.
