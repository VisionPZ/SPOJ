const flushBlockBytes = 1 shl 17
const modulusValue = 1000000000'i64
const maximumDepth = 65

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

type LayerData = object
  counts: seq[int64]
  parentSums: seq[int64]

var memoizedLayers: array[2, array[maximumDepth + 1, array[maximumDepth + 1, LayerData]]]

proc addRoot(layers: var LayerData) =
  if layers.counts.len > 0:
    layers.parentSums[layers.parentSums.len - 1] = layers.counts[layers.counts.len - 1] mod modulusValue
  layers.parentSums.add 0
  layers.counts.add 1

proc mergeLayers(resultData: var LayerData, other: LayerData) =
  if other.counts.len == 0:
    return
  if resultData.counts.len == 0:
    resultData.counts = other.counts
    resultData.parentSums = other.parentSums
    return
  let lastLayer = resultData.counts.len - 1
  for layerIndex in 0 .. lastLayer - 1:
    resultData.parentSums[layerIndex] = (resultData.parentSums[layerIndex] +
      other.parentSums[layerIndex] +
      (other.counts[layerIndex] mod modulusValue) *
      (resultData.counts[layerIndex + 1] mod modulusValue)) mod modulusValue
    resultData.counts[layerIndex] += other.counts[layerIndex]
  resultData.counts[lastLayer] += other.counts[other.counts.len - 1]

proc fullSubtree(depth: int, degree: int, lastFlag: bool): LayerData =
  if depth < 0:
    var emptyLayers: LayerData
    return emptyLayers
  if depth == 0:
    var singleRoot: LayerData
    singleRoot.counts.add 1
    singleRoot.parentSums.add 0
    return singleRoot
  let flagIndex = if lastFlag: 1 else: 0
  if memoizedLayers[flagIndex][depth][degree].counts.len > 0:
    return memoizedLayers[flagIndex][depth][degree]
  var resultData: LayerData
  for childIndex in 1 .. degree:
    let childIsLast = (childIndex == degree) and lastFlag
    var childDegree = childIndex
    if childIsLast:
      childDegree += 1
    let childLayers = fullSubtree(depth - 1, childDegree, childIsLast)
    mergeLayers(resultData, childLayers)
  resultData.addRoot()
  memoizedLayers[flagIndex][depth][degree] = resultData
  return resultData

proc partialSubtree(depth: int, degree: int, remainingNodes: int64,
                    lastFlag: bool, maxDepth: int): LayerData =
  var resultData: LayerData
  var remainingCount = remainingNodes
  for childIndex in 1 .. degree:
    let childIsLast = (childIndex == degree) and lastFlag
    var childDegree = childIndex
    if childIsLast:
      childDegree += 1
    if remainingCount == 0:
      var childLayers = fullSubtree(maxDepth - 1 - depth, childDegree, childIsLast)
      childLayers.counts.insert(0, 0)
      childLayers.parentSums.insert(0, 0)
      mergeLayers(resultData, childLayers)
    else:
      let childLayers = fullSubtree(maxDepth - depth, childDegree, childIsLast)
      if childLayers.counts[0] <= remainingCount:
        remainingCount -= childLayers.counts[0]
        mergeLayers(resultData, childLayers)
      else:
        let deeperLayers = partialSubtree(depth + 1, childDegree, remainingCount,
                                          childIsLast, maxDepth)
        mergeLayers(resultData, deeperLayers)
        remainingCount = 0
  resultData.addRoot()
  return resultData

memoizedLayers[1][0][0].addRoot()

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let target = int64(nextInt(inputData, scanPos))
  if target < 3:
    appendOutput($target)
    outputBuffer.add '\n'
    continue
  var currentPower: int64 = 1
  var generation: int = 0
  while currentPower < target:
    currentPower = currentPower * 2
    generation += 1
  let halfPower = currentPower div 2
  var treeLayers = partialSubtree(0, 1, target - halfPower, true, generation - 1)
  var layerCounts = newSeq[int64](treeLayers.counts.len)
  var layerParents = newSeq[int64](treeLayers.parentSums.len)
  for layerIndex in 0 .. treeLayers.counts.len - 1:
    layerCounts[layerIndex] = treeLayers.counts[treeLayers.counts.len - 1 - layerIndex]
  for layerIndex in 0 .. treeLayers.parentSums.len - 1:
    layerParents[layerIndex] = treeLayers.parentSums[treeLayers.parentSums.len - 1 - layerIndex]
  var totalSum: int64 = 2
  var powerFactor: int64 = 1
  for layerIndex in 2 .. layerCounts.len - 1:
    totalSum = (totalSum + layerParents[layerIndex] +
      powerFactor * (layerCounts[layerIndex] mod modulusValue)) mod modulusValue
    powerFactor = (powerFactor * 2) mod modulusValue
  appendOutput($totalSum)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
