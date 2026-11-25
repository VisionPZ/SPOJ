# ADAHLIA — Ada and Dahlia (SPOJ)

<https://www.spoj.com/problems/ADAHLIA/>

## Problem

A generator produces flower diameters with the recurrence A[i+1] = (a*A[i] + b) mod c. Sort all N diameters and report the largest gap between neighbouring values.

Input is one line with N, a, b, c and A[0]. Output one integer, the maximum sorted gap.

| item | bound |
|---|---|
| flowers N | 2 to 40000000 |
| multiplier a | 0 to 10^18 |
| offset b | 0 to 10^18 |
| modulus c | 1 to 10^18 |
| judge limit | 4000 ms, 1536 MB |

The product a*A[i] can reach 10^36, so the generator needs a 128-bit product.

Sample input:

```
10 2 3 31 7
```

The sample generates ten diameters from modulus 31.

Sample output:

```
8
```

The sorted diameters are 2, 2, 6, 6, 7, 7, 15, 15, 17, 17.

## Idea

Sorting forty million numbers is like sorting a whole library to find the widest shelf gap. Divide the value range into N equal buckets instead. The widest gap across buckets is at least one bucket width, so any gap inside one bucket cannot win. Track the minimum and maximum value per bucket, then compare neighbouring nonempty buckets. Two generator passes avoid storing all diameters, and a 128-bit helper computes each product exactly. Generate twice, then compare bucket edges.

## Why It Works

1. With N values spanning S, the largest sorted gap is at least S/N, the bucket width.
2. Two values in one bucket differ by less than that width, so the winning gap crosses a bucket boundary.
3. The smallest value in a bucket and the largest value in the previous nonempty bucket give the exact gap between those groups.
4. Generating the sequence twice replaces an array of N diameters with two arrays of bucket bounds.

| term | meaning |
|---|---|
| `bucketWidth` | value span divided by the flower count |
| `bucketMinimums` | smallest diameter in each bucket |
| `bucketMaximums` | largest diameter in each bucket |
| `multiplyModulo` | exact product modulo c using a 128-bit intermediate |

The four terms cover the bucket layout and the exact generator step.

A script trace of the sample:

```
generated: 7 17 6 15 2 7 17 6 15 2
sorted:    2 2 6 6 7 7 15 15 17 17
gaps:      0 4 0 1 0 8 0 2 0
bucket width: 15 / 10 = 1
max gap: 8
```

The gap from 7 to 15 is the largest, which matches the sample output.

## Code

**Input and helpers.** The reader loads five parameters, and the helper computes an exact modular product.

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc multiplyModulo(firstFactor, secondFactor, modulusValue: int64): int64 {.
    importc: "multiply_modulo_words", cdecl.}

{.emit: """
NI64 multiply_modulo_words(NI64 firstFactor, NI64 secondFactor, NI64 modulusValue) {
  return (NI64)((__int128)firstFactor * (__int128)secondFactor % (__int128)modulusValue);
}
""".}
```

The scanner builds 64-bit values directly from digits.
The emitted helper uses a 128-bit intermediate before reducing modulo c.
One buffer collects the single output line.

**First pass.** One generation pass finds the smallest and largest diameters.

```nim
let flowerCount = nextInt(inputData, scanPos)
let generationFactor = int64(nextInt(inputData, scanPos))
let generationOffset = int64(nextInt(inputData, scanPos))
let generationModulus = int64(nextInt(inputData, scanPos))
let startingDiameter = int64(nextInt(inputData, scanPos))

var smallestDiameter = high(int64)
var largestDiameter = -1'i64
var currentDiameter = startingDiameter
for flowerIndex in 0 .. flowerCount - 1:
  if currentDiameter < smallestDiameter:
    smallestDiameter = currentDiameter
  if currentDiameter > largestDiameter:
    largestDiameter = currentDiameter
  currentDiameter = (multiplyModulo(generationFactor, currentDiameter, generationModulus) + generationOffset) mod generationModulus
```

The extremes define the bucket width without a full sort.
A constant sequence leaves the largest diameter equal to the smallest.
Each step adds the offset before reducing, exactly as the formula states.

**Second pass.** A fresh generation pass fills bucket bounds, then bucket edges give the answer.

```nim
var largestGap: int64 = 0
if largestDiameter > smallestDiameter:
  let diameterSpan = largestDiameter - smallestDiameter
  var bucketWidth = diameterSpan div int64(flowerCount)
  if bucketWidth < 1'i64:
    bucketWidth = 1'i64
  let bucketCount = int(diameterSpan div bucketWidth) + 1
  var bucketMinimums = newSeq[int64](bucketCount)
  var bucketMaximums = newSeq[int64](bucketCount)
  for bucketIndex in 0 .. bucketCount - 1:
    bucketMinimums[bucketIndex] = high(int64)
    bucketMaximums[bucketIndex] = -1'i64
  currentDiameter = startingDiameter
  for flowerIndex in 0 .. flowerCount - 1:
    let bucketIndex = int((currentDiameter - smallestDiameter) div bucketWidth)
    if currentDiameter < bucketMinimums[bucketIndex]:
      bucketMinimums[bucketIndex] = currentDiameter
    if currentDiameter > bucketMaximums[bucketIndex]:
      bucketMaximums[bucketIndex] = currentDiameter
    currentDiameter = (multiplyModulo(generationFactor, currentDiameter, generationModulus) + generationOffset) mod generationModulus
  var previousMaximum = smallestDiameter
  var havePreviousBucket = false
  for bucketIndex in 0 .. bucketCount - 1:
    if bucketMaximums[bucketIndex] >= 0'i64:
      if havePreviousBucket:
        let bucketGap = bucketMinimums[bucketIndex] - previousMaximum
        if bucketGap > largestGap:
          largestGap = bucketGap
      previousMaximum = bucketMaximums[bucketIndex]
      havePreviousBucket = true

appendOutput($largestGap)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The bucket count never exceeds the flower count plus one.
A width of zero is raised to one so division stays defined.
Only nonempty buckets take part in the final comparison.

## Complexity

Two generation passes replace sorting and full storage of the sequence.

| phase | time | space |
|---|---|---|
| first pass | N generator steps | constant |
| second pass | N bucket updates | two arrays of bucket bounds |
| bucket scan | one pass over buckets | constant |
| output | one buffered write | block buffer |

Bucket count stays below N + 1 for every input.

| measure | Big O |
|---|---|
| time | O(N) |
| space | O(N) |

Sorting forty million values would need O(N log N) comparisons and a large value array. Buckets keep the work linear.
