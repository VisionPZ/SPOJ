<https://www.spoj.com/problems/FCATTLE/>

## Problem

Choose one rectangular pasture of area at most `A` so the cow survives the most days. Each day the cow needs one herb of the type listed in the medicine sequence, and each chosen cell feeds the cow once. Ties go to the rectangle with the smallest top row, then left column, then bottom row, then right column.

Each case starts with `R C A`. The next line lists medicine types up to -1. Then `R` rows of `C` herb types follow. Three zeros end the input. Output five integers: `days r1 c1 r2 c2`.

| item | bound |
|---|---|
| rows R and columns C | 1 to 200 |
| rectangle area | at most A, with A > 1 |
| medicine types and herbs | non-negative integers |
| judge limit | 1000 ms, 1536 MB |

The sample input:

```
3 4 6
12 30 12 100 22 -1
30 12 5 3
12 30 100 5
22 3 22 100
3 4 6
2 30 12 100 22 -1
30 12 5 3
12 30 100 5
22 3 22 100
3 4 6
12 30 12 100 22 -1
30 12 5 3
12 30 100 5
22 12 22 100
0 0 0
```

The sample output:

```
4 1 1 2 3
0 1 1 1 1
5 1 2 3 3
```

## Idea

Think of each herb type as a queue of days it must serve. If a rectangle holds `c` herbs of a type, it can reach the day preceding that type's `(c+1)`-th need. The weakest type sets the survival length, like the shortest board in a barrel. A min segment tree tracks that weakest type while a rectangle grows column by column.

## Why It Works

1. The cow needs one herb of the listed type each day. A rectangle supports day `d` exactly when it holds enough herbs of that type for days `1..d`.
2. For type `t`, let `p_c` be the day of its `c`-th medicine occurrence. With `c` herbs available, the last fully supported day is `p_(c+1) - 1`, or the whole sequence when no next occurrence exists.
3. The rectangle survives `min` of those per-type limits, because every type must last through each day.
4. A point-update min segment tree holds one limit per type, so the root is the current survival length after each added cell.
5. Extending a rectangle only adds herbs, so the survival length never falls while the right column moves right.
6. Iterating top row, then bottom row, then left column, then right column, and comparing explicit tie-break keys yields the required lexicographically smallest rectangle.
7. Resetting only the types touched during one left-column scan keeps the tree state consistent between scans.

| term | meaning |
|---|---|
| `typeValues` | distinct medicine herb types |
| `occurrences` | days on which each type is needed |
| `nextDays` | day of the `(c+1)`-th need for each count `c` |
| `segmentMin` | minimum per-type support, stored in a segment tree |
| `typeCounts` | herbs of each type inside the current rectangle |

The table maps each array to the role it plays.

A worked trace for rectangle rows 1-2, columns 1-3 of the first sample case:

| type | herbs | next needed day | supported day |
|---|---|---|---|
| 12 | 2 | none | 5 |
| 30 | 2 | none | 5 |
| 100 | 1 | none | 5 |
| 22 | 0 | 5 | 4 |

The weakest type is 22, so the rectangle feeds the cow for 4 days.

## Code

**Input and scanner.** All input lines enter one buffer, and `nextInt` reads the signed medicine sentinel.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value
```

The minus branch reads the -1 that ends the medicine line.
Herb values are read as plain non-negative tokens.

**Buffered output.** A single string batches result lines into block writes.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`appendOutput` avoids one write per case.
The final write flushes any remaining bytes.

**Medicine types and need days.** Distinct types map to compact indices, and each index records when it is next needed.

```nim
var rowCount = nextInt(inputData, scanPos)
var columnCount = nextInt(inputData, scanPos)
var areaLimit = nextInt(inputData, scanPos)

while not (rowCount == 0 and columnCount == 0 and areaLimit == 0):
  var medicines = newSeq[int]()
  var medicineValue = nextInt(inputData, scanPos)
  while medicineValue != -1:
    medicines.add medicineValue
    medicineValue = nextInt(inputData, scanPos)
  let medicineLength = medicines.len

  var typeValues = newSeq[int]()
  var medicineTypes = newSeq[int](medicineLength)
  for dayIndex in 0 .. medicineLength - 1:
    var found = -1
    for typeIndex in 0 .. typeValues.len - 1:
      if typeValues[typeIndex] == medicines[dayIndex]:
        found = typeIndex
        break
    if found == -1:
      found = typeValues.len
      typeValues.add medicines[dayIndex]
    medicineTypes[dayIndex] = found
  let typeCount = typeValues.len

  var occurrences = newSeq[seq[int]](typeCount)
  for dayIndex in 0 .. medicineLength - 1:
    occurrences[medicineTypes[dayIndex]].add dayIndex + 1
  var nextDays = newSeq[seq[int]](typeCount)
  var occurrenceCounts = newSeq[int](typeCount)
  var initialSupport = newSeq[int](typeCount)
  for typeIndex in 0 .. typeCount - 1:
    let count = occurrences[typeIndex].len
    occurrenceCounts[typeIndex] = count
    nextDays[typeIndex] = newSeq[int](count + 1)
    for occurrenceIndex in 0 .. count - 1:
      nextDays[typeIndex][occurrenceIndex] = occurrences[typeIndex][occurrenceIndex]
    nextDays[typeIndex][count] = medicineLength + 1
    initialSupport[typeIndex] = nextDays[typeIndex][0] - 1
```

A final need day of `medicineLength + 1` means the type never runs out.
The initial support is the day before its first need.

**Minimum segment tree.** One leaf per type holds its support day, and the root holds the weakest one.

```nim
  var segmentSize = 1
  while segmentSize < typeCount:
    segmentSize *= 2
  var segmentMin = newSeq[int](2 * segmentSize)
  for nodeIndex in 0 .. 2 * segmentSize - 1:
    segmentMin[nodeIndex] = medicineLength + 1
  for typeIndex in 0 .. typeCount - 1:
    segmentMin[segmentSize + typeIndex] = initialSupport[typeIndex]
  for nodeIndex in countdown(segmentSize - 1, 1):
    if segmentMin[2 * nodeIndex] < segmentMin[2 * nodeIndex + 1]:
      segmentMin[nodeIndex] = segmentMin[2 * nodeIndex]
    else:
      segmentMin[nodeIndex] = segmentMin[2 * nodeIndex + 1]

  proc setSupport(typeIndex: int, value: int) =
    var nodeIndex = segmentSize + typeIndex
    segmentMin[nodeIndex] = value
    nodeIndex = nodeIndex div 2
    while nodeIndex >= 1:
      if segmentMin[2 * nodeIndex] < segmentMin[2 * nodeIndex + 1]:
        segmentMin[nodeIndex] = segmentMin[2 * nodeIndex]
      else:
        segmentMin[nodeIndex] = segmentMin[2 * nodeIndex + 1]
      nodeIndex = nodeIndex div 2
```

The tree is padded to a power of two, so unused leaves stay large.
`setSupport` walks from the changed leaf back to the root.

**Rectangle scan.** Each right column adds one herb per row, then the root gives the survival length.

```nim
  var gridTypes = newSeq[int](rowCount * columnCount)
  for rowIndex in 0 .. rowCount - 1:
    for columnIndex in 0 .. columnCount - 1:
      let herb = nextInt(inputData, scanPos)
      var found = -1
      for typeIndex in 0 .. typeCount - 1:
        if typeValues[typeIndex] == herb:
          found = typeIndex
          break
      gridTypes[rowIndex * columnCount + columnIndex] = found

  var typeCounts = newSeq[int](typeCount)
  var markGeneration = newSeq[int](typeCount)
  var changedTypes = newSeq[int]()
  var generation = 0
  var bestDays = 0
  var bestTopRow = 1
  var bestLeftColumn = 1
  var bestBottomRow = 1
  var bestRightColumn = 1

  for topRow in 1 .. rowCount:
    let largestHeight = min(rowCount - topRow + 1, areaLimit)
    for bottomRow in topRow .. topRow + largestHeight - 1:
      let height = bottomRow - topRow + 1
      var widthLimit = areaLimit div height
      if widthLimit < 1:
        continue
      if widthLimit > columnCount:
        widthLimit = columnCount
      for leftColumn in 1 .. columnCount:
        generation += 1
        changedTypes.setLen 0
        let maxRight = min(columnCount, leftColumn + widthLimit - 1)
        for rightColumn in leftColumn .. maxRight:
          for rowIndex in topRow .. bottomRow:
            let typeIndex = gridTypes[(rowIndex - 1) * columnCount + rightColumn - 1]
            if typeIndex >= 0:
              if markGeneration[typeIndex] != generation:
                markGeneration[typeIndex] = generation
                changedTypes.add typeIndex
              typeCounts[typeIndex] += 1
              let used = typeCounts[typeIndex]
              var limit = medicineLength + 1
              if used <= occurrenceCounts[typeIndex]:
                limit = nextDays[typeIndex][used]
              setSupport(typeIndex, limit - 1)
          var days = segmentMin[1]
          if days > medicineLength:
            days = medicineLength
          if days > bestDays or
             (days == bestDays and (topRow < bestTopRow or
              (topRow == bestTopRow and (leftColumn < bestLeftColumn or
               (leftColumn == bestLeftColumn and (bottomRow < bestBottomRow or
                (bottomRow == bestBottomRow and rightColumn < bestRightColumn))))))):
            bestDays = days
            bestTopRow = topRow
            bestLeftColumn = leftColumn
            bestBottomRow = bottomRow
            bestRightColumn = rightColumn
          if days == medicineLength:
            break
        for typeIndex in changedTypes:
          typeCounts[typeIndex] = 0
          setSupport(typeIndex, initialSupport[typeIndex])
```

The generation marks types so each one is reset once per left column.
The width limit is `A div height`, which enforces the area bound.
The tie-break comparison keeps the first rectangle when survival lengths match.

**Case output.** The best rectangle is written and the next header is read.

```nim
  appendOutput($bestDays & " " & $bestTopRow & " " & $bestLeftColumn & " " &
               $bestBottomRow & " " & $bestRightColumn & "\n")
  rowCount = nextInt(inputData, scanPos)
  columnCount = nextInt(inputData, scanPos)
  areaLimit = nextInt(inputData, scanPos)

stdout.write outputBuffer
outputBuffer.setLen 0
```

The five fields appear in the exact output order.
The zero header ends the loop before any extra line is written.

## Complexity

Every legal height and left column starts one column scan, and each added cell costs one logarithmic tree update.

| phase | time | space |
|---|---|---|
| medicine setup | one pass over the sequence | need tables per type |
| rectangle scan | one tree update per cell visit | counts and tree arrays |
| tie-break check | constant work per rectangle | five best values |
| output | one append per case | block buffer |

The phase table shows that the rectangle scan dominates.

| measure | Big O |
|---|---|
| time per case | O(R * A * C * log K) |
| space per case | O(R * C + K) |

Testing every rectangle and rescanning all medicine days costs O(R^2 C^2 M) per case. The need tables and the min tree cut each rectangle check to a single root read.
