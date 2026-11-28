import math, strutils

const flushBlockBytes = 1 shl 18
const digitBase = 48

proc nextInt(inputData: string, i: var int): int =
  while i < inputData.len and int(inputData[i]) < digitBase:
    i += 1
  var value = 0
  while i < inputData.len and int(inputData[i]) >= digitBase:
    value = value * 10 + (int(inputData[i]) - digitBase)
    i += 1
  return value

proc addProduct(highWord: var int64, lowWord: var uint64, term: int64) =
  let termBits = cast[uint64](term)
  let addedLow = lowWord + termBits
  let carryWord: int64 = if addedLow < lowWord: 1 else: 0
  let extendWord: int64 = if term < 0: -1 else: 0
  lowWord = addedLow
  highWord += carryWord + extendWord

proc flushOutput(outputBuffer: var string) =
  stdout.write outputBuffer
  outputBuffer.setLen 0

var inputData = ""
var nextLine = ""
while readLine(stdin, nextLine):
  inputData.add nextLine
  inputData.add '\n'

var i = 0
let testCount = nextInt(inputData, i)
var outputBuffer = ""
var highWord: int64 = 0
var lowWord: uint64 = 0

var j = 0
while j < testCount:
  let edgeAB = nextInt(inputData, i)
  let edgeAC = nextInt(inputData, i)
  let edgeAD = nextInt(inputData, i)
  let edgeBC = nextInt(inputData, i)
  let edgeBD = nextInt(inputData, i)
  let edgeCD = nextInt(inputData, i)

  let squaredAD = edgeAD * edgeAD
  let squaredBD = edgeBD * edgeBD
  let squaredCD = edgeCD * edgeCD
  let twiceDotAB = squaredAD + squaredBD - edgeAB * edgeAB
  let twiceDotAC = squaredAD + squaredCD - edgeAC * edgeAC
  let twiceDotBC = squaredBD + squaredCD - edgeBC * edgeBC

  highWord = 0
  lowWord = 0
  addProduct(highWord, lowWord, 4 * squaredAD * squaredBD * squaredCD)
  addProduct(highWord, lowWord, twiceDotAB * twiceDotAC * twiceDotBC)
  addProduct(highWord, lowWord, -(squaredAD * twiceDotBC * twiceDotBC))
  addProduct(highWord, lowWord, -(squaredBD * twiceDotAC * twiceDotAC))
  addProduct(highWord, lowWord, -(squaredCD * twiceDotAB * twiceDotAB))

  let scaledSquaredVolume = int64(lowWord)
  let volume = sqrt(float(scaledSquaredVolume) / 144.0)
  outputBuffer.add formatFloat(volume, ffDecimal, 4)
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    flushOutput(outputBuffer)
  j += 1

if outputBuffer.len > 0:
  flushOutput(outputBuffer)
