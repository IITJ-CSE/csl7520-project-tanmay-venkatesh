#include <bits/stdc++.h>
#define f(i,a,b) for(int i=a;i<b;++i)
#define pii pair<int, int>
using namespace std;
using namespace std::chrono;

#include <ext/pb_ds/assoc_container.hpp>
#include <ext/pb_ds/tree_policy.hpp>
using namespace __gnu_pbds;

#define ordered_set tree<pii, null_type,less<pii>, rb_tree_tag,tree_order_statistics_node_update>
#define ok order_of_key
#define fo find_by_order


inline int randint(int l, int r)
{
    mt19937 rng(chrono::steady_clock::now().time_since_epoch().count());
    return l+rng()%(r-l+1);
}

int main()
{
    int n, m, q, e;
    cin>>n>>m>>q;
    cout<<n<<" "<<m<< " "<<q<<"\n";
    ordered_set cur;
    map<pii, int> wt;
    f(i,0,m){
        int u, v;
        if(i<n-1){
            u=i+1;
            v=i+2;
        }
        else{
            u=randint(1,n);
            v=randint(1,n);
        }
        if(u==v||cur.find({u,v})!=cur.end()){
            i--;continue;
        }
        e=randint(1,20);
        cur.insert({u,v});
        wt[{u,v}]=e;
        cout<<u<<" "<<v<<" "<<e<<"\n";
    }
    
    while(q--){
        int e=randint(1,4);
        if(e==1){
            int k=cur.size();
            e=randint(0,k-1);
            auto it=cur.fo(e);
            if(it->second-it->first==1){
                q++;
                continue;
            }
            cout<<"0 "<<it->first<<" "<<it->second<<"\n";
            wt.erase({it->first,it->second});
            cur.erase(it);
        }
        else if(e==2){
            int u=randint(1, n);
            int v=randint(1, n);
            if(u==v||cur.find({u,v})!=cur.end()){
                q++;continue;
            }
            e=randint(1,20);
            cur.insert({u,v});
            wt[{u,v}]=e;
            cout<<"1 "<<u<<" "<<v<<" "<<e<<"\n";
        }
        else if(e==3){
            int k=cur.size();
            e=randint(0,k-1);
            auto it=cur.fo(e);
            e=randint(wt[{it->first,it->second}],20);
            cout<<"1 "<<it->first<<" "<<it->second<<" "<<e<<"\n";
            wt[{it->first,it->second}]=e;
        }
        else{
            int k=cur.size();
            e=randint(0,k-1);
            auto it=cur.fo(e);
            e=randint(1,wt[{it->first,it->second}]);
            cout<<"1 "<<it->first<<" "<<it->second<<" "<<e<<"\n";
            wt[{it->first,it->second}]=e;
        }
    }
}
