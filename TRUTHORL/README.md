# TRUTHORL — Truth Or Lie (SPOJ)

<https://www.spoj.com/problems/TRUTHORL/>

## Problem

People answer two different yes-or-no questions, and each person is right on exactly one answer. Count the assignments of yes and no to the questions that agree with every person.

The first integer is the number of test cases. Each case starts with `n` people and `m` questions, then `n` lines of four integers a b c d. The answer to question `a` is `b`, and the answer to question `c` is `d`; 1 means yes and 0 means no. Print `No Inference` when the count is zero or when every assignment survives. Otherwise print the count as a decimal integer.

| item | bound |
|---|---|
| people `n` | at most 10000 |
| questions `m` | at most 200 |
| answers `b` and `d` | 0 or 1 |
| judge limit | 1000 ms, 1536 MB |

The count can reach 2 to the power of 200, so it needs decimal expansion. Let `x_i` be the truth value of question `i`, and let `xor` mean addition modulo two.

Sample input:

```
2
2 2
1 1 2 0
1 1 2 1
4 4
1 1 2 1
1 1 3 0
2 1 4 1
3 1 4 0
```

Sample output:

```
No Inference
2
```

## Idea

Treat each person as a parity equation, like linking two ends of a chain with a known twist. A disjoint-set structure with a parity bit per parent merges the linked questions and detects contradictions. Each free component doubles the answer, so repeated decimal doubling prints the exact count. Checking all 2 to the power of `m` assignments would explode at m = 200, while parity merging stays nearly linear.

The table gives the cost of one person.

| item | bound |
|---|---|
| merge cost | inverse Ackermann amortized |
| decimal expansion | up to 200 doublings |

This cost shape keeps all cases inside the time limit.

## Why It Works

1. A person is correct on exactly one of two questions, so the truth values of those answers differ.
2. Write that fact as x_a xor x_c = 1 xor b xor d, an equation over GF(2).
3. A union-find parent stores the xor between a node and its parent.
4. Path compression accumulates parities, so two roots reveal the xor between their components.
5. A repeated equation with a different parity means zero assignments survive.
6. Otherwise each root component is free, and the solution count is 2 raised to the component count.

The table names the values used in the code.

| term | meaning |
|---|---|
| `requiredXor` | parity required by one person |
| `parents` | union-find parent for each question |
| `parities` | xor from a question to its parent |
| `rootXor` | parity between the two component roots |
| `componentCount` | number of free components |

The code stores one parity byte per question.

The worked example uses the second sample case. The script derives four equations and one free component.

```
person 1: x1 xor x2 = 1
person 2: x1 xor x3 = 0
person 3: x2 xor x4 = 1
person 4: x3 xor x4 = 0
components = 1
free questions = 1
assignments = 2
```

The first sample case forces both x1 xor x2 = 1 and x1 xor x2 = 0, so it prints `No Inference`.

## Code

**Input, union-find, and big output.** The reader parses triples, and parity merging detects contradictions.

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

proc findRoot(parents: var seq[int], parities: var seq[int], node: int): int =
  if parents[node] == node:
    return node
  let oldParent = parents[node]
  let root = findRoot(parents, parities, oldParent)
  parities[node] = parities[node] xor parities[oldParent]
  parents[node] = root
  return root

proc powerOfTwoString(exponent: int): string =
  result = "1"
  for step in 0 .. exponent - 1:
    var carry = 0
    var digitIndex = result.len - 1
    while digitIndex >= 0:
      let doubled = 2 * (int(result[digitIndex]) - 48) + carry
      result[digitIndex] = char(doubled mod 10 + 48)
      carry = doubled div 10
      digitIndex -= 1
    if carry > 0:
      result = "1" & result

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Path compression folds parity on the way back to the root. Decimal doubling runs from the least significant digit. The writer flushes whole blocks, not single answers.

**Case processing.** Every person adds one parity constraint and may invalidate the whole case.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let personCount = nextInt(inputData, scanPos)
  let questionCount = nextInt(inputData, scanPos)
  var parents = newSeq[int](questionCount)
  var parities = newSeq[int](questionCount)
  for questionIndex in 0 .. questionCount - 1:
    parents[questionIndex] = questionIndex
    parities[questionIndex] = 0
  var consistent = true
  for personIndex in 0 .. personCount - 1:
    let firstQuestion = nextInt(inputData, scanPos) - 1
    let firstAnswer = nextInt(inputData, scanPos)
    let secondQuestion = nextInt(inputData, scanPos) - 1
    let secondAnswer = nextInt(inputData, scanPos)
    if not consistent:
      continue
    let requiredXor = 1 xor firstAnswer xor secondAnswer
    let firstRoot = findRoot(parents, parities, firstQuestion)
    let firstParity = parities[firstQuestion]
    let secondRoot = findRoot(parents, parities, secondQuestion)
    let secondParity = parities[secondQuestion]
    let rootXor = requiredXor xor firstParity xor secondParity
    if firstRoot == secondRoot:
      if rootXor != 0:
        consistent = false
    else:
      parents[secondRoot] = firstRoot
      parities[secondRoot] = rootXor
  if not consistent:
    appendOutput("No Inference")
  else:
    var componentCount = 0
    for questionIndex in 0 .. questionCount - 1:
      if parents[questionIndex] == questionIndex:
        componentCount += 1
    if componentCount == questionCount:
      appendOutput("No Inference")
    else:
      appendOutput(powerOfTwoString(componentCount))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Question numbers are converted to zero-based indexes. A contradiction still consumes all four input integers. The component count drives the exact power of two.

## Complexity

Each person performs two finds, and each case expands one decimal power.

| phase | time | space |
|---|---|---|
| input read | one pass over all integers | one input string |
| parity merging | near linear in people plus questions | two arrays of `m` integers |
| decimal expansion | up to `m` doublings | one decimal string |

The two arrays are the main working storage.

| measure | Big O |
|---|---|
| time | O((n + m) alpha(m) + m^2 / word) per case |
| space | O(m) |

Enumerating all assignments costs exponential time, while parity merging stays near linear.
