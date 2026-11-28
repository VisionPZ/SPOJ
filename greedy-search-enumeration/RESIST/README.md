# RESIST — Kirchhof Law (SPOJ)

<https://www.spoj.com/problems/RESIST/>

## Problem

An electrical network has nodes and resistors between them. Report the equivalent resistance between node 1 and node N, rounded to two digits after the decimal point. The input ends at end of file.

Each case starts with N and M. Each of the next M lines gives two endpoint nodes and the resistance. A blank line separates consecutive cases, and no other whitespace appears. Print one resistance per case.

| item | bound |
|---|---|
| nodes N | more than 2, at most 100 |
| resistors M | 0 to 300 |
| resistance per resistor | 1 to 100 |
| judge limit | 500 ms, 1536 MB |

The node count keeps a dense linear system affordable.

Sample input:

```
4 5
1 2 15
2 4 5
1 3 10
3 4 10
2 3 1
```

Sample output:

```
9.40
```

The five resistors combine to 9.40 ohms between nodes 1 and 4.

## Idea

Treat node N as zero volts and push one ampere into node 1, like measuring pressure at a tap with a known flow. Kirchhoff's current law gives one linear equation per remaining node, and the voltage at node 1 equals the resistance. This is nodal analysis with Gaussian elimination and partial pivoting. Each case costs O(N^3) time and O(N^2) space. Building every series and parallel combination by hand has no simple general form, so solving the linear system is the reliable route. Set one node to ground, solve once, and read the answer at the source node.

## Why It Works

1. Current through a resistor equals conductance times the voltage difference across it.
2. Conductance is the reciprocal of resistance, so each edge adds conductance to its two endpoint diagonals and subtracts it from their cross entries.
3. Kirchhoff's law says the sum of currents leaving a node is zero, except at node 1 where one ampere enters.
4. With node N fixed at zero volts, the remaining N - 1 equations have a unique solution for a connected network.
5. One ampere enters at node 1, so its voltage equals the equivalent resistance by Ohm's law.

| term | meaning |
|---|---|
| `system` | conductance matrix with the current vector in its last column |
| `conductance` | reciprocal of a resistor's resistance |
| `potentials` | solved voltages at nodes 1 to N - 1 |
| `scaledValue` | voltage multiplied by 100 before rounding |

Gaussian elimination with row swaps keeps the solve stable for small dense systems.

A trace of the sample solve:

| quantity | value |
|---|---|
| ground node | 4 |
| injected current | 1 ampere at node 1 |
| solved voltage at node 1 | 9.3999999999 |
| printed result | 9.40 |

The printed value matches the sample output.

## Code

**Input helpers and buffered output.** One read pass loads the whole input, and a probe detects end of file.

```nim
const flushBlockBytes = 1 shl 17

proc hasMoreData(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len and (data[cursor] < '0' or data[cursor] > '9'):
    cursor += 1
  return cursor < data.len

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendResistance(value: float) =
  let scaledValue = int(value * 100.0 + 0.5000001)
  let wholePart = scaledValue div 100
  let fractionPart = scaledValue mod 100
  appendOutput($wholePart)
  appendOutput(".")
  if fractionPart < 10:
    appendOutput("0")
  appendOutput($fractionPart)
  outputBuffer.add '\n'
```

Blank lines hold no digits, so the scanner skips them.
Rounding happens once on the scaled integer.
The fraction always prints two digits.

**Matrix assembly.** Each resistor contributes conductance to four entries, except at ground.

```nim
while hasMoreData(inputData, scanPos):
  let nodeCount = nextInt(inputData, scanPos)
  let resistorCount = nextInt(inputData, scanPos)
  let systemSize = nodeCount - 1
  var system = newSeq[seq[float64]](systemSize)
  for rowIndex in 0 .. systemSize - 1:
    system[rowIndex] = newSeq[float64](systemSize + 1)
  for resistorIndex in 0 .. resistorCount - 1:
    let firstNode = nextInt(inputData, scanPos) - 1
    let secondNode = nextInt(inputData, scanPos) - 1
    let resistanceValue = nextInt(inputData, scanPos)
    if firstNode == secondNode:
      continue
    let conductance = 1.0 / float(resistanceValue)
    let firstIsGround = firstNode == nodeCount - 1
    let secondIsGround = secondNode == nodeCount - 1
    if not firstIsGround:
      system[firstNode][firstNode] += conductance
    if not secondIsGround:
      system[secondNode][secondNode] += conductance
    if not firstIsGround and not secondIsGround:
      system[firstNode][secondNode] -= conductance
      system[secondNode][firstNode] -= conductance
  system[0][systemSize] += 1.0
  for rowIndex in 0 .. systemSize - 1:
    var rowIsEmpty = true
    for columnIndex in 0 .. systemSize - 1:
      if system[rowIndex][columnIndex] != 0.0:
        rowIsEmpty = false
    if rowIsEmpty:
      system[rowIndex][rowIndex] = 1.0
```

Self-connected edges change nothing and are skipped.
An isolated node gets a harmless unit equation.
The last column holds the injected current.

**Solve and print.** Partial pivoting removes zeros from the diagonal before back substitution.

```nim
  for columnIndex in 0 .. systemSize - 1:
    var pivotRow = columnIndex
    var pivotSize = abs(system[columnIndex][columnIndex])
    for rowIndex in columnIndex + 1 .. systemSize - 1:
      let candidateSize = abs(system[rowIndex][columnIndex])
      if candidateSize > pivotSize:
        pivotSize = candidateSize
        pivotRow = rowIndex
    if pivotRow != columnIndex:
      let temporaryRow = system[columnIndex]
      system[columnIndex] = system[pivotRow]
      system[pivotRow] = temporaryRow
    if system[columnIndex][columnIndex] == 0.0:
      continue
    let pivotValue = system[columnIndex][columnIndex]
    for rowIndex in columnIndex + 1 .. systemSize - 1:
      let eliminationFactor = system[rowIndex][columnIndex] / pivotValue
      if eliminationFactor == 0.0:
        continue
      system[rowIndex][columnIndex] = 0.0
      for innerColumn in columnIndex + 1 .. systemSize:
        system[rowIndex][innerColumn] -= eliminationFactor * system[columnIndex][innerColumn]
  var potentials = newSeq[float64](systemSize)
  for rowIndex in countdown(systemSize - 1, 0):
    if system[rowIndex][rowIndex] == 0.0:
      potentials[rowIndex] = 0.0
      continue
    var rowTotal = system[rowIndex][systemSize]
    for columnIndex in rowIndex + 1 .. systemSize - 1:
      rowTotal -= system[rowIndex][columnIndex] * potentials[columnIndex]
    potentials[rowIndex] = rowTotal / system[rowIndex][rowIndex]
  appendResistance(potentials[0])

stdout.write outputBuffer
outputBuffer.setLen 0
```

Row swaps pick the largest available pivot.
Back substitution walks from the last row to the first.
One buffered write emits every case at the end.

## Complexity

A dense system of size N - 1 dominates each case.

| phase | time | space |
|---|---|---|
| input read | one pass over the numbers | one input string |
| matrix assembly | O(M) | N by N matrix |
| elimination | O(N^3) | same matrix |
| output | one buffered line per case | block buffer |

Elimination sets the cost when M is small.

| measure | Big O |
|---|---|
| time | O(N^3 + M) per case |
| space | O(N^2) per case |

Collapsing resistors by hand has no general polynomial recipe, while nodal analysis handles any network in cubic time. Ground one node, inject one ampere, and solve once.
