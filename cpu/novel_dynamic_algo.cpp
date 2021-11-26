//g++  7.4.0

#include <bits/stdc++.h>
#define f(i,a,b) for(int i=a;i<b;++i)
using namespace std;

const int MX=1e6;
vector<set<int>> in;
vector<set<int>> out;


int main()
{
    ios_base::sync_with_stdio(false);
    cin.tie(0);
    cout.tie(0);
    
    int n, m, u, v, w, q, x, y, e;
    cin>>n>>m>>q;
    map<pair<int, int>, int> wt;
    in.resize(n+3);
    out.resize(n+3);
    f(i,0,m)cin>>u>>v>>w, wt[{u-1, v-1}]=w, in[v-1].insert(u-1), out[u-1].insert(v-1);
    
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
    cout<<endl;
    
    // Acting on queries
    priority_queue<pair<int, int>, vector<pair<int, int>>, std::greater<pair<int, int>> > H;
    int mark[n];
    memset(mark, 0, sizeof(mark));
    while(q--){
        
        cin>>e>>x>>y;
        x--;
        y--;
        if(e)cin>>w;
        if(e&&(out[x].find(y)==out[x].end()||w<wt[{x, y}])){
            // Incremental algo
            if(out[x].find(y)==out[x].end())out[x].insert(y),in[y].insert(x);
            wt[{x, y}]=w;
            if(d[y]<d[x]+w){
                f(i,0,n)cout<<d[i]<<" ";
                cout<<"\n";
                continue;
            }
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
            if(p[y]!=x){
                f(i,0,n)cout<<d[i]<<" ";
                cout<<"\n";
                continue;
            }
            
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
                d[u]=1e9;
                p[u]=-1;
                // find pred_min(u) 
                int best_pred = -1, min_d = 1e9;
                for(auto z:in[u])if(min_d>d[z]+wt[{z,u}]){
                    min_d=d[z]+wt[{z,u}];
                    best_pred=z;
                }
                if(best_pred!=-1){
                    if(mark[best_pred])d[u]=1e9, H.push({d[u], u});
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
        f(i,0,n)cout<<d[i]<<" ";
        cout<<"\n";
    }
}
