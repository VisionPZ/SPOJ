<https://www.spoj.com/problems/BLCATS/>

## Problem

Cats sit in a circle with colors white, red, or green. In each step, consecutive pairs talk in order, and two different colors both become the third color. Report the colors after k steps.

| item | bound |
|---|---|
| cats n | 1 to 50000 |
| steps k | 1 to 1000000000 |
| judge limit | 5000 ms, 1536 MB |

Pairs are processed in index order, from pair one-two through pair n-one.

Sample input:

```
3 1
GRR
```

Sample output:

```
RGR
```

## Idea

Treat colors as digits zero, one, and two, like dial positions that always sum to zero modulo three. A conversation then sets both dials to the negative sum of their values, even when the values match. This is a linear map, so powers of its matrix give the answer for large k. Storing the matrix as one edge vector plus one diagonal band keeps the data linear, and a number-theoretic transform multiplies two such matrices in O(n log n). Binary exponentiation finishes the job.

## Why It Works

1. Colors zero, one, and two sum to three, which is zero modulo three.
2. For two different colors a and b, the third color is minus a minus b modulo three.
3. For equal colors a and a, the same formula returns a because minus two a equals a modulo three.
4. One step is therefore a fixed linear map on the color vector.
5. Every power of that map keeps one edge vector and one Toeplitz diagonal band.
6. Convolutions of those compact arrays rebuild the product after each squaring.

| term | meaning |
|---|---|
| `edgeValues` | first two columns of the one-step matrix, which are equal per row |
| `bandValues` | diagonal band holding entries from column two onward |
| `offsetValue` | shift from a diagonal distance to an array index |
| `transformModulus` | prime used by the convolution transform |

A worked step with G R R uses digits two, one, one. Pair one gives minus three, or zero, so the state becomes zero, zero, one. Pair two gives minus one, or two, so the state becomes zero, two, two. Pair three gives minus two, or one, so the final state is one, two, one, which prints R G R.

## Code

**Input, output, and modular helper.** The reader loads sizes and colors, and the modular power supports the transform.

```nim
const flushBlockBytes = 1 shl 17
const transformModulus = 998244353
const transformRoot = 3

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

proc mod3(value: int): int =
  ((value mod 3) + 3) mod 3

proc powerUnderModulus(baseValue: int64, exponentValue: int64): int64 =
  var runningBase = baseValue
  var runningExponent = exponentValue
  var resultValue = int64(1)
  while runningExponent > 0:
    if (runningExponent mod 2) == 1:
      resultValue = (resultValue * runningBase) mod transformModulus
    runningBase = (runningBase * runningBase) mod transformModulus
    runningExponent = runningExponent div 2
  return resultValue
```

Color digits stay small, so products fit the transform prime.
The hand scanner ignores the newline before the color row.
Output is buffered in blocks like every other solution.

**Transform and convolution.** The number-theoretic transform multiplies two compact arrays.

```nim
proc forwardTransform(values: var seq[int64], inverted: bool) =
  let lengthValue = values.len
  var reversedIndex = 0
  for indexValue in 1 .. lengthValue - 1:
    var bitValue = lengthValue div 2
    while (reversedIndex and bitValue) != 0:
      reversedIndex = reversedIndex xor bitValue
      bitValue = bitValue div 2
    reversedIndex = reversedIndex xor bitValue
    if indexValue < reversedIndex:
      swap values[indexValue], values[reversedIndex]

  var blockLength = 2
  while blockLength <= lengthValue:
    var stepRoot = powerUnderModulus(transformRoot, (transformModulus - 1) div blockLength)
    if inverted:
      stepRoot = powerUnderModulus(stepRoot, transformModulus - 2)
    var blockStart = 0
    while blockStart < lengthValue:
      var currentRoot = int64(1)
      let halfBlock = blockLength div 2
      for offsetValue in 0 .. halfBlock - 1:
        let leftValue = values[blockStart + offsetValue]
        let rightValue = (values[blockStart + offsetValue + halfBlock] * currentRoot) mod transformModulus
        values[blockStart + offsetValue] = (leftValue + rightValue) mod transformModulus
        values[blockStart + offsetValue + halfBlock] = (leftValue - rightValue + transformModulus) mod transformModulus
        currentRoot = (currentRoot * stepRoot) mod transformModulus
      blockStart += blockLength
    blockLength = blockLength * 2

  if inverted:
    let inverseLength = powerUnderModulus(int64(lengthValue), transformModulus - 2)
    for indexValue in 0 .. lengthValue - 1:
      values[indexValue] = (values[indexValue] * inverseLength) mod transformModulus
```

Bit reversal prepares the array for the in-place butterfly.
The inverse pass divides by the transform length.
Small inputs take a direct convolution instead.

**Convolution wrappers.** One prepared transform serves two products that share a right operand.

```nim
proc naiveConvolution(leftValues: seq[int], rightValues: seq[int], neededLength: int): seq[int] =
  var naiveResult = newSeq[int](neededLength)
  for leftIndex in 0 .. leftValues.len - 1:
    if leftValues[leftIndex] == 0:
      continue
    for rightIndex in 0 .. rightValues.len - 1:
      if rightValues[rightIndex] == 0:
        continue
      naiveResult[leftIndex + rightIndex] = mod3(naiveResult[leftIndex + rightIndex] + leftValues[leftIndex] * rightValues[rightIndex])
  return naiveResult

proc prepareTransform(values: seq[int], transformLength: int): seq[int64] =
  var prepared = newSeq[int64](transformLength)
  for indexValue in 0 .. values.len - 1:
    prepared[indexValue] = int64(values[indexValue])
  forwardTransform(prepared, false)
  return prepared

proc convolvePrepared(leftValues: seq[int], preparedRight: seq[int64], neededLength: int, transformLength: int): seq[int] =
  var firstTransform = newSeq[int64](transformLength)
  for indexValue in 0 .. leftValues.len - 1:
    firstTransform[indexValue] = int64(leftValues[indexValue])
  forwardTransform(firstTransform, false)
  for indexValue in 0 .. transformLength - 1:
    firstTransform[indexValue] = (firstTransform[indexValue] * preparedRight[indexValue]) mod transformModulus
  forwardTransform(firstTransform, true)
  var resultValues = newSeq[int](neededLength)
  for indexValue in 0 .. neededLength - 1:
    resultValues[indexValue] = int(firstTransform[indexValue]) mod 3
  return resultValues

proc convolveValues(leftValues: seq[int], rightValues: seq[int]): seq[int] =
  if leftValues.len == 0 or rightValues.len == 0:
    return @[]
  let neededLength = leftValues.len + rightValues.len - 1
  if neededLength <= 4096:
    return naiveConvolution(leftValues, rightValues, neededLength)
  var transformLength = 1
  while transformLength < neededLength:
    transformLength = transformLength * 2
  let preparedRight = prepareTransform(rightValues, transformLength)
  return convolvePrepared(leftValues, preparedRight, neededLength, transformLength)
```

The direct path avoids transform overhead for small circles.
Transform sizes are the next power of two.
Every coefficient returns to a color digit modulo three.

**Structured product.** The two arrays encode the whole matrix, and convolutions rebuild their product.

```nim
type Transition = object
  edgeValues: seq[int]
  bandValues: seq[int]

proc structureMultiply(leftStructure: Transition, rightStructure: Transition, circleSize: int): Transition =
  let offsetValue = circleSize - 3
  let bandLength = 2 * circleSize - 4

  var lowerBand = newSeq[int](offsetValue + 1)
  for indexValue in 0 .. offsetValue:
    lowerBand[indexValue] = leftStructure.bandValues[indexValue]
  var upperBand = newSeq[int](bandLength - offsetValue - 1)
  for indexValue in offsetValue + 1 .. bandLength - 1:
    upperBand[indexValue - offsetValue - 1] = leftStructure.bandValues[indexValue]
  var reversedBand = newSeq[int](bandLength)
  for indexValue in 0 .. bandLength - 1:
    reversedBand[bandLength - 1 - indexValue] = leftStructure.bandValues[indexValue]

  var lowerProduct: seq[int]
  var upperProduct: seq[int]
  let lowerNeed = lowerBand.len + rightStructure.bandValues.len - 1
  let upperNeed = upperBand.len + rightStructure.bandValues.len - 1
  if lowerNeed <= 4096:
    lowerProduct = naiveConvolution(lowerBand, rightStructure.bandValues, lowerNeed)
    upperProduct = naiveConvolution(upperBand, rightStructure.bandValues, upperNeed)
  else:
    var transformLength = 1
    while transformLength < lowerNeed or transformLength < upperNeed:
      transformLength = transformLength * 2
    let preparedRight = prepareTransform(rightStructure.bandValues, transformLength)
    lowerProduct = convolvePrepared(lowerBand, preparedRight, lowerNeed, transformLength)
    upperProduct = convolvePrepared(upperBand, preparedRight, upperNeed, transformLength)
  let edgeProduct = convolveValues(reversedBand, rightStructure.edgeValues)

  var newBand = newSeq[int](bandLength)
  for distanceValue in 3 - circleSize .. circleSize - 2:
    var resultValue = 0
    if distanceValue <= 0:
      let productIndex = distanceValue + 2 * offsetValue
      if productIndex >= 0 and productIndex < lowerProduct.len:
        resultValue = lowerProduct[productIndex]
      let lowerShift = distanceValue + offsetValue
      let upperShift = circleSize - 2 + distanceValue + offsetValue
      var firstTerm = 0
      var secondTerm = 0
      if lowerShift >= 0 and lowerShift < bandLength:
        firstTerm = rightStructure.bandValues[lowerShift]
      if upperShift >= 0 and upperShift < bandLength:
        secondTerm = rightStructure.bandValues[upperShift]
      resultValue = mod3(resultValue + leftStructure.edgeValues[circleSize - 1] * (firstTerm + secondTerm))
    else:
      let productIndex = distanceValue + offsetValue - 1
      if productIndex >= 0 and productIndex < upperProduct.len:
        resultValue = upperProduct[productIndex]
      let firstShift = distanceValue - circleSize + 2 + offsetValue
      let secondShift = distanceValue + offsetValue
      var firstTerm = 0
      var secondTerm = 0
      if firstShift >= 0 and firstShift < bandLength:
        firstTerm = rightStructure.bandValues[firstShift]
      if secondShift >= 0 and secondShift < bandLength:
        secondTerm = rightStructure.bandValues[secondShift]
      resultValue = mod3(resultValue + leftStructure.edgeValues[1] * (firstTerm + secondTerm))
    newBand[distanceValue + offsetValue] = resultValue

  var newEdges = newSeq[int](circleSize)
  let commonEdges = mod3(rightStructure.edgeValues[0] + rightStructure.edgeValues[1])
  for positionValue in 0 .. circleSize - 1:
    let effectivePosition = if positionValue >= 1: positionValue else: circleSize - 1
    let productIndex = effectivePosition + bandLength - 1 - offsetValue
    var crossValue = 0
    if productIndex >= 0 and productIndex < edgeProduct.len:
      crossValue = edgeProduct[productIndex]
    let firstBandIndex = offsetValue - effectivePosition
    let secondBandIndex = offsetValue + 1 - effectivePosition
    if firstBandIndex >= 0 and firstBandIndex < bandLength:
      crossValue -= leftStructure.bandValues[firstBandIndex] * rightStructure.edgeValues[0]
    if secondBandIndex >= 0 and secondBandIndex < bandLength:
      crossValue -= leftStructure.bandValues[secondBandIndex] * rightStructure.edgeValues[1]
    newEdges[positionValue] = mod3(leftStructure.edgeValues[positionValue] * commonEdges + crossValue)

  return Transition(edgeValues: newEdges, bandValues: newBand)
```

The band splits at its zero diagonal so two convolutions suffice.
The edge vector needs one reversed-band convolution.
All sums reduce modulo three after each product.

**Applying a power.** The final matrix acts on the starting colors through the same band product.

```nim
proc applyStructure(structureValue: Transition, colors: seq[int], circleSize: int): seq[int] =
  let offsetValue = circleSize - 3
  let bandLength = 2 * circleSize - 4
  var reversedBand = newSeq[int](bandLength)
  for indexValue in 0 .. bandLength - 1:
    reversedBand[bandLength - 1 - indexValue] = structureValue.bandValues[indexValue]
  let edgeProduct = convolveValues(reversedBand, colors)
  var resultColors = newSeq[int](circleSize)
  let commonEdges = mod3(colors[0] + colors[1])
  for positionValue in 0 .. circleSize - 1:
    let effectivePosition = if positionValue >= 1: positionValue else: circleSize - 1
    let productIndex = effectivePosition + bandLength - 1 - offsetValue
    var crossValue = 0
    if productIndex >= 0 and productIndex < edgeProduct.len:
      crossValue = edgeProduct[productIndex]
    let firstBandIndex = offsetValue - effectivePosition
    let secondBandIndex = offsetValue + 1 - effectivePosition
    if firstBandIndex >= 0 and firstBandIndex < bandLength:
      crossValue -= structureValue.bandValues[firstBandIndex] * colors[0]
    if secondBandIndex >= 0 and secondBandIndex < bandLength:
      crossValue -= structureValue.bandValues[secondBandIndex] * colors[1]
    resultColors[positionValue] = mod3(structureValue.edgeValues[positionValue] * commonEdges + crossValue)
  return resultColors

proc stepColors(colors: seq[int]): seq[int] =
  let circleSize = colors.len
  var nextColors = colors
  for positionValue in 0 .. circleSize - 1:
    let followingPosition = (positionValue + 1) mod circleSize
    let thirdColor = mod3(-(nextColors[positionValue] + nextColors[followingPosition]))
    nextColors[positionValue] = thirdColor
    nextColors[followingPosition] = thirdColor
  return nextColors
```

The first two columns contribute one shared sum.
The remaining columns contribute one diagonal convolution.
Small circles use cycle detection on the direct step.

**Driver.** Parsing, exponentiation, and buffered output finish the program.

```nim
let circleSize = nextInt(inputData, scanPos)
let stepCount = int64(nextInt(inputData, scanPos))

var initialColors = newSeq[int]()
while initialColors.len < circleSize and scanPos < inputData.len:
  let currentChar = inputData[scanPos]
  if currentChar == 'W' or currentChar == 'R' or currentChar == 'G':
    if currentChar == 'W':
      initialColors.add 0
    elif currentChar == 'R':
      initialColors.add 1
    else:
      initialColors.add 2
  scanPos += 1

if circleSize <= 3:
  var history = newSeq[string]()
  var currentColors = initialColors
  var currentStep = int64(0)
  while currentStep < stepCount:
    var keyValue = ""
    for colorValue in currentColors:
      keyValue.add char(48 + colorValue)
    var seenBefore = -1
    for historyIndex in 0 .. history.len - 1:
      if history[historyIndex] == keyValue:
        seenBefore = historyIndex
        break
    if seenBefore >= 0:
      let cycleLength = history.len - seenBefore
      let remaining = (stepCount - int64(seenBefore)) mod int64(cycleLength)
      let savedState = history[seenBefore + int(remaining)]
      var restoredColors = newSeq[int]()
      for savedChar in savedState:
        restoredColors.add int(savedChar) - 48
      currentColors = restoredColors
      break
    history.add keyValue
    currentColors = stepColors(currentColors)
    currentStep += 1
  var outputLine = ""
  for colorValue in currentColors:
    if colorValue == 0:
      outputLine.add 'W'
    elif colorValue == 1:
      outputLine.add 'R'
    else:
      outputLine.add 'G'
  appendOutput(outputLine)
  appendOutput("\n")
else:
  let offsetValue = circleSize - 3
  let bandLength = 2 * circleSize - 4
  var oneStep = Transition(edgeValues: newSeq[int](circleSize), bandValues: newSeq[int](bandLength))
  for positionValue in 1 .. circleSize - 2:
    if (positionValue mod 2) == 0:
      oneStep.edgeValues[positionValue] = 2
    else:
      oneStep.edgeValues[positionValue] = 1
  let firstEdge = mod3(1 + (if ((circleSize - 2) mod 2) == 0: 1 else: 2))
  oneStep.edgeValues[0] = firstEdge
  oneStep.edgeValues[circleSize - 1] = firstEdge
  for distanceValue in 3 - circleSize .. 1:
    if ((distanceValue mod 2) + 2) mod 2 == 0:
      oneStep.bandValues[distanceValue + offsetValue] = 1
    else:
      oneStep.bandValues[distanceValue + offsetValue] = 2

  var accumulated = oneStep
  var powered = oneStep
  var remainingSteps = stepCount - 1
  while remainingSteps > 0:
    if (remainingSteps mod 2) == 1:
      accumulated = structureMultiply(accumulated, powered, circleSize)
    remainingSteps = remainingSteps div 2
    if remainingSteps > 0:
      powered = structureMultiply(powered, powered, circleSize)

  let finalColors = applyStructure(accumulated, initialColors, circleSize)
  var outputLine = ""
  for colorValue in finalColors:
    if colorValue == 0:
      outputLine.add 'W'
    elif colorValue == 1:
      outputLine.add 'R'
    else:
      outputLine.add 'G'
  appendOutput(outputLine)
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The one-step matrix is built directly from its alternating band.
Binary squaring applies about thirty structured products.
One buffered write emits the resulting color row.

## Complexity

The compact matrix stores two arrays of length proportional to n.

| phase | time | space |
|---|---|---|
| input read | one pass over the color row | one input string |
| one-step setup | one pass over the band | two compact arrays |
| squaring | logarithm of k convolutions | transform arrays |
| final apply | one convolution | one color array |
| output | one color row | block buffer |

| measure | Big O |
|---|---|
| time | O(n log n log k) |
| space | O(n) |

Simulating every talk in every step would cost O(n k).
