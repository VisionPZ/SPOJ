#!/usr/bin/env python3
import random
from itertools import product
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def brute_answer(text):
    n = len(text)
    forward = {}
    backward = {}
    for u in range(n):
        fset = set()
        x = u
        for _ in range(n):
            arc = x
            if text[arc] == 'A':
                break
            x = (x + 1) % n
            if x == u:
                break
            fset.add(x)
        bset = set()
        x = u
        for _ in range(n):
            arc = (x - 1) % n
            if text[arc] == 'C':
                break
            x = (x - 1) % n
            if x == u:
                break
            bset.add(x)
        forward[u] = fset
        backward[u] = bset
    only_clock = [(u, v) for u in range(n) for v in forward[u] if v not in backward[u]]
    only_anticlock = [(u, v) for u in range(n) for v in backward[u] if v not in forward[u]]
    shared = [(u, v) for u in range(n) for v in forward[u] if v in backward[u]]

    def peak(clock, anticlock):
        size = 2 * n + 2
        dc = [0] * size
        da = [0] * size
        for u, v in clock:
            dist = (v - u) % n
            dc[u] += 1
            dc[u + dist] -= 1
        for u, v in anticlock:
            low = v + n if v < u else v
            high = (u - 1) + n
            da[low] += 1
            da[high + 1] -= 1
        cc = [0] * n
        ca = [0] * n
        run_c = 0
        run_a = 0
        for k in range(2 * n):
            run_c += dc[k]
            run_a += da[k]
            if k < n:
                cc[k] = run_c
                ca[k] = run_a
            else:
                cc[k - n] += run_c
                ca[k - n] += run_a
        return max(cc), max(ca)

    best = None
    for mask in range(1 << len(shared)):
        clock = list(only_clock)
        anticlock = list(only_anticlock)
        for k, pair in enumerate(shared):
            if mask >> k & 1:
                clock.append(pair)
            else:
                anticlock.append(pair)
        high_clock, high_anticlock = peak(clock, anticlock)
        total = high_clock + high_anticlock
        if best is None or total < best:
            best = total
    return best


def both_pair_count(text):
    n = len(text)
    limit = n
    to_a = [limit] * n
    to_c = [limit] * n
    for k in range(2 * n - 1, -1, -1):
        place = k % n
        if text[place] == 'A':
            to_a[place] = 0
        else:
            step = to_a[(k + 1) % n] + 1
            to_a[place] = min(limit, step)
    for k in range(2 * n):
        place = k % n
        if text[(k - 1) % n] == 'C':
            to_c[place] = 1
        else:
            step = to_c[(k - 1) % n] + 1
            to_c[place] = min(limit, step)
    total = 0
    for u in range(n):
        far = min(u + to_a[u], u + n - 1)
        near = u - to_c[u] + 1 + n
        low = max(u + 1, near)
        if far >= low:
            total += far - low + 1
    return total


def longest_run(text, allowed):
    n = len(text)
    best = 0
    run = 0
    for k in range(2 * n):
        if text[k % n] in allowed:
            run += 1
            best = max(best, run)
        else:
            run = 0
    return min(best, n)


def one_sided_answer(text):
    n = len(text)
    full = n * (n - 1) // 2
    runs = []
    current = 0
    for ch in text:
        if ch == 'B':
            current += 1
        elif current > 0:
            runs.append(current)
            current = 0
    if current > 0:
        if runs and text[0] == 'B' and text[-1] == 'B':
            runs[0] += current
        else:
            runs.append(current)
    if not runs:
        return full
    pair_total = sum(length * (length + 1) // 2 for length in runs)
    capacities = [(length + 1) ** 2 // 4 for length in runs]
    best = 0
    for idx, length in enumerate(runs):
        outside = max(capacities[:idx] + capacities[idx + 1:], default=-1)
        for take in range(1, length + 1):
            base = take * (length - take + 1)
            if outside >= 0:
                best = max(best, base + outside)
            best = max(best, take * take // 4 + base)
            if take < length:
                vertex = (length + 1 + take) // 2
                for value_at in (max(take + 1, min(length, vertex)),
                                 max(take + 1, min(length, vertex + 1))):
                    best = max(best, value_at * (length + 1 + take - value_at) - take * take)
    return full - pair_total + best


def oracle_options(text):
    n = len(text)
    fwd=[0]*n; back=[0]*n
    for u in range(n):
        c=0
        for k in range(n):
            if text[(u+k)%n] in 'BC': c+=1
            else: break
        fwd[u]=min(c,n)
        c=0
        for k in range(n):
            if text[(u-k)%n] in 'AB': c+=1
            else: break
        back[u]=min(c,n)
    pairs=[]
    for u in range(n):
        for d in range(1,n):
            opts=[]
            if d<=fwd[u]:
                opts.append(frozenset((u+k)%n for k in range(d)))
            if d<=back[u]:
                opts.append(frozenset((u-k)%n for k in range(d)))
            if opts: pairs.append((u,(u+d)%n,opts))
    return pairs

def oracle(text):
    n = len(text)
    count_a = text.count('A')
    count_c = text.count('C')
    if count_a == 0 and count_c == 0:
        return n * n // 4
    if count_a == 0 or count_c == 0:
        return one_sided_answer(text)
    fwd = [0]*n
    run = 0
    for p in range(2*n-1, -1, -1):
        run = run+1 if text[p % n] in 'BC' else 0
        if p < n and run > 0:
            fwd[p] = run if run < n else n
    back = [0]*n
    for p in range(2*n):
        u = p % n
        prev = (u-1) % n
        back[u] = min(n, back[prev]+1) if text[prev] in 'AB' else 0

    D0 = [0]*(n+2); D1 = [0]*(n+2)
    def add_lin(l, r, a, b):
        if l > r or l<0 or r>=n: return
        D0[l]+=a; D1[l]+=b; D0[r+1]-=a; D1[r+1]-=b
    for u in range(n):
        dC = min(fwd[u], n-back[u]-1)
        if dC >= 1:
            lo = min(dC-1, n-1-u)
            add_lin(u, u+lo, u+dC, -1)
            if dC-1 > lo:
                add_lin(0, dC-1-lo-1, u+dC-n, -1)
        eAhi = min(back[u], n-fwd[u]-1)
        if eAhi >= 1:
            lo = min(eAhi, u)
            if lo >= 1: add_lin(u-lo, u-1, eAhi+1-u, 1)
            if eAhi > lo: add_lin(n+u-eAhi, n-1, eAhi+1-u-n, 1)
    F = []; c0=c1=0
    for p in range(n):
        c0+=D0[p]; c1+=D1[p]; F.append(c0+p*c1)

    D2 = [0]*(n+2); DA0 = [0]*(n+2); DA1 = [0]*(n+2)
    def add2(l,r,v):
        if l>r or r>=n: return
        D2[l]+=v; D2[r+1]-=v
    def add_linA(l,r,a,b):
        if l>r or r>=n: return
        DA0[l]+=a; DA1[l]+=b; DA0[r+1]-=a; DA1[r+1]-=b
    def add_t_range(u, tlo, thi, a, b):
        if tlo > thi: return
        tl=u+tlo; tr=u+thi
        if tr<n: add_linA(tl,tr,a,b)
        elif tl>=n: add_linA(tl-n,tr-n,a+b*n,b)
        else:
            add_linA(tl,n-1,a,b); add_linA(0,tr-n,a+b*n,b)
    dlo=[0]*n; dhi=[-1]*n
    arcs=[]
    for u in range(n):
        lo=max(1,n-back[u]); hi=min(fwd[u],n-1)
        if lo<=hi:
            dlo[u]=lo; dhi[u]=hi
            add_t_range(u,0,lo-1,hi-lo+1,0)
            add_t_range(u,lo,hi-1,hi+u,-1)
            for d in range(lo,hi+1):
                arcs.append((u,u+d))
    A=[]; cur=ca0=ca1=0
    for p in range(n):
        cur+=D2[p]; ca0+=DA0[p]; ca1+=DA1[p]
        A.append(cur+ca0+p*ca1)
    H=[F[i]+A[i] for i in range(n)]

    G1=[0]*n; G2=[0]*n; G3=[0]*n
    if dhi[0]>=dlo[0]:
        for j in range(n):
            G1[j]=sum(1 for d in range(dlo[0],dhi[0]+1) if d>j)
    D3=[0]*(n+2)
    for u in range(n):
        if dhi[u]>=dlo[u]:
            Rlo=u+dlo[u]; Rhi=u+dhi[u]
            cnt=max(0,Rhi-max(Rlo,n+1)+1)
            if cnt>0: D3[u]+=cnt; D3[n]-=cnt
    cur=0
    for p in range(n): cur+=D3[p]; G2[p]=cur
    end_u=[[] for _ in range(2*n+2)]
    ec=[0]*(2*n+2)
    for u,r in arcs:
        ec[r]+=1; end_u[r].append(u)
    suff=0
    for r in range(2*n+1,-1,-1):
        suff+=ec[r]
        if 0<=r-n-1<n: G3[r-n-1]=suff
    val=[H[j]+A[0]-2*G1[j]-2*G2[j]-2*G3[j] for j in range(n)]

    events=[[] for _ in range(2*n+2)]
    for u,r in arcs:
        events[u].append((0,u,r))
        events[r].append((1,u,r))
        if r>n: events[r-n].append((2,u,r))

    class Seg:
        def __init__(self, arr):
            self.sz=1
            while self.sz<len(arr): self.sz*=2
            N=self.sz; self.mx=[-10**18]*(2*N); self.lz=[0]*(2*N)
            for i,x in enumerate(arr): self.mx[N+i]=x
            for i in range(N-1,0,-1): self.mx[i]=max(self.mx[2*i],self.mx[2*i+1])
        def apply(self,node,v): self.mx[node]+=v; self.lz[node]+=v
        def push(self,node):
            v=self.lz[node]
            if v: self.apply(2*node,v); self.apply(2*node+1,v); self.lz[node]=0
        def add(self,node,l,r,ql,qr,v):
            if qr<l or r<ql: return
            if ql<=l and r<=qr: self.apply(node,v); return
            self.push(node); m=(l+r)//2
            self.add(2*node,l,m,ql,qr,v); self.add(2*node+1,m+1,r,ql,qr,v)
            self.mx[node]=max(self.mx[2*node],self.mx[2*node+1])
        def query(self,node,l,r,ql,qr):
            if qr<l or r<ql: return -10**18
            if ql<=l and r<=qr: return self.mx[node]
            self.push(node); m=(l+r)//2
            return max(self.query(2*node,l,m,ql,qr),self.query(2*node+1,m+1,r,ql,qr))
    seg=Seg(val)
    best=max(F)
    for g in range(n):
        if g>0:
            mv=seg.query(1,0,seg.sz-1,0,g-1)
            cand=(F[g]+mv+1)//2
            if cand>best: best=cand
        pos=g+1
        if pos<len(events):
            for typ,u,r in events[pos]:
                hi1=min(n-1,r-1); hi2=min(n-1,r-n-1) if r>n else -1
                comp_lo=hi2+1 if hi2>=0 else 0
                comp_hi=u-1
                tail_lo=r if r<=n else n
                if typ==0:
                    if u<=hi1: seg.add(1,0,seg.sz-1,u,hi1,-1)
                    if 0<=hi2: seg.add(1,0,seg.sz-1,0,hi2,-1)
                    if comp_lo<=comp_hi and comp_lo<n: seg.add(1,0,seg.sz-1,comp_lo,min(n-1,comp_hi),1)
                    if tail_lo<n: seg.add(1,0,seg.sz-1,tail_lo,n-1,1)
                elif typ==1:
                    if u<=hi1: seg.add(1,0,seg.sz-1,u,hi1,1)
                    if 0<=hi2: seg.add(1,0,seg.sz-1,0,hi2,1)
                    if comp_lo<=comp_hi and comp_lo<n: seg.add(1,0,seg.sz-1,comp_lo,min(n-1,comp_hi),-1)
                    if tail_lo<n: seg.add(1,0,seg.sz-1,tail_lo,n-1,-1)
                else:
                    upto=r-n-1
                    if 0<=upto<n: seg.add(1,0,seg.sz-1,0,upto,1)
                    if r-n<=u-1 and r-n<n: seg.add(1,0,seg.sz-1,r-n,min(n-1,u-1),-1)
                    if u<n: seg.add(1,0,seg.sz-1,u,n-1,1)
    return best


SAMPLE_INPUT = "2\n3\nAAA\n4\nBACB\n"
SAMPLE_OUTPUT = "3\n5\n"

assert oracle("AAA") == 3
assert oracle("BACB") == 5
assert oracle("ABC") == 2
assert oracle("BBB") == 2
assert oracle("ACAC") == 1
for n in range(3, 6):
    for chars in product('ABC', repeat=n):
        text = ''.join(chars)
        val = oracle(text)
        assert 0 <= val <= n * (n - 1) // 2, text


def write_case(name, cases):
    input_text = str(len(cases)) + "\n"
    for n, text in cases:
        input_text += str(n) + "\n" + text + "\n"
    output_text = "".join(str(oracle(text)) + "\n" for n, text in cases)
    (ROOT / "in" / (name + ".txt")).write_text(input_text)
    (ROOT / "out" / (name + ".out")).write_text(output_text)


def build():
    edges = [
        (3, "AAA"), (3, "CCC"), (3, "BBB"), (3, "ABC"), (3, "BAC"),
        (3, "AAB"), (3, "BBC"), (4, "ACAC"), (4, "BACB"), (4, "ABCA"),
        (5, "AACCC"), (5, "CCCAA"), (5, "BABAB"), (5, "AABBC"),
    ]
    write_case("2_edges", edges)

    big = 100000
    wide = [
        (big, "A" * big),
        (big, "C" * big),
        (big, "B" * big),
        (big, "A" * (big // 2) + "C" * (big // 2)),
        (big, "AC" * (big // 2)),
        (big, "B" + "A" * (big - 1)),
        (big, "B" + "C" * (big - 1)),
        (big, "A" + "B" * (big - 1)),
        (big, "C" + "B" * (big - 1)),
        (big, ("ABC" * ((big + 2) // 3))[:big]),
    ]
    write_case("3_wide", wide)

    rng = random.Random(2026)
    random_cases = []
    for _ in range(40):
        n = rng.randint(3, 20000)
        text = ''.join(rng.choice('ABC') for _ in range(n))
        random_cases.append((n, text))
    write_case("4_random", random_cases)

    io_cases = []
    for _ in range(100):
        n = 100000
        text = ''.join(rng.choice('ABC') for _ in range(n))
        io_cases.append((n, text))
    write_case("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_INPUT)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUTPUT)
build()
