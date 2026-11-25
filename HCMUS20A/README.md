# HCMUS20A — Magic Schools (SPOJ)

<https://www.spoj.com/problems/HCMUS20A/>

## Problem

Schools form a tree, each school teaches blue or white magic, and each has a happiness value that may be negative. Choose two schools and take every school on their path. The path must contain the same number of blue and white schools, and its happiness sum must be as large as possible. Report that maximum sum.

Input gives n, a color string of length n, n happiness values, and n-1 parent links where link i connects school i+1 to its parent. Output one integer.

| item | bound |
|---|---|
| schools n | 2 to 100000 |
| happiness | -100000 to 100000 |
| judge limit | 1000 ms, 1536 MB |

Both colors occur at least once, so a valid path exists.

Sample input:

```
6
BWBBBW
6 0 3 -2 100 5
1 2 2 4 4
```

Sample output:

```
9
```

## Idea

Treat blue as plus one and white as minus one, like balancing weights on a scale. A valid path has total weight zero. Centroid decomposition splits the tree into small pieces, and each centroid collects paths that pass through it. For each branch, keep the best happiness for every balance and pair it with balances from earlier branches. Brute force over all school pairs would cost quadratic time, while each node appears in only logarithmically many centroid pieces. Every path is considered at its highest separating centroid.

## Why It Works

1. A path has equal color counts exactly when its signed balance is zero.
2. Any path passes through the first centroid that separates its endpoints into different branches, or has that centroid as an endpoint.
3. For a node u above a centroid c, the partner balance must be sign(c) minus balance(u).
4. The path happiness is weight(u) plus weight(partner) minus happiness(c).
5. Processing branches one at a time prevents pairing two nodes in the same branch.
6. Removing the centroid recurses on each remaining component.

| term | meaning |
|---|---|
| `colorSign` | plus one for blue, minus one for white |
| `bestWeight` | best path happiness from earlier branches at a balance |
| `branchWeight` | best happiness inside the current branch at a balance |
| `balanceOffset` | shifts negative balances into array indexes |
| `bestAnswer` | largest valid path happiness found so far |

The branch-by-branch rule keeps every pair of endpoints in different branches.

A script trace over the sample tree gives these balanced paths:

```
path schools   signs          happiness
1 2            + -            6
2 3            - +            3
2 4            - +           -2
4 6            + -            3
3 2 4 6        + - + -        6
1 2 4 6        + - + -        9
```

The largest value is 9, from schools 1, 2, 4, and 6, matching the sample.

Negative happiness values require the scanner to read a minus sign before digits.

## Code

**Input and tree storage.** The reader loads colors, happiness, and parent links.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return signValue * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let schoolCount = nextInt(inputData, scanPos)
while scanPos < inputData.len and (inputData[scanPos] == ' ' or inputData[scanPos] == '\n' or inputData[scanPos] == '\r'):
  scanPos += 1

var colorSign = newSeq[int](schoolCount + 1)
for schoolIndex in 1 .. schoolCount:
  if inputData[scanPos] == 'B':
    colorSign[schoolIndex] = 1
  else:
    colorSign[schoolIndex] = -1
  scanPos += 1

var happiness = newSeq[int64](schoolCount + 1)
for schoolIndex in 1 .. schoolCount:
  happiness[schoolIndex] = int64(nextInt(inputData, scanPos))

var edgeHead = newSeq[int](schoolCount + 1)
var edgeTarget = newSeq[int](2 * schoolCount + 2)
var edgeNext = newSeq[int](2 * schoolCount + 2)
var edgeCount = 1

proc addEdge(firstSchool: int, secondSchool: int) =
  edgeTarget[edgeCount] = secondSchool
  edgeNext[edgeCount] = edgeHead[firstSchool]
  edgeHead[firstSchool] = edgeCount
  edgeCount += 1

for childSchool in 2 .. schoolCount:
  let parentSchool = nextInt(inputData, scanPos)
  addEdge(parentSchool, childSchool)
  addEdge(childSchool, parentSchool)
```

The scanner accepts negative happiness values.
Colors are read directly from the input string.
Edge index zero is reserved as the end of a linked list.

**Centroid search.** Each component is measured, then split at its centroid.

```nim
var isRemoved = newSeq[bool](schoolCount + 1)
var componentParent = newSeq[int](schoolCount + 1)
var componentSize = newSeq[int](schoolCount + 1)

let balanceOffset = schoolCount + 2
let balanceArraySize = 2 * schoolCount + 5
var bestWeight = newSeq[int64](balanceArraySize)
var bestOwner = newSeq[int](balanceArraySize)
var bestStamp = newSeq[int](balanceArraySize)
var branchWeight = newSeq[int64](balanceArraySize)
var branchStamp = newSeq[int](balanceArraySize)
for index in 0 .. balanceArraySize - 1:
  bestOwner[index] = -1
  bestStamp[index] = -1
  branchStamp[index] = -1
var stampCounter = 0
var branchStampCounter = 0
var bestAnswer: int64 = -(1'i64 shl 60)

var decompositionStack = newSeq[int]()
decompositionStack.add(1)

while decompositionStack.len > 0:
  let startSchool = decompositionStack.pop()
  var componentNodes = newSeq[int]()
  var visitStack = newSeq[int]()
  visitStack.add(startSchool)
  componentParent[startSchool] = 0
  while visitStack.len > 0:
    let currentSchool = visitStack.pop()
    componentNodes.add(currentSchool)
    var edgeIndex = edgeHead[currentSchool]
    while edgeIndex != 0:
      let neighborSchool = edgeTarget[edgeIndex]
      if neighborSchool != componentParent[currentSchool] and not isRemoved[neighborSchool]:
        componentParent[neighborSchool] = currentSchool
        visitStack.add(neighborSchool)
      edgeIndex = edgeNext[edgeIndex]
  for reverseIndex in countdown(componentNodes.len - 1, 0):
    let currentSchool = componentNodes[reverseIndex]
    var subtreeTotal = 1
    var edgeIndex = edgeHead[currentSchool]
    while edgeIndex != 0:
      let neighborSchool = edgeTarget[edgeIndex]
      if componentParent[neighborSchool] == currentSchool and not isRemoved[neighborSchool]:
        subtreeTotal += componentSize[neighborSchool]
      edgeIndex = edgeNext[edgeIndex]
    componentSize[currentSchool] = subtreeTotal

  let componentTotal = componentNodes.len
  var centroidSchool = startSchool
  var bestSplit = componentTotal + 1
  for nodeIndex in 0 .. componentTotal - 1:
    let candidate = componentNodes[nodeIndex]
    var largestPart = componentTotal - componentSize[candidate]
    var edgeIndex = edgeHead[candidate]
    while edgeIndex != 0:
      let neighborSchool = edgeTarget[edgeIndex]
      if componentParent[neighborSchool] == candidate and not isRemoved[neighborSchool]:
        if componentSize[neighborSchool] > largestPart:
          largestPart = componentSize[neighborSchool]
      edgeIndex = edgeNext[edgeIndex]
    if largestPart < bestSplit:
      bestSplit = largestPart
      centroidSchool = candidate
```

Subtree sizes are computed in reverse DFS order.
The centroid minimizes the largest remaining part.
Iterative stacks avoid deep recursion on a long tree.

**Balance tables.** The centroid starts the table, then each branch is merged after its own scan.

```nim
  isRemoved[centroidSchool] = true
  stampCounter += 1
  let centroidSign = colorSign[centroidSchool]
  let centroidHappiness = happiness[centroidSchool]
  let centroidBalance = centroidSign + balanceOffset
  bestWeight[centroidBalance] = centroidHappiness
  bestOwner[centroidBalance] = 0
  bestStamp[centroidBalance] = stampCounter
  var touchedBalances = newSeq[int]()
  touchedBalances.add(centroidBalance)

  var centroidEdge = edgeHead[centroidSchool]
  while centroidEdge != 0:
    let branchSchool = edgeTarget[centroidEdge]
    if not isRemoved[branchSchool]:
      let ownerId = branchSchool
      branchStampCounter += 1
      var branchBalances = newSeq[int]()
      var nodeStack = newSeq[int]()
      var balanceStack = newSeq[int]()
      var weightStack = newSeq[int64]()
      nodeStack.add(branchSchool)
      balanceStack.add(centroidSign + colorSign[branchSchool])
      weightStack.add(centroidHappiness + happiness[branchSchool])
      componentParent[branchSchool] = centroidSchool
      while nodeStack.len > 0:
        let currentSchool = nodeStack.pop()
        let currentBalance = balanceStack.pop()
        let currentWeight = weightStack.pop()
        let targetBalance = centroidSign - currentBalance + balanceOffset
        if targetBalance >= 0 and targetBalance < balanceArraySize and bestStamp[targetBalance] == stampCounter:
          let candidateAnswer = currentWeight + bestWeight[targetBalance] - centroidHappiness
          if candidateAnswer > bestAnswer:
            bestAnswer = candidateAnswer
        let storageBalance = currentBalance + balanceOffset
        if storageBalance >= 0 and storageBalance < balanceArraySize:
          if branchStamp[storageBalance] != branchStampCounter:
            branchStamp[storageBalance] = branchStampCounter
            branchBalances.add(storageBalance)
            branchWeight[storageBalance] = currentWeight
          elif currentWeight > branchWeight[storageBalance]:
            branchWeight[storageBalance] = currentWeight
        var edgeIndex = edgeHead[currentSchool]
        while edgeIndex != 0:
          let neighborSchool = edgeTarget[edgeIndex]
          if neighborSchool != componentParent[currentSchool] and not isRemoved[neighborSchool]:
            componentParent[neighborSchool] = currentSchool
            nodeStack.add(neighborSchool)
            balanceStack.add(currentBalance + colorSign[neighborSchool])
            weightStack.add(currentWeight + happiness[neighborSchool])
          edgeIndex = edgeNext[edgeIndex]
      for balanceIndex in 0 .. branchBalances.len - 1:
        let storageBalance = branchBalances[balanceIndex]
        if bestStamp[storageBalance] != stampCounter or branchWeight[storageBalance] > bestWeight[storageBalance]:
          bestStamp[storageBalance] = stampCounter
          bestWeight[storageBalance] = branchWeight[storageBalance]
          bestOwner[storageBalance] = ownerId
          touchedBalances.add(storageBalance)
```

The centroid counts as its own branch, so endpoint paths work.
Queries read only earlier branches, so duplicates are excluded.
Merging happens after the whole branch has been scanned.

```nim
  for balanceIndex in 0 .. touchedBalances.len - 1:
    bestStamp[touchedBalances[balanceIndex]] = -1

  centroidEdge = edgeHead[centroidSchool]
  while centroidEdge != 0:
    let neighborSchool = edgeTarget[centroidEdge]
    if not isRemoved[neighborSchool]:
      decompositionStack.add(neighborSchool)
    centroidEdge = edgeNext[centroidEdge]

appendOutput($(bestAnswer))
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Stamps clear touched entries without clearing the whole array.
Each surviving component is queued for another centroid round.
The final answer is written once.

## Complexity

Every decomposition level visits each node in its component once.

| phase | time | space |
|---|---|---|
| tree build | one pass over parent links | adjacency arrays |
| centroid search | one pass per component | subtree sizes |
| balance merge | one pass per component | balance arrays |
| output | one line | block buffer |

The decomposition depth bounds the total repeated visits.

| measure | Big O |
|---|---|
| time | O(n log n) |
| space | O(n) |

Checking all school pairs would cost O(n^2) time, which is slower.
Centroid decomposition makes each path meet at one separating node, which is the takeaway.
