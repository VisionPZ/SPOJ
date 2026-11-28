# VECTAR5 — Count Subsets (SPOJ)

<https://www.spoj.com/problems/VECTAR5/>

## Problem

Count ordered pairs of nonempty subsets A and B of `{1, 2, ..., n}` where neither subset contains the other, and print the count modulo 1000000007. Each element may sit in neither subset, in A only, in B only, or in both.

The first line holds the case count. Each later line holds one value of n. Print one residue per case.

| Item | Bound |
|---|---|
| Cases T | 1 to 100000 |
| Set size n | 1 to 1000000 |
| Judge limit | 1000 ms, 1536 MB |

The modulus is prime and equals 1000000007.

The sample asks for two set sizes:

```
2
4
8
```

The expected output is:

```
110
52670
```

## Idea

Sort each element into four boxes like guests at a party: absent, A only, B only, or both, and require at least one guest in each single box. That gives all four placements minus the ones missing an A-only or a B-only guest. Use inclusion-exclusion and precompute the powers of two, three, and four once. Enumerating all subset pairs would take 4ⁿ steps, while each answer after precomputation takes one table lookup.

## Why It Works

1. Each of the n elements has four placements, so there are 4ⁿ ordered pairs of subsets.
2. A is not a subset of B exactly when some element lies in A only.
3. B is not a subset of A exactly when some element lies in B only.
4. Placements with no A-only element offer three choices each, giving 3ⁿ.
5. Placements with no B-only element also number 3ⁿ.
6. Placements with neither single box used offer two choices each, giving 2ⁿ.
7. Inclusion-exclusion removes both bad families and adds back their overlap: 4ⁿ - 2·3ⁿ + 2ⁿ.
8. Requiring an A-only and a B-only element also makes both subsets nonempty.

| Term | Meaning |
|---|---|
| `moduloValue` | the prime 1000000007 |
| `powersOfTwo` | residues of 2 raised to each exponent |
| `powersOfThree` | residues of 3 raised to each exponent |
| `powersOfFour` | residues of 4 raised to each exponent |
| `queries` | the requested set sizes |
| `maximumQuery` | largest requested size, which bounds the tables |

Adding twice the modulus before taking the residue keeps the subtraction nonnegative.

For n = 4 the tables give:

```
4^4 = 256
3^4 = 81
2^4 = 16
256 - 2 * 81 + 16 = 110
```

The trace matches the first sample answer.

## Code

**Input and scanning.** The reader collects all queries before building any table.

```nim
const flushBlockBytes = 1 shl 17
const moduloValue = 1000000007

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

let caseCount = nextInt(inputData, scanPos)
var queries = newSeq[int](caseCount)
var maximumQuery = 0
for caseIndex in 0 .. caseCount - 1:
  queries[caseIndex] = nextInt(inputData, scanPos)
  if queries[caseIndex] > maximumQuery:
    maximumQuery = queries[caseIndex]
```

Reading first gives the table size in one pass.
The scanner skips spaces and line breaks between queries.
All queries are positive, so no sign branch appears.

**Power tables.** Three recurrences fill every needed exponent.

```nim
var powersOfTwo = newSeq[int64](maximumQuery + 1)
var powersOfThree = newSeq[int64](maximumQuery + 1)
var powersOfFour = newSeq[int64](maximumQuery + 1)
powersOfTwo[0] = 1
powersOfThree[0] = 1
powersOfFour[0] = 1
for exponent in 1 .. maximumQuery:
  powersOfTwo[exponent] = powersOfTwo[exponent - 1] * 2 mod moduloValue
  powersOfThree[exponent] = powersOfThree[exponent - 1] * 3 mod moduloValue
  powersOfFour[exponent] = powersOfFour[exponent - 1] * 4 mod moduloValue
```

Each step multiplies the previous residue by its base.
Products stay in 64 bits because the modulus is about one billion.
Exponents stop at the largest query, never at a guessed limit.

**Answers.** Inclusion-exclusion produces one residue per case.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

for caseIndex in 0 .. caseCount - 1:
  let query = queries[caseIndex]
  var answer = powersOfFour[query] - 2 * powersOfThree[query] + powersOfTwo[query]
  answer = (answer + 2 * int64(moduloValue)) mod int64(moduloValue)
  appendOutput($answer)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The shift by twice the modulus prevents a negative residue.
One line is appended for each case in input order.
The final write flushes the remaining block.

## Complexity

The power tables dominate, and each query is a constant lookup.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over the query list | one input string and query list |
| Power tables | three steps per exponent up to the largest query | three residue tables |
| Output | one line per case | block buffer |

No subset is ever enumerated.

| Measure | Big O |
|---|---|
| Time | O(T + max n) |
| Space | O(T + max n) |

Enumerating all 4ⁿ subset pairs per case would be exponential, so the closed form wins.
