#include <bits/stdc++.h>
using namespace std;
using namespace std::chrono;

#define f(i,a,b) for(int i=a;i<b;++i)
 
typedef struct edge{
    int u, v, w;
}edge;


const int blockSize = 256;
int numBlocks;
float exec_time = 0;
 
bool edgeComparator(edge &e1, edge &e2){
    if(e1.u==e2.u)return e1.v<e2.v;
    return e1.u<e2.u;
}
 
__global__
void initialise(int n, int *wt, bool *mask)
{
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    for (int i = index; i < n; i += stride){
        mask[i]=0;
        if(!i){
            wt[i]=0;
        }
        else{
            wt[i]=1000000000;
        }
    }   
}

__global__
void relax(int n, int *v, int *wt, int *ea, int *es, int *ew, bool *mask){
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    for (int i = index; i < v[n]; i += stride){
        if(wt[ea[i]]>wt[es[i]]+ew[i]){
            atomicExch(&wt[ea[i]], wt[es[i]]+ew[i]);
        }
    }
}

void bellman_ford(int n, int *v, int *wt, int *ea, int *es, int *ew, bool *mask){
        int numBlocks = (n + blockSize - 1) / blockSize;
        cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    cudaEventRecord(start);
    initialise<<<numBlocks, blockSize>>>(n, wt, mask);
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);
    float tmp = 0;
    cudaEventElapsedTime(&tmp, start, stop);
    exec_time+=tmp;
        int numBlocksE = (v[n] + blockSize - 1) / blockSize;
        for(int i=0;i<n-1;++i){
        cudaEventCreate(&start);
        cudaEventCreate(&stop);
        cudaEventRecord(start);
        relax<<<numBlocksE, blockSize>>>(n, v, wt, ea, es, ew, mask);
        cudaEventRecord(stop);
        cudaEventSynchronize(stop);
        float tmp = 0;
        cudaEventElapsedTime(&tmp, start, stop);
        exec_time+=tmp;
    }
        for(int i=0;i<n;++i)cout<<wt[i]<<" ";cout<<"\n";
}
 

 
 
int main(void)
{
    ios_base::sync_with_stdio(false);
    cin.tie(0);
    cout.tie(0);
    int n, m, l, r, w;
    cin>>n>>m;
    vector<edge> edges;
    f(i,0,m)cin>>l>>r>>w, edges.push_back({l-1, r-1, w});
    sort(edges.begin(), edges.end(), edgeComparator);
    
    int *wt, *v, *ea, *es, *ew;
    bool *mask;
    auto start = high_resolution_clock::now();
    // Allocate Unified Memory – accessible from CPU or GPU
    cudaMallocManaged(&wt, n*sizeof(int));
    cudaMallocManaged(&v, (n+1)*sizeof(int));
    cudaMallocManaged(&ea, m*sizeof(int));
        cudaMallocManaged(&es, m*sizeof(int));
    cudaMallocManaged(&ew, m*sizeof(int));
    cudaMallocManaged(&mask, n*sizeof(bool));
    
    int curv=0;v[0]=0;
    f(i,0,m){
        while(curv<edges[i].u)v[++curv]=i;
        ea[i]=edges[i].v;
        es[i]=edges[i].u;
        ew[i]=edges[i].w;
    }
    while(curv<n)v[++curv]=m;
    /*f(i,0,n)cout<<v[i]<<" ";cout<<endl;
    f(i,0,m)cout<<ea[i]<<" ";cout<<endl;
    f(i,0,m)cout<<ew[i]<<" ";cout<<endl;*/
 
    bellman_ford(n, v, wt, ea, es, ew, mask);
 
    // Free memory
    cudaFree(wt);
    cudaFree(v);
    cudaFree(ea);
        cudaFree(es);
    cudaFree(ew);
    cudaFree(mask);
    
    auto stop = high_resolution_clock::now();
    auto duration = duration_cast<microseconds>(stop - start);
    ofstream ot("gpu_perf.txt");
    ot<<duration.count()/1000.0<<"\n";
 
    return 0;
}
