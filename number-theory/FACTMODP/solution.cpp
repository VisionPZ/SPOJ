
#include <bits/stdc++.h>
using namespace std;
using u64 = uint64_t;
static inline u64 isqrt_u64(u64 x){
    u64 r = std::sqrt((long double)x);
    while((__uint128_t)(r+1)*(r+1)<=x) r++;
    while((__uint128_t)r*r>x) r--;
    return r;
}
static u64 modpow(u64 a,u64 e,u64 m){u64 r=1%m;while(e){if(e&1)r=(u64)((__uint128_t)r*a%m);a=(u64)((__uint128_t)a*a%m);e>>=1;}return r;}
struct NP{u64 mod,root;int lg;};
static const NP P[3]={{2013265921ULL,31,27},{1811939329ULL,13,26},{1004535809ULL,3,21}};
static u64 pmod;
// CRT constants, initialised once in main()
static u64 M1,M2,M3,INVM1,INVM12,C1,C12;

static void ntt(vector<u64>& a,const NP& pr,bool inv){
    int n=a.size();
    for(int i=1,j=0;i<n;i++){int b=n>>1;for(;j&b;b>>=1)j^=b;j^=b;if(i<j)swap(a[i],a[j]);}
    for(int len=2;len<=n;len<<=1){
        u64 wl=modpow(pr.root,(pr.mod-1)/len,pr.mod);
        if(inv)wl=modpow(wl,pr.mod-2,pr.mod);
        for(int i=0;i<n;i+=len){
            u64 w=1;
            for(int k=0;k<len/2;k++){
                u64 u=a[i+k],v=(u64)((__uint128_t)a[i+k+len/2]*w%pr.mod);
                u64 x=u+v; if(x>=pr.mod)x-=pr.mod;
                u64 y=u>=v?u-v:u+pr.mod-v;
                a[i+k]=x;a[i+k+len/2]=y;w=(u64)((__uint128_t)w*wl%pr.mod);
            }
        }
    }
    if(inv){u64 ni=modpow(n,pr.mod-2,pr.mod);for(auto&x:a)x=(u64)((__uint128_t)x*ni%pr.mod);}
}

// one polynomial multiplication mod pmod via 3 NTTs + Garner CRT
static vector<u64> mul(const vector<u64>& a,const vector<u64>& b){
    int need=(int)a.size()+(int)b.size()-1;
    if((int)a.size()<=24 || (int)b.size()<=24){ // naive for tiny polys
        vector<u64> c(need,0);
        for(size_t i=0;i<a.size();i++) if(a[i])
            for(size_t j=0;j<b.size();j++) if(b[j])
                c[i+j]=(c[i+j]+(u64)((__uint128_t)a[i]*b[j]%pmod))%pmod;
        while(c.size()>1&&c.back()==0)c.pop_back();
        return c;
    }
    int n=1;while(n<need)n<<=1;
    const u64 m1=M1,m2=M2,m3=M3;
    u64 invm1=INVM1, invm12=INVM12;
    u64 c1=C1,c12=C12;
    vector<vector<u64>> rs(3,vector<u64>(need));
    for(int t=0;t<3;t++){
        vector<u64> fa(n),fb(n);
        for(size_t i=0;i<a.size();i++)fa[i]=a[i]%P[t].mod;
        for(size_t i=0;i<b.size();i++)fb[i]=b[i]%P[t].mod;
        ntt(fa,P[t],false);ntt(fb,P[t],false);
        for(int i=0;i<n;i++)fa[i]=(u64)((__uint128_t)fa[i]*fb[i]%P[t].mod);
        ntt(fa,P[t],true);
        rs[t].assign(fa.begin(),fa.begin()+need);
    }
    vector<u64> out(need);
    for(int i=0;i<need;i++){
        u64 r1=rs[0][i],r2=rs[1][i],r3=rs[2][i];
        u64 t2=(u64)((__uint128_t)((r2 + m2 - r1%m2)%m2)*invm1%m2);
        u64 u12=(r1%m3 + (u64)((__uint128_t)(m1%m3)*t2%m3))%m3;
        u64 t3=(u64)((__uint128_t)((r3 + m3 - u12)%m3)*invm12%m3);
        u64 x=(r1%pmod + (u64)((__uint128_t)c1*(t2%pmod)%pmod))%pmod;
        x=(x + (u64)((__uint128_t)c12*(t3%pmod)%pmod))%pmod;
        out[i]=x;
    }
    while(out.size()>1&&out.back()==0)out.pop_back();
    return out;
}

static vector<u64> invpoly(const vector<u64>& a,int n){
    vector<u64> b(1,modpow(a[0],pmod-2,pmod));
    for(int k=1;k<n;k*=2){
        int m=min(2*k,n);
        vector<u64> f(a.begin(),a.begin()+min((int)a.size(),m));
        vector<u64> fb=mul(f,b);fb.resize(m);
        vector<u64> t(m);
        for(int i=0;i<m;i++)t[i]=(i<(int)fb.size()? (pmod-fb[i])%pmod:0);
        t[0]=(t[0]+2)%pmod;
        vector<u64> nb=mul(b,t);nb.resize(m);
        b=nb;
    }
    b.resize(n);return b;
}

// remainder a mod b (b monic or invertible leading coefficient)
static vector<u64> rempoly(const vector<u64>& a,const vector<u64>& b){
    int n=a.size(),m=b.size();
    if(n<m)return a;
    int qn=n-m+1;
    vector<u64> rb(b.rbegin(),b.rend());
    vector<u64> ir=invpoly(rb,qn);
    vector<u64> ra(a.rbegin(),a.rend());
    vector<u64> q=mul(ra,ir);q.resize(qn);
    reverse(q.begin(),q.end());
    vector<u64> prod=mul(q,b);
    vector<u64> r(min((int)prod.size(),n));
    for(int i=0;i<(int)r.size();i++)r[i]=(a[i]+pmod-(i<(int)prod.size()?prod[i]:0))%pmod;
    while(r.size()>1&&r.back()==0)r.pop_back();
    return r;
}

static u64 horner(const vector<u64>& f,u64 x){u64 v=0;for(int i=(int)f.size()-1;i>=0;i--)v=((__uint128_t)v*x+f[i])%pmod;return v;}

struct Tree{vector<vector<vector<u64>>> lv;};
static Tree build(const vector<vector<u64>>& leaves){
    Tree t;t.lv.push_back(leaves);
    while(t.lv.back().size()>1){
        auto&prev=t.lv.back();vector<vector<u64>> cur;
        for(size_t i=0;i<prev.size();i+=2)
            cur.push_back(i+1<prev.size()?mul(prev[i],prev[i+1]):prev[i]);
        t.lv.push_back(cur);
    }
    return t;
}
static vector<u64> evaluate(const vector<u64>&F,const Tree&t){
    int L=t.lv.size()-1;
    const auto&root=t.lv[L][0];
    vector<vector<u64>> R;
    R.push_back(root.size()>1?rempoly(F,root):vector<u64>{horner(F,(pmod-root[0])%pmod)});
    int li=L;
    while(li>0){
        vector<vector<u64>> nxt;
        for(size_t i=0;i<R.size();i++){
            const auto&lp=t.lv[li-1][2*i], &rp=t.lv[li-1][2*i+1];
            nxt.push_back(lp.size()>1?rempoly(R[i],lp):vector<u64>{horner(R[i],(pmod-lp[0])%pmod)});
            nxt.push_back(rp.size()>1?rempoly(R[i],rp):vector<u64>{horner(R[i],(pmod-rp[0])%pmod)});
        }
        R=nxt;li--;
    }
    vector<u64> out;for(auto&v:R)out.push_back(v[0]%pmod);
    return out;
}

static const int inputBlockBytes = 1 << 16;
static string inputData;

static void readInput() {
    char block[inputBlockBytes];
    size_t count = 0;
    while ((count = fread(block, 1, inputBlockBytes, stdin)) > 0) {
        inputData.append(block, count);
    }
}

static size_t scanPos = 0;

static u64 nextUnsigned() {
    while (scanPos < inputData.size() && (inputData[scanPos] < '0' || inputData[scanPos] > '9')) scanPos += 1;
    u64 value = 0;
    while (scanPos < inputData.size() && inputData[scanPos] >= '0' && inputData[scanPos] <= '9') {
        value = value * 10 + (inputData[scanPos] - '0');
        scanPos += 1;
    }
    return value;
}

static u64 solveCase(u64 N, u64 prime) {
    pmod = prime;
    C1 = M1 % pmod;
    C12 = (u64)((__uint128_t)M1 * M2 % pmod);
    if (N >= pmod) return 0;
    u64 m = isqrt_u64(pmod - 1) + 1;
    u64 q = N / m;
    u64 r = N % m;
    if (q == 0) {
        u64 value = 1;
        for (u64 i = 2; i <= N; i += 1) value = (u64)((__uint128_t)value * i % pmod);
        return value;
    }
    vector<vector<u64>> leaves;
    for (u64 i = 1; i <= m; i += 1) leaves.push_back({i % pmod, 1});
    Tree Ht = build(leaves);
    const auto& H = Ht.lv.back()[0];
    u64 padded = 1;
    while (padded < q) padded <<= 1;
    vector<vector<u64>> points;
    for (u64 j = 0; j < padded; j += 1) {
        u64 location = (j % padded) * m % pmod;
        points.push_back({(pmod - location) % pmod, 1});
    }
    Tree Tt = build(points);
    vector<u64> values = evaluate(H, Tt);
    u64 answer = 1;
    for (u64 j = 0; j < q; j += 1) answer = (u64)((__uint128_t)answer * (values[j] % pmod) % pmod);
    for (u64 i = 1; i <= r; i += 1) answer = (u64)((__uint128_t)answer * ((q * m + i) % pmod) % pmod);
    return answer;
}

int main() {
    M1 = P[0].mod; M2 = P[1].mod; M3 = P[2].mod;
    INVM1 = modpow(M1 % M2, M2 - 2, M2);
    INVM12 = modpow((u64)((__uint128_t)M1 * M2 % M3), M3 - 2, M3);
    readInput();
    u64 caseCount = nextUnsigned();
    string output;
    output.reserve((size_t)caseCount * 14);
    for (u64 caseIndex = 0; caseIndex < caseCount; caseIndex += 1) {
        u64 N = nextUnsigned();
        u64 prime = nextUnsigned();
        output += to_string(solveCase(N, prime));
        output += (caseIndex + 1 == caseCount ? '\n' : ' ');
    }
    fwrite(output.data(), 1, output.size(), stdout);
    return 0;
}
