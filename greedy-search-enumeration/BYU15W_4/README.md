# BYU15W_4 — Game Calculator (SPOJ)

<https://www.spoj.com/problems/BYU15W_4/>

## Problem

Two armies A and B fight in turns where each unit independently scores a hit with probability `H`. Each turn removes from each army the hits scored by the opposing army until at least one side has zero or fewer units left. Compute the probabilities that A wins, B wins, or both sides fall together in a draw.

Input starts with `T`, followed by `T` test cases of two lines: the decimal hit chance `H` and the two integer army sizes `A` and `B`. Print three probabilities per case, each rounded to five decimal places.

Constraints and limits for the task:

| item | bound |
|---|---|
| test cases | T positive integer |
| hit probability H | 0 < H ≤ 1 |
| army sizes A, B | 1 to 1000000 |
| output precision | 5 decimal places |
| judge limit | 1000 ms, 1536 MB |

Large army sizes prevent running exact per-unit dynamic programming directly up to one million.

Sample input and output:

```
2
0.3
2 1
0.854
8 8
```

```
0.86839 0.09213 0.03948
0.38532 0.38532 0.22936
```

The second sample case shows a symmetric starting point with a large draw chance.

## Idea

Track the scaled army gap on a random-walk grid while both armies are huge, like watching two shrinking sandpiles from a distance before counting individual grains at the end. When total army size drops near `dpCutoff`, hand the surviving distribution to an exact two-dimensional dynamic program over binomial hit counts.

The exact dynamic program factors the two hit counts in O(M³) work for states up to `dpCutoff`. Large-army evolution uses O(G²) work per macro-step on a fixed grid of `gridPoints` bins. Evaluating every state up to one million directly would require trillions of transitions and exceed the time limit.

Splitting between a macro-stepped random walk and a small exact endgame keeps every regime accurate and fast.

## Why It Works

1. If `H = 1`, every unit hits on turn one, so the larger army wins and equal armies draw.
2. When `A` and `B` are at most `dpCutoff`, conditioning out the mutual-miss `(0, 0)` turn divides each state transition by `1 - P(0, 0)`.
3. Because hits by A and B are independent given `(A, B)`, summing over one side's hits first factors the inner 2D transition into two passes.
4. For larger armies, let `S = A + B` and `D = A - B`. In one turn, expected `S` scales by `1 - H` and expected `D` scales by `1 + H`.
5. Therefore `Z = D / (1 + H)^t` is a zero-drift martingale whose increment variance is `H(1 - H) S / (1 + H)^(2t)`.
6. Absorbing mass when |Z| reaches `S / (1 + H)^t` captures early wins. Five Gauss-Hermite nodes then integrate total-size variance at handoff.

Formula terms and variables in the program:

| term | meaning |
|---|---|
| `dpCutoff` | exact dynamic programming boundary set to `64` |
| `gridPoints` | number of bins on the martingale grid (`601`) |
| `sumS` | expected remaining total units `A + B` |
| `scale` | cumulative growth factor `(1 + H)^t` |
| `varS` | accumulated variance of total remaining units |
| `ghNodes`, `ghWeights` | 5-point Gauss-Hermite quadrature nodes and weights |

Worked trace for the first sample `H = 0.3`, `A = 2`, `B = 1` using exact dynamic programming:

| state `(a, b)` | `P(A wins)` | `P(B wins)` | `P(draw)` |
|---|---|---|---|
| `(1, 1)` | 0.41176 | 0.41176 | 0.17647 |
| `(2, 1)` | 0.86839 | 0.09213 | 0.03948 |

At `(2, 1)`, army A deals 0, 1, or 2 hits with probabilities 0.49, 0.42, and 0.09, immediately resolving 51% of games in turn one.

## Code

**Factored exact endgame.** Computing intermediate sums over B's hits turns a quartic transition into a cubic one.

```nim
  for armyA in 1 .. limit:
    let loA = rowLo[armyA]
    let hiA = rowHi[armyA]
    for armyB in 1 .. limit:
      let loB = rowLo[armyB]
      let hiB = rowHi[armyB]
      var bpMin = armyB - hiA
      if bpMin < 0:
        bpMin = 0
      for nextB in bpMin .. armyB:
        var sumA = 0.0
        var sumB = 0.0
        var sumD = 0.0
        for hitsB in loB .. hiB:
          if hitsB == 0 and nextB == armyB:
            continue
          let probB = rows[armyB][hitsB]
          var nextA = armyA - hitsB
          if nextA < 0:
            nextA = 0
          let idx = nextA * stride + nextB
          sumA += probB * table.winA[idx]
          sumB += probB * table.winB[idx]
          sumD += probB * table.draw[idx]
        let condIdx = armyB * stride + nextB
        condA[condIdx] = sumA
        condB[condIdx] = sumB
        condD[condIdx] = sumD
```

The inner loop skips `(hitsB = 0, nextB = armyB)` so mutual-miss self-loops are excluded cleanly.
Restricting hit counts to `[loB .. hiB]` avoids multiplying negligible tails below `1e-13`.
Each `(armyA, armyB)` cell takes work proportional to the square of the binomial standard deviation.

**Macro-stepped martingale propagation.** Tiny hit probabilities collapse many turns into one geometric-series update.

```nim
    var varZStep = 0.0
    if macroTurns == 1:
      scale *= growth
      varZStep = hitProb * decay * sumS / (scale * scale)
      varS = decay * decay * varS + hitProb * decay * sumS
      sumS *= decay
    else:
      let decPow = pow(decay, float64(macroTurns))
      let groPow = pow(growth, float64(macroTurns))
      let ratioPow = pow(ratioZ, float64(macroTurns))
      let geoZ = (1.0 - ratioPow) / (1.0 - ratioZ)
      varZStep = hitProb * decay * sumS / (scale * scale * growth * growth) * geoZ
      let geoS = (1.0 - decPow) / hitProb
      varS = decPow * decPow * varS + hitProb * decay * sumS * (decPow / decay) * geoS
      sumS *= decPow
      scale *= groPow
```

Closed-form geometric sums `geoZ` and `geoS` compute exact `macroTurns` variance without an inner loop.
The `ratioZ` constant `(1 - H) / (1 + H)^2` is always strictly less than one.
Even `H = 0.0001` at `A = 1000000` finishes in roughly one thousand macro-steps.

**Quadrature handoff and output formatting.** Five Gauss-Hermite nodes evaluate total-size uncertainty over the exact DP table.

```nim
      for qIdx in 0 .. 4:
        let sumVal = sumS + ghNodes[qIdx] * stdS
        if sumVal <= 0.0:
          draw += mass * ghWeights[qIdx]
          continue
        let aFloat = 0.5 * (sumVal + diffVal)
        let bFloat = 0.5 * (sumVal - diffVal)
        let aBase = int(floor(aFloat))
        let bBase = int(floor(bFloat))
        let aFrac = aFloat - float64(aBase)
        let bFrac = bFloat - float64(bBase)
        for da in 0 .. 1:
          let wA = if da == 0: 1.0 - aFrac else: aFrac
          var aa = aBase + da
          if aa < 0:
            aa = 0
          elif aa > dpCutoff:
            aa = dpCutoff
          for db in 0 .. 1:
            let wB = if db == 0: 1.0 - bFrac else: bFrac
            var bb = bBase + db
            if bb < 0:
              bb = 0
            elif bb > dpCutoff:
              bb = dpCutoff
            let weight = mass * ghWeights[qIdx] * wA * wB
            let tIdx = aa * table.stride + bb
            winA += weight * table.winA[tIdx]
            winB += weight * table.winB[tIdx]
            draw += weight * table.draw[tIdx]
```

Bilinear interpolation clamps coordinates into `[0, dpCutoff]` so edge states stay in bounds.
Non-positive `sumVal` samples count directly toward `draw` when both armies vanish together.
When `A = B`, symmetry sets both win chances to half of `1 - draw`.

## Complexity

Cost per test case across the two execution regimes:

| phase | time | space |
|---|---|---|
| exact DP (`A, B ≤ dpCutoff`) | O(M² σ²) | O(M²) |
| martingale grid (`max > dpCutoff`) | O(steps · G · r) | O(G) |
| quadrature handoff | O(G + M² σ²) | O(M²) |

Here `M ≤ 64`, `σ ≤ 16`, `G = 601`, and `r ≤ 30` is the Gaussian kernel radius.

| item | Big O |
|---|---|
| time per case | O(M² σ² + G · log(S / M) / min(H, 0.01)) |
| space | O(M² + G) |

Direct per-unit dynamic programming would take O(A · B · √(AB)) time and fail on million-unit inputs.

Every input regime reduces either to fast exact binomial DP or to a short macro-stepped random walk.
