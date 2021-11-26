#include <bits/stdc++.h>
#define f(i,a,b) for(int i=a;i<b;++i)
using namespace std;
using namespace std::chrono;

int main()
{
    auto start = high_resolution_clock::now();
    ios_base::sync_with_stdio(false);
    cin.tie(0);
    cout.tie(0);

    int n, m;
    cin>>n>>m;
    vector<array<int,3>> e(m);
    f(i,0,m) cin>>e[i][0]>>e[i][1]>>e[i][2];
    vector<int> d(n+1,INT_MAX);
    d[1]=0;
    f(i,1,n+1) f(j,0,m) if(d[e[j][0]]!=INT_MAX) d[e[j][1]]=min(d[e[j][1]],d[e[j][0]]+e[j][2]);

    f(i,1,n+1) cout<<d[i]<<" ";
    cout<<endl;
    auto stop = high_resolution_clock::now();
    auto duration = duration_cast<microseconds>(stop - start);
    ofstream ot("cpu_perf.txt");
    ot<<duration.count()/1000.0<<"\n";
}
