#include <bits/stdc++.h>
#define f(i,a,b) for(int i=a;i<b;++i)
using namespace std;

int main()
{
    ios_base::sync_with_stdio(false);
    cin.tie(0);
    cout.tie(0);
    
    int n, m, u, v, w, q, x, y, e;
    cin>>n>>m;
    map<pair<int, int>, int> wt;
    set<int> out[n];
    f(i,0,m)cin>>u>>v>>w, wt[{u-1, v-1}]=w, out[u-1].insert(v-1);
    
    // Dijkshtra's algo (preprocessing)
    int p[n], d[n];
    memset(p, -1, sizeof(p));
    d[0]=0;
    f(i,1,n)d[i]=1e9;
    set<pair<int, int>> S;
    S.insert({d[0], 0});
    while(!S.empty()){
        u=S.begin()->second;
        w=S.begin()->first;
        S.erase(S.begin());
        for(auto z:out[u])if(d[z]>w+wt[{u, z}]){
            S.erase({d[z], z});
            d[z]=w+wt[{u, z}];
            S.insert({d[z], z});
            p[z]=u;
        }
    }
    
    f(i,0,n)cout<<d[i]<<" ";
    cout<<"\n";
}
