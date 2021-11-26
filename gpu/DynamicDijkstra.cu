#include <bits/stdc++.h>
using namespace std;
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
    *thrd = 0;
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
 
__global__
void update_v(int n, int l, int inc, int *v){
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    for (int i = index; i <= n; i += stride){
        if(i>l)v[i]+=inc;
    }
}
 
__global__
void store_ea_es_and_ew(int n, int idx, int *v, int *ea, int *es, int *ew, int *tmp_ea, int *tmp_es, int *tmp_ew){
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    for (int i = index; i < v[n]; i += stride){
        if(i>idx){
            tmp_ea[i]=ea[i];
            tmp_es[i]=es[i];
            tmp_ew[i]=ew[i];
        }
    }
}
 
__global__
void update_ea_es_and_ew(int n, int idx, int gap, int *v, int *ea, int *es, int *ew, int *tmp_ea, int *tmp_es, int *tmp_ew){
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    for (int i = index; i < v[n]; i += stride){
        if(i>=idx){
            ea[i]=tmp_ea[i+gap];
            es[i]=tmp_es[i+gap];
            ew[i]=tmp_ew[i+gap];
        }
    }
}
 
__global__
void find_edge_index(int n, int l, int r, int *v, int *es, int *ea, int *edge_idx){
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    for (int i = index; i < v[n]; i += stride){
        //printf("%d %d\n",es[i],ea[i]);
        if(es[i]==l&&ea[i]==r)*edge_idx=i;
    }
}
 
void update_graph(int n, int l, int r, int w, int *v, int *ea, int *es, int *ew, int *tmp_ea, int *tmp_es, int *tmp_ew){
    int *edge_idx;
    cudaMallocManaged(&edge_idx, sizeof(int));
    *edge_idx=-1;
    int numBlocksE = (v[n] + blockSize - 1) / blockSize;
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    cudaEventRecord(start);
    find_edge_index<<<numBlocksE, blockSize>>>(n, l, r, v, es, ea, edge_idx);
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);
    float tmp = 0;
    cudaEventElapsedTime(&tmp, start, stop);
    exec_time+=tmp;
    int idx=*edge_idx;
    cudaFree(edge_idx);
    //cout<<idx<<endl;
    if(idx!=-1){
        if(w!=-1)ew[idx]=w;
        else{
            cudaEventCreate(&start);
            cudaEventCreate(&stop);
            cudaEventRecord(start);
            store_ea_es_and_ew<<<numBlocksE, blockSize>>>(n, idx, v, ea, es, ew, tmp_ea, tmp_es, tmp_ew);
            cudaEventRecord(stop);
            cudaEventSynchronize(stop);
            tmp = 0;
            cudaEventElapsedTime(&tmp, start, stop);
            exec_time+=tmp;
            cudaEventCreate(&start);
            cudaEventCreate(&stop);
            cudaEventRecord(start);
            update_v<<<numBlocks+1, blockSize>>>(n, l, -1, v);
            cudaEventRecord(stop);
            cudaEventSynchronize(stop);
            tmp = 0;
            cudaEventElapsedTime(&tmp, start, stop);
            exec_time+=tmp;
            cudaEventCreate(&start);
            cudaEventCreate(&stop);
            cudaEventRecord(start);
            update_ea_es_and_ew<<<numBlocksE, blockSize>>>(n, idx, 1, v, ea, es, ew, tmp_ea, tmp_es, tmp_ew);
            cudaEventRecord(stop);
            cudaEventSynchronize(stop);
            tmp = 0;
            cudaEventElapsedTime(&tmp, start, stop);
            exec_time+=tmp;
        }
    }
    else{
        numBlocksE = v[n]/ blockSize + 1;
        cudaEventCreate(&start);
        cudaEventCreate(&stop);
        cudaEventRecord(start);
        store_ea_es_and_ew<<<numBlocksE, blockSize>>>(n, v[l+1]-1, v, ea, es, ew, tmp_ea, tmp_es, tmp_ew);
        cudaEventRecord(stop);
        cudaEventSynchronize(stop);
        tmp = 0;
        cudaEventElapsedTime(&tmp, start, stop);
        exec_time+=tmp;
        es[v[l+1]]=l;
        ea[v[l+1]]=r;
        ew[v[l+1]]=w;
        cudaEventCreate(&start);
        cudaEventCreate(&stop);
        cudaEventRecord(start);
        update_v<<<numBlocks+1, blockSize>>>(n, l, 1, v);
        cudaEventRecord(stop);
        cudaEventSynchronize(stop);
        tmp = 0;
        cudaEventElapsedTime(&tmp, start, stop);
        exec_time+=tmp;
        cudaEventCreate(&start);
        cudaEventCreate(&stop);
        cudaEventRecord(start);
        update_ea_es_and_ew<<<numBlocksE, blockSize>>>(n, v[l+1], -1, v, ea, es, ew, tmp_ea, tmp_es, tmp_ew);
        cudaEventRecord(stop);
        cudaEventSynchronize(stop);
        tmp = 0;
        cudaEventElapsedTime(&tmp, start, stop);
        exec_time+=tmp;
    }
}
 
void process_queries(int n, int q, int *v, int *wt, int *ea, int* es, int *ew, bool *mask, int *thrd, int *tmp_ea, int *tmp_es, int *tmp_ew){
    while(q--){
        int e, l, r, w=-1;
        cin>>e>>l>>r;
        l--;
        r--;
        if(e)cin>>w;
        update_graph(n, l, r, w, v, ea, es, ew, tmp_ea, tmp_es, tmp_ew);
        dijkstra(n, v, wt, ea, ew, mask, thrd);
    }
}
 
int main(void)
{
    ios_base::sync_with_stdio(false);
    cin.tie(0);
    cout.tie(0);
    int n, m, l, r, w, q;
    cin>>n>>m>>q;
 
    numBlocks = (n + blockSize - 1) / blockSize;
 
    vector<edge> edges;
    f(i,0,m)cin>>l>>r>>w, edges.push_back({l-1, r-1, w});
    sort(edges.begin(), edges.end(), edgeComparator);
 
    int *wt, *v, *es, *ea, *ew, *thrd, *tmp_ea, *tmp_es, *tmp_ew;
    bool *mask;
 
    // Allocate Unified Memory – accessible from CPU or GPU
    cudaMallocManaged(&wt, n*sizeof(int));
    cudaMallocManaged(&v, (n+1)*sizeof(int));
    cudaMallocManaged(&es, (m+q)*sizeof(int));
    cudaMallocManaged(&ea, (m+q)*sizeof(int));
    cudaMallocManaged(&ew, (m+q)*sizeof(int));
    cudaMallocManaged(&tmp_es, (m+q)*sizeof(int));
    cudaMallocManaged(&tmp_ea, (m+q)*sizeof(int));
    cudaMallocManaged(&tmp_ew, (m+q)*sizeof(int));
    cudaMallocManaged(&mask, n*sizeof(bool));
    cudaMallocManaged(&thrd, sizeof(int));
 
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
 
    dijkstra(n, v, wt, ea, ew, mask, thrd);
    process_queries(n, q, v, wt, ea, es, ew, mask, thrd, tmp_ea, tmp_es, tmp_ew);
 
    // Free memory
    cudaFree(wt);
    cudaFree(v);
    cudaFree(ea);
    cudaFree(es);
    cudaFree(ew);
    cudaFree(tmp_ea);
    cudaFree(tmp_es);
    cudaFree(tmp_ew);
    cudaFree(mask);
    cudaFree(thrd);
    
    ofstream out("../kernel_perf.txt");
    out<<exec_time<<"\n";
    out.close();
 
    return 0;
}
