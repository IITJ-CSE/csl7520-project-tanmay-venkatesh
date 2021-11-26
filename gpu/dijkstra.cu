#include <bits/stdc++.h>
using namespace std;
#define f(i,a,b) for(int i=a;i<b;++i)
 
typedef struct edge{
    int u, v, w;
}edge;

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
void threshold(int n, int* v, int *wt, int *ea, int *ew, bool *mask, int *thrd){
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    for (int i = index; i < n; i += stride){
        //printf("id %d\n", i);
        if(!mask[i]&&wt[i]<1000000000){
            for(int j=v[i];j<v[i+1];++j)if(!mask[ea[j]]){
                //printf("edge %d %d\n", i, ea[j]);
                /*if(*thrd > wt[i] + ew[j]){
                    atomicCAS(thrd, *thrd, wt[i]+ew[j]);
                    //printf("%d %d\n", ea[j], *thrd);
                }*/
                atomicMin(thrd, wt[i]+ew[j]);
            }
        }
    }
}
 
__global__
void relax(int n, int *v, int *wt, int *ea, int *ew, bool *mask, int *thrd){
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    for (int i = index; i < n; i += stride){
        if(!mask[i]&&wt[i]<*thrd){
            mask[i]=1;
            for(int j=v[i];j<v[i+1];++j){
                //if(wt[ea[j]] > wt[i] + ew[j])atomicCAS(&wt[ea[j]], wt[ea[j]], wt[i]+ew[j]);
                atomicMin(&wt[ea[j]], wt[i]+ew[j]);
            }
        }
    }
}
 
void dijkstra(int n, int *v, int *wt, int *ea, int *ew, bool *mask, int *thrd){
    int blockSize = 256;
    int numBlocks = (n + blockSize - 1) / blockSize;
    //cout<<"s1"<<endl;
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
    //cout<<"s2"<<endl;
    *thrd = 0;
    //cout<<"bf"<<endl;
    //cout<<*thrd<<endl;
    //cout<<"bf2"<<endl;
    while(*thrd<1000000000){
        *thrd=1000000000;
        cudaEventCreate(&start);
        cudaEventCreate(&stop);
        cudaEventRecord(start);
        threshold<<<numBlocks, blockSize>>>(n, v, wt, ea, ew, mask, thrd);
        cudaEventRecord(stop);
        cudaEventSynchronize(stop);
        tmp = 0;
        cudaEventElapsedTime(&tmp, start, stop);
        exec_time+=tmp;
        cudaEventCreate(&start);
        cudaEventCreate(&stop);
        cudaEventRecord(start);
        relax<<<numBlocks, blockSize>>>(n, v, wt, ea, ew, mask, thrd);
        cudaEventRecord(stop);
        cudaEventSynchronize(stop);
        tmp = 0;
        cudaEventElapsedTime(&tmp, start, stop);
        exec_time+=tmp;
    }
    f(i,0,n)cout<<wt[i]<<" ";cout<<endl;
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
    
    int *wt, *v, *ea, *ew, *thrd;
    bool *mask;
 
    // Allocate Unified Memory – accessible from CPU or GPU
    cudaMallocManaged(&wt, n*sizeof(int));
    cudaMallocManaged(&v, (n+1)*sizeof(int));
    cudaMallocManaged(&ea, m*sizeof(int));
    cudaMallocManaged(&ew, m*sizeof(int));
    cudaMallocManaged(&mask, n*sizeof(bool));
    cudaMallocManaged(&thrd, sizeof(int));
    
    int curv=0;v[0]=0;
    f(i,0,m){
        while(curv<edges[i].u)v[++curv]=i;
        ea[i]=edges[i].v;
        ew[i]=edges[i].w;
    }
    while(curv<n)v[++curv]=m;
    /*f(i,0,n)cout<<v[i]<<" ";cout<<endl;
    f(i,0,m)cout<<ea[i]<<" ";cout<<endl;
    f(i,0,m)cout<<ew[i]<<" ";cout<<endl;*/
 
    dijkstra(n, v, wt, ea, ew, mask, thrd);
 
    // Free memory
    cudaFree(wt);
    cudaFree(v);
    cudaFree(ea);
    cudaFree(ew);
    cudaFree(mask);
    cudaFree(thrd);
    
    ofstream out("kernel_time.txt");
    out<<"Total kernel time : "<<exec_time<<"\n";
    out.close();
 
    return 0;
}
