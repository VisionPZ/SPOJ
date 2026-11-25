import algorithm
import math

const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const sieveLimit = 10000
const stepLimit = 100

type Huge = tuple[negative: bool, exponent: int, mantissa: float64]

proc zeroHuge(): Huge =
  return (false, 0, 0.0)

proc fromSmall(value: int64): Huge =
  if value == 0:
    return zeroHuge()
  let negativeFlag = value < 0
  var magnitude = value
  if negativeFlag:
    magnitude = -value
  var exponentValue = 0
  var probe = magnitude
  while probe > 1:
    probe = probe div 2
    exponentValue += 1
  var divisor = 1.0
  var counter = 0
  while counter < exponentValue:
    divisor = divisor * 2.0
    counter += 1
  return (negativeFlag, exponentValue, float64(magnitude) / divisor)

proc normalized(negativeFlag: bool, exponentValue: int, mantissaValue: float64): Huge =
  if mantissaValue == 0.0:
    return zeroHuge()
  var currentMantissa = mantissaValue
  var currentExponent = exponentValue
  while currentMantissa >= 2.0:
    currentMantissa = currentMantissa * 0.5
    currentExponent += 1
  while currentMantissa < 1.0:
    currentMantissa = currentMantissa * 2.0
    currentExponent -= 1
  return (negativeFlag, currentExponent, currentMantissa)

proc shiftedDown(mantissaValue: float64, shift: int): float64 =
  var value = mantissaValue
  var counter = 0
  while counter < shift:
    value = value * 0.5
    counter += 1
  return value

proc added(left: Huge, right: Huge): Huge =
  if left.mantissa == 0.0:
    return right
  if right.mantissa == 0.0:
    return left
  let commonExponent = max(left.exponent, right.exponent)
  let leftMantissa = shiftedDown(left.mantissa, commonExponent - left.exponent)
  let rightMantissa = shiftedDown(right.mantissa, commonExponent - right.exponent)
  if left.negative == right.negative:
    return normalized(left.negative, commonExponent, leftMantissa + rightMantissa)
  if leftMantissa >= rightMantissa:
    return normalized(left.negative, commonExponent, leftMantissa - rightMantissa)
  return normalized(right.negative, commonExponent, rightMantissa - leftMantissa)

proc negated(value: Huge): Huge =
  return (not value.negative, value.exponent, value.mantissa)

proc scaledBy(value: Huge, factor: int): Huge =
  if value.mantissa == 0.0:
    return zeroHuge()
  if factor < 0:
    return negated(normalized(value.negative, value.exponent,
                              value.mantissa * float64(-factor)))
  return normalized(value.negative, value.exponent, value.mantissa * float64(factor))

proc multiplied(left: Huge, right: Huge): Huge =
  if left.mantissa == 0.0 or right.mantissa == 0.0:
    return zeroHuge()
  return normalized(left.negative != right.negative, left.exponent + right.exponent,
                    left.mantissa * right.mantissa)

proc compareHuge(left: Huge, right: Huge): int =
  if left.mantissa == 0.0 and right.mantissa == 0.0:
    return 0
  if left.mantissa == 0.0:
    return -1
  if right.mantissa == 0.0:
    return 1
  if left.negative != right.negative:
    if left.negative:
      return -1
    return 1
  if left.exponent != right.exponent:
    if left.exponent < right.exponent:
      return -1
    return 1
  if left.mantissa < right.mantissa:
    return -1
  if left.mantissa > right.mantissa:
    return 1
  return 0

proc sameHuge(left: Huge, right: Huge): bool =
  if left.negative != right.negative or left.exponent != right.exponent:
    return false
  let difference = left.mantissa - right.mantissa
  if difference < 0.0:
    return -difference < 0.000000000001
  return difference < 0.000000000001

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc positiveModulo(value: int64, modulus: int64): int64 =
  var reducedValue = value mod modulus
  if reducedValue < 0:
    reducedValue += modulus
  return reducedValue

proc integerSquareRoot(value: int64): int64 =
  var root = int64(sqrt(float64(value)))
  while (root + 1) * (root + 1) <= value:
    root += 1
  while root * root > value:
    root -= 1
  return root

proc primeRepresentation(primeValue: int): tuple[first: int, second: int] =
  var coefficient = 1
  while 2 * coefficient * coefficient <= primeValue * 2 + 4:
    let upper = 2 * coefficient * coefficient + primeValue
    let upperRoot = integerSquareRoot(int64(upper))
    if upperRoot * upperRoot == upper:
      return (int(upperRoot), coefficient)
    let lower = 2 * coefficient * coefficient - primeValue
    if lower > 0:
      let lowerRoot = integerSquareRoot(int64(lower))
      if lowerRoot * lowerRoot == lower:
        return (int(lowerRoot), coefficient)
    coefficient += 1
  return (0, 0)

type Factor = tuple[primeValue: int, exponent: int]

proc factorValue(value: int, primeList: seq[int]): seq[Factor] =
  var factors: seq[Factor] = @[]
  var remaining = value
  var primeIndex = 0
  while primeIndex < primeList.len:
    let primeValue = primeList[primeIndex]
    if primeValue * primeValue > remaining:
      break
    if remaining mod primeValue == 0:
      var exponent = 0
      while remaining mod primeValue == 0:
        remaining = remaining div primeValue
        exponent += 1
      factors.add((primeValue, exponent))
    primeIndex += 1
  if remaining > 1:
    factors.add((remaining, 1))
  return factors

type PairValue = tuple[realPart: Huge, imaginaryPart: Huge, realMod: int64, imaginaryMod: int64]

proc pairMultiply(left: PairValue, right: PairValue, modulus: int64): PairValue =
  let realPart = added(multiplied(left.realPart, right.realPart),
                       scaledBy(multiplied(left.imaginaryPart, right.imaginaryPart), 2))
  let imaginaryPart = added(multiplied(left.realPart, right.imaginaryPart),
                            multiplied(left.imaginaryPart, right.realPart))
  let realMod = positiveModulo(left.realMod * right.realMod + 2 * left.imaginaryMod * right.imaginaryMod, modulus)
  let imaginaryMod = positiveModulo(left.realMod * right.imaginaryMod + left.imaginaryMod * right.realMod, modulus)
  return (realPart, imaginaryPart, realMod, imaginaryMod)

type Orbit = tuple[realBase: Huge, imaginaryBase: Huge, realMod: int64, imaginaryMod: int64]

proc buildOrbits(factors: seq[Factor], targetValue: int, modulus: int64): seq[Orbit] =
  var choices: seq[PairValue] = @[(fromSmall(1), fromSmall(1), 1 mod modulus, 1 mod modulus)]
  for factor in factors:
    if factor.primeValue == 2:
      let rootTwo: PairValue = (zeroHuge(), fromSmall(1), int64(0), 1 mod modulus)
      var repeatIndex = 0
      while repeatIndex < 2 * factor.exponent:
        var repeated: seq[PairValue] = @[]
        for choice in choices:
          repeated.add(pairMultiply(choice, rootTwo, modulus))
        choices = repeated
        repeatIndex += 1
    elif factor.primeValue mod 8 == 3 or factor.primeValue mod 8 == 5:
      let inertFactor: PairValue = (fromSmall(int64(factor.primeValue)), zeroHuge(),
                         int64(factor.primeValue) mod modulus, int64(0))
      var repeatIndex = 0
      while repeatIndex < factor.exponent:
        var repeated: seq[PairValue] = @[]
        for choice in choices:
          repeated.add(pairMultiply(choice, inertFactor, modulus))
        choices = repeated
        repeatIndex += 1
    else:
      let representation = primeRepresentation(factor.primeValue)
      let positivePair: PairValue = (fromSmall(int64(representation.first)),
                          fromSmall(int64(representation.second)),
                          int64(representation.first) mod modulus,
                          int64(representation.second) mod modulus)
      let negativePair: PairValue = (fromSmall(int64(representation.first)),
                          scaledBy(fromSmall(int64(representation.second)), -1),
                          int64(representation.first) mod modulus,
                          positiveModulo(-int64(representation.second), modulus))
      let identityPair: PairValue = (fromSmall(1), zeroHuge(), 1 mod modulus, int64(0))
      var positivePowers: seq[PairValue] = @[identityPair]
      var negativePowers: seq[PairValue] = @[identityPair]
      var powerIndex = 0
      while powerIndex < 2 * factor.exponent:
        positivePowers.add(pairMultiply(positivePowers[powerIndex], positivePair, modulus))
        negativePowers.add(pairMultiply(negativePowers[powerIndex], negativePair, modulus))
        powerIndex += 1
      var expanded: seq[PairValue] = @[]
      for choice in choices:
        for splitIndex in 0 .. 2 * factor.exponent:
          let leftPart = pairMultiply(choice, positivePowers[splitIndex], modulus)
          expanded.add(pairMultiply(leftPart, negativePowers[2 * factor.exponent - splitIndex], modulus))
      choices = expanded
  let threshold = fromSmall(int64(targetValue))
  var orbitResult: seq[Orbit] = @[]
  for choice in choices:
    for signIndex in 0 .. 1:
      var realPart = choice.realPart
      var imaginaryPart = choice.imaginaryPart
      var realModValue = choice.realMod
      var imaginaryModValue = choice.imaginaryMod
      if signIndex == 1:
        realPart = negated(realPart)
        imaginaryPart = negated(imaginaryPart)
        realModValue = positiveModulo(-realModValue, modulus)
        imaginaryModValue = positiveModulo(-imaginaryModValue, modulus)
      var advanceIndex = 0
      while advanceIndex < stepLimit:
        if compareHuge(realPart, threshold) > 0 and not imaginaryPart.negative and imaginaryPart.mantissa != 0.0:
          break
        let nextReal = added(scaledBy(realPart, 3), scaledBy(imaginaryPart, 4))
        let nextImaginary = added(scaledBy(realPart, 2), scaledBy(imaginaryPart, 3))
        let nextRealMod = positiveModulo(3 * realModValue + 4 * imaginaryModValue, modulus)
        let nextImaginaryMod = positiveModulo(2 * realModValue + 3 * imaginaryModValue, modulus)
        realPart = nextReal
        imaginaryPart = nextImaginary
        realModValue = nextRealMod
        imaginaryModValue = nextImaginaryMod
        advanceIndex += 1
      if advanceIndex == stepLimit:
        continue
      var reduceIndex = 0
      while reduceIndex < stepLimit:
        let previousReal = added(scaledBy(realPart, 3), scaledBy(imaginaryPart, -4))
        let previousImaginary = added(scaledBy(imaginaryPart, 3), scaledBy(realPart, -2))
        if compareHuge(previousReal, threshold) > 0 and not previousImaginary.negative and previousImaginary.mantissa != 0.0:
          let previousRealMod = positiveModulo(3 * realModValue - 4 * imaginaryModValue, modulus)
          let previousImaginaryMod = positiveModulo(3 * imaginaryModValue - 2 * realModValue, modulus)
          realPart = previousReal
          imaginaryPart = previousImaginary
          realModValue = previousRealMod
          imaginaryModValue = previousImaginaryMod
        else:
          break
        reduceIndex += 1
      var duplicate = false
      for existing in orbitResult:
        if sameHuge(existing.realBase, realPart) and sameHuge(existing.imaginaryBase, imaginaryPart):
          duplicate = true
          break
      if not duplicate:
        orbitResult.add((realPart, imaginaryPart, realModValue, imaginaryModValue))
  return orbitResult

proc matrixAdvance(firstValue: int64, secondValue: int64, steps: int64, modulus: int64): int64 =
  var a00: int64 = 1 mod modulus
  var a01: int64 = 0
  var a10: int64 = 0
  var a11: int64 = 1 mod modulus
  var b00: int64 = 6 mod modulus
  var b01: int64 = (modulus - 1) mod modulus
  var b10: int64 = 1 mod modulus
  var b11: int64 = 0
  var exponentValue = steps
  while exponentValue > 0:
    if (exponentValue and 1) == 1:
      let c00 = (a00 * b00 + a01 * b10) mod modulus
      let c01 = (a00 * b01 + a01 * b11) mod modulus
      let c10 = (a10 * b00 + a11 * b10) mod modulus
      let c11 = (a10 * b01 + a11 * b11) mod modulus
      a00 = c00
      a01 = c01
      a10 = c10
      a11 = c11
    let d00 = (b00 * b00 + b01 * b10) mod modulus
    let d01 = (b00 * b01 + b01 * b11) mod modulus
    let d10 = (b10 * b00 + b11 * b10) mod modulus
    let d11 = (b10 * b01 + b11 * b11) mod modulus
    b00 = d00
    b01 = d01
    b10 = d10
    b11 = d11
    exponentValue = exponentValue shr 1
  return (a10 * firstValue + a11 * secondValue) mod modulus

var composite = newSeq[bool](sieveLimit + 1)
var primeList: seq[int] = @[]
var sieveIndex = 2
while sieveIndex <= sieveLimit:
  if not composite[sieveIndex]:
    primeList.add sieveIndex
    var multipleIndex = sieveIndex * sieveIndex
    while multipleIndex <= sieveLimit:
      composite[multipleIndex] = true
      multipleIndex += sieveIndex
  sieveIndex += 1

type Term = tuple[value: Huge, orbitIndex: int, termIndex: int]

proc compareTerm(left: Term, right: Term): int =
  return compareHuge(left.value, right.value)

let caseCount = nextInt(inputData, scanPos)
var caseIndex = 0
while caseIndex < caseCount:
  let targetIndex = int64(nextInt(inputData, scanPos))
  let differenceValue = nextInt(inputData, scanPos)
  let modulusValue = int64(nextInt(inputData, scanPos))
  let doubleModulus = 2 * modulusValue
  let factors = factorValue(differenceValue, primeList)
  let orbits = buildOrbits(factors, differenceValue, doubleModulus)
  let orbitCount = orbits.len
  let termCount = 5 * orbitCount + 6
  var allTerms: seq[Term] = @[]
  var orbitValues: seq[seq[Huge]] = @[]
  var orbitRealMods: seq[seq[int64]] = @[]
  var orbitImaginaryMods: seq[seq[int64]] = @[]
  var orbitIndexValue = 0
  while orbitIndexValue < orbitCount:
    let sourceOrbit = orbits[orbitIndexValue]
    var valueList: seq[Huge] = @[]
    var realModList: seq[int64] = @[]
    var imaginaryModList: seq[int64] = @[]
    var realPart = sourceOrbit.realBase
    var imaginaryPart = sourceOrbit.imaginaryBase
    var realModValue = sourceOrbit.realMod
    var imaginaryModValue = sourceOrbit.imaginaryMod
    var termIndexValue = 0
    while termIndexValue < termCount:
      valueList.add(imaginaryPart)
      realModList.add(realModValue)
      imaginaryModList.add(imaginaryModValue)
      allTerms.add((imaginaryPart, orbitIndexValue, termIndexValue))
      let nextReal = added(scaledBy(realPart, 3), scaledBy(imaginaryPart, 4))
      let nextImaginary = added(scaledBy(realPart, 2), scaledBy(imaginaryPart, 3))
      let nextRealMod = positiveModulo(3 * realModValue + 4 * imaginaryModValue, doubleModulus)
      let nextImaginaryMod = positiveModulo(2 * realModValue + 3 * imaginaryModValue, doubleModulus)
      realPart = nextReal
      imaginaryPart = nextImaginary
      realModValue = nextRealMod
      imaginaryModValue = nextImaginaryMod
      termIndexValue += 1
    orbitValues.add(valueList)
    orbitRealMods.add(realModList)
    orbitImaginaryMods.add(imaginaryModList)
    orbitIndexValue += 1
  allTerms.sort(compareTerm)
  var mergedRealMods: seq[int64] = @[]
  var mergedImaginaryMods: seq[int64] = @[]
  var mergedIndex = 0
  while mergedIndex < allTerms.len:
    let chosen = allTerms[mergedIndex]
    mergedRealMods.add(orbitRealMods[chosen.orbitIndex][chosen.termIndex])
    mergedImaginaryMods.add(orbitImaginaryMods[chosen.orbitIndex][chosen.termIndex])
    mergedIndex += 1
  let directLimit = int64(mergedRealMods.len)
  var firstLegMod: int64 = 0
  var secondLegMod: int64 = 0
  var hypotenuseMod: int64 = 0
  if targetIndex <= directLimit:
    let chosenIndex = int(targetIndex - 1)
    firstLegMod = mergedRealMods[chosenIndex]
    hypotenuseMod = mergedImaginaryMods[chosenIndex] mod modulusValue
  else:
    let globalIndex = targetIndex - 1
    let quotient = globalIndex div int64(orbitCount)
    let remainder = globalIndex mod int64(orbitCount)
    let startIndex = int(remainder) + 3 * orbitCount
    let nextIndex = startIndex + orbitCount
    let steps = quotient - 3
    firstLegMod = matrixAdvance(mergedRealMods[nextIndex], mergedRealMods[startIndex], steps, doubleModulus)
    hypotenuseMod = matrixAdvance(mergedImaginaryMods[nextIndex], mergedImaginaryMods[startIndex], steps, doubleModulus) mod modulusValue
  secondLegMod = (positiveModulo(firstLegMod - int64(differenceValue), doubleModulus) div 2) mod modulusValue
  firstLegMod = positiveModulo(secondLegMod + int64(differenceValue), modulusValue)
  appendOutput($secondLegMod & " " & $firstLegMod & " " & $hypotenuseMod)
  outputBuffer.add '\n'
  caseIndex += 1
stdout.write outputBuffer
outputBuffer.setLen 0
