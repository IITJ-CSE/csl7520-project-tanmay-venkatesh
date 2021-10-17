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
    set<int> in[n], out[n];
    cout<<"Enter the edges (u -> v,  w) in the form <u, v, w> on each line. Use zero-based indices.\n";
    f(i,0,m)cin>>u>>v>>w, wt[{u, v}]=w, in[v].insert(u), out[u].insert(v);
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
        /*
        f(i,0,n)cout<<d[i]<<" ";
        cout<<"\n";
        */
        cin>>e>>x>>y;
        if(e)cin>>w;
        if(e&&(out[x].find(y)==out[x].end()||w<wt[{x, y}])){
            // Incremental algo
            if(out[x].find(y)==out[x].end())out[x].insert(y),in[y].insert(x);
            wt[{x, y}]=w;
            if(d[y]<d[x]+w)continue;
            p[y]=x;
            d[y]=d[x]+w;
            H.push({d[y], y});
            while(!H.empty()){
                u=H.top().second;
                H.pop();
                for(auto z:out[u])if(d[z]>d[u]+wt[{u, z}]){
                    d[z]=d[u]+wt[{u, z}];
                    p[z]=u;
                    H.push({d[z], z});
                }
            }
        }
        else{
            
            // Decremental algo
            
            if(e)wt[{x, y}]=w;
            else wt.erase({x, y}),out[x].erase(y), in[y].erase(x);
            if(p[y]!=x)continue;
            
            // Mark all the vertices in T(v)
            stack<int> st;
            vector<int> Tv;
            st.push(y);
            while(!st.empty()){
                u=st.top();
                st.pop();
                mark[u]=1;
                Tv.push_back(u);
                for(auto z:out[u])if(p[z]==u)st.push(z);
            }
            
            H.push({d[y], y});int c=0;
            while(!H.empty()){
                u=H.top().second;
                H.pop(); 
                int old_val=d[u];
                d[u]=INT_MAX;
                p[u]=-1;
                // find pred_min(u) 
                int best_pred = -1, min_d = INT_MAX;
                for(auto z:in[u])if(min_d>d[z])min_d=d[z], best_pred=z;
                if(best_pred!=-1){
                    if(mark[best_pred])d[u]=INT_MAX, H.push({d[u], u});
                    else{
                        mark[u]=0;
                        d[u]=d[best_pred]+wt[{best_pred, u}];
                        p[u]=best_pred;
                    }
                }
                if(d[u]!=old_val){
                    for(auto z:out[u]){
                        if(p[z]==u)H.push({d[z], z});
                        else if(d[u]+wt[{u, z}]<d[z])H.push({d[u]+wt[{u, z}], z});
                    }
                }
                else{
                    stack<int> st;
                    st.push(u);
                    while(!st.empty()){
                        v=st.top();
                        st.pop();
                        mark[v]=0;
                        for(auto z:out[v])if(p[z]==v)st.push(z);
                    }
                }
            }
            for(auto z:Tv)mark[z]=0;
        }
    }
    
    f(i,0,n)cout<<d[i]<<" ";
    cout<<"\n";
    
    
}
