//g++  7.4.0

#include <bits/stdc++.h>
#define f(i,a,b) for(int i=a;i<b;++i)
using namespace std;

int main()
{
    ios_base::sync_with_stdio(false);
    cin.tie(0);
    cout.tie(0);
    
    int n, m, u, v, w, q, x, y, e;
    cout<<"Enter the number of vertices and edges\n";
    cin>>n>>m;
    map<pair<int, int>, int> wt;
    set<int> out[n];
    cout<<"Enter the edges (u -> v,  w) in the form <u, v, w> on each line. Use zero-based indices.\n";
    f(i,0,m)cin>>u>>v>>w, wt[{u, v}]=w, out[u].insert(v);
    cout<<"Enter the number of queries\n";
    cin>>q;
    
    // Dijkshtra's algo (preprocessing)
    int p[n], d[n];
    memset(p, -1, sizeof(p));
    d[0]=0;
    f(i,1,n)d[i]=INT_MAX;
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
    
    // Acting on queries
    priority_queue<pair<int, int>, vector<pair<int, int>>, std::greater<pair<int, int>> > H;
    int mark[n];
    memset(mark, 0, sizeof(mark));
    while(q--){
        // Print statement after every query increases the complexity to O(q*n).
        
        /*f(i,0,n)cout<<d[i]<<" ";
        cout<<"\n";*/
        
        cin>>e>>x>>y;
        if(e)cin>>w;
        if(e&&(out[x].find(y)==out[x].end()||w<wt[{x, y}])){
            if(out[x].find(y)==out[x].end())out[x].insert(y);
            wt[{x, y}]=w;
        }
        else{
            
            if(e)wt[{x, y}]=w;
            else wt.erase({x, y}),out[x].erase(y);          
        }
        memset(p, -1, sizeof(p));
        d[0]=0;
        f(i,1,n)d[i]=INT_MAX;
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
    }
    
    f(i,0,n)cout<<d[i]<<" ";
    cout<<"\n";
}
