# FN16CEIL — Ceiling Function (SPOJ)

<https://www.spoj.com/problems/FN16CEIL/>

## Problem

Each prototype is a list of distinct layer values. Inserting them in order into a binary search tree gives a shape. Two lists belong together when their trees have the same shape. Report how many different shapes occur in each test case.

Input starts with two integers `n` and `k`. The value `n` is the number of prototypes, and `k` is the number of layers per prototype. The next `n` lines each hold `k` distinct integers from 1 to 1000000. Several test cases follow until end of file. Output one line per test case with the number of different shapes.

| item | bound |
|---|---|
| prototypes per case n | 1 to 50 |
| layers per prototype k | 1 to 20 |
| layer value | 1 to 1000000 |
| test cases | until end of file |
| judge limit | 1000 ms, 1536 MB |

Only comparison outcomes matter, so equal value ranks act like equal layer values.

Sample input:

```
5 3
2 7 1
3 1 4
1 5 9
2 6 5
9 7 3
3 4
3 1 2 40000
3 4 2 1
33 42 17 23
```

Sample output:

```
4
2
```

## Idea

Shape is like a family tree of left and right branches: names on the nodes do not change its outline. Replace each value by its rank, insert the ranks into a binary search tree, and write the tree as a string of parentheses. Each new string adds one shape. Scanning all prototypes costs `n` insertions of `k` ranks. Comparing raw values with full trees would rebuild and recompare every node for every pair; the string reduces each tree to one comparable key. Short takeaway: rank first, then serialize the outline.

## Why It Works

1. Insertion compares only relative order, so ranks determine every branch decision.
2. Sorting the values of one prototype gives each value a unique rank.
3. The insertion rule sends a smaller rank left and any other rank right.
4. A string with one opening bracket per node records both children of every node.
5. Two trees have the same shape exactly when their strings match.

| term | meaning |
|---|---|
| `ordered` | values of one prototype sorted by insertion sort |
| `ranks` | position of each value inside `ordered` |
| `leftChild` | index of the left child of each inserted node |
| `signature` | parenthesised string describing one tree shape |
| `signatures` | distinct strings collected so far |

The two prototypes `(2, 7, 1)` and `(3, 1, 4)` give ranks `1, 2, 0` and `1, 0, 2`. Both trees have a root with one child on each side, so both produce the same signature. The prototype `(1, 5, 9)` produces a chain of right children and a different signature.

Ranks are integers, so no rounding is needed. The insertion loop stops once every rank finds an empty child slot.

## Code

**Input and scanning.** The hand reader loads every test case into one string.

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

proc hasNextToken(data: string, pos: int): bool =
  var checkPos = pos
  while checkPos < data.len:
    if data[checkPos] >= '0' and data[checkPos] <= '9':
      return true
    checkPos += 1
  return false
```

The scanner skips separators and builds each value one digit at a time.
The token check stops the loop cleanly at end of file.
All input values are positive, so the scanner needs no minus branch.

**Tree shape.** The code compresses values to ranks and serialises the built tree.

```nim
proc serializeShape(leftChild: seq[int], rightChild: seq[int], nodeIndex: int): string =
  if nodeIndex == -1:
    return "."
  result = "("
  result.add serializeShape(leftChild, rightChild, leftChild[nodeIndex])
  result.add serializeShape(leftChild, rightChild, rightChild[nodeIndex])
  result.add ")"

proc shapeSignature(values: seq[int]): string =
  var ordered = newSeq[int](values.len)
  for index in 0 .. values.len - 1:
    ordered[index] = values[index]
  for index in 1 .. ordered.len - 1:
    let key = ordered[index]
    var previousIndex = index - 1
    while previousIndex >= 0 and ordered[previousIndex] > key:
      ordered[previousIndex + 1] = ordered[previousIndex]
      previousIndex -= 1
    ordered[previousIndex + 1] = key
  var ranks = newSeq[int](values.len)
  for index in 0 .. values.len - 1:
    var low = 0
    var high = ordered.len - 1
    while low <= high:
      let middle = (low + high) div 2
      if ordered[middle] == values[index]:
        ranks[index] = middle
        break
      elif ordered[middle] < values[index]:
        low = middle + 1
      else:
        high = middle - 1
  var leftChild = newSeq[int](values.len)
  var rightChild = newSeq[int](values.len)
  for index in 0 .. values.len - 1:
    leftChild[index] = -1
    rightChild[index] = -1
  if values.len > 0:
    for index in 1 .. values.len - 1:
      let insertedRank = ranks[index]
      var currentNode = 0
      while true:
        if insertedRank < ranks[currentNode]:
          if leftChild[currentNode] == -1:
            leftChild[currentNode] = index
            break
          currentNode = leftChild[currentNode]
        else:
          if rightChild[currentNode] == -1:
            rightChild[currentNode] = index
            break
          currentNode = rightChild[currentNode]
  return serializeShape(leftChild, rightChild, 0)
```

Insertion sort handles at most twenty values per prototype.
Each rank walks down from the root until an empty child appears.
The recursive writer emits one bracket pair per node and a dot per empty child.

**Counting and output.** The driver keeps one string for all answers.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while hasNextToken(inputData, scanPos):
  let protoCount = nextInt(inputData, scanPos)
  let layerCount = nextInt(inputData, scanPos)
  var signatures = newSeq[string](0)
  for protoIndex in 0 .. protoCount - 1:
    var values = newSeq[int](layerCount)
    for layerIndex in 0 .. layerCount - 1:
      values[layerIndex] = nextInt(inputData, scanPos)
    let signature = shapeSignature(values)
    var seen = false
    for previousSignature in signatures:
      if previousSignature == signature:
        seen = true
        break
    if not seen:
      signatures.add signature
  appendOutput($signatures.len)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

A linear scan over previous signatures keeps the code small.
It compares at most fifty short strings per prototype.
One final write flushes the remaining buffer after the last test case.

## Complexity

Each prototype is ranked, inserted, and serialised once.

| phase | time | space |
|---|---|---|
| input read | one pass over all tokens | one input string |
| ranking | insertion sort of k values | two arrays of k integers |
| shape write | one string per prototype | one string per distinct shape |
| output | one line per test case | block buffer |

| measure | Big O |
|---|---|
| time per test case | O(n * k log k) |
| space per prototype | O(k) |

A direct tree-to-tree comparison would compare every node pair for every prototype pair. The signature turns that repeated work into one string comparison. Short takeaway: compress each tree once, then count distinct keys.
