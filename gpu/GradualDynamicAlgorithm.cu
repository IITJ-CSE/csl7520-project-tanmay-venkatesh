#include <bits/stdc++.h>
using namespace std;
#define f(i, a, b) for (int i = a; i < b; ++i)

typedef struct edge
{
    int u, v, w;
} edge;

const int blockSize = 256;
int numBlocks;
float exec_time = 0;

bool edgeComparator(edge &e1, edge &e2)
{
    if (e1.u == e2.u)
        return e1.v < e2.v;
    return e1.u < e2.u;
}

__global__ void initialise(int n, int src, int ini_cost, int *wt, bool *mask)
{
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    for (int i = index; i < n; i += stride)
    {
        mask[i] = 0;
        if (i == src)
        {
            wt[i] = ini_cost;
        }
        else
        {
            wt[i] = 1000000000;
        }
    }
}

__global__ void threshold(int n, int *v, int *wt, int *ea, int *ew, bool *mask, int *thrd)
{
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    for (int i = index; i < n; i += stride)
    {
        if (!mask[i] && wt[i] < 1000000000)
        {
            for (int j = v[i]; j < v[i + 1]; ++j)
                if (!mask[ea[j]] && *thrd > wt[i] + ew[j])
                {
                    atomicExch(thrd, wt[i] + ew[j]);
                }
        }
    }
}

__global__ void relax2(int n, int *v, int *wt, int *ea, int *es, int *ew, bool *mask, int *thrd)
{
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    for (int i = index; i < v[n]; i += stride)
    {
        if (!mask[es[i]] && wt[es[i]] < *thrd)
        {
            //mask[es[i]]=1;
            if (wt[ea[i]] > wt[es[i]] + ew[i])
            {
                atomicExch(&wt[ea[i]], wt[es[i]] + ew[i]);
            }
        }
    }
    __syncthreads();
    for (int i = index; i < v[n]; i += stride)
    {
        if (!mask[es[i]] && wt[es[i]] < *thrd)
            mask[es[i]] = 1;
    }
}

__global__ void relax(int n, int *v, int *wt, int *ea, int *ew, bool *mask, int *thrd)
{
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    for (int i = index; i < n; i += stride)
    {
        if (!mask[i] && wt[i] < *thrd)
        {
            mask[i] = 1;
            for (int j = v[i]; j < v[i + 1]; ++j)
                if (wt[ea[j]] > wt[i] + ew[j])
                {
                    atomicExch(&wt[ea[j]], wt[i] + ew[j]);
                }
        }
    }
}

__global__ void find_p(int n, int *v, int *wt, int *ea, int *es, int *ew, int *p)
{
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    for (int i = index; i < v[n]; i += stride)
        if (wt[ea[i]] == wt[es[i]] + ew[i])
        {
            atomicExch(&p[ea[i]], es[i]);
        }
}

void dijkstra(int n, int *v, int *wt, int *ea, int *es, int *ew, int *p, int src = 0, int ini_cost = 0, bool find_par = 1)
{
    bool *mask;
    cudaMallocManaged(&mask, n * sizeof(bool));
    int *thrd;
    cudaMallocManaged(&thrd, sizeof(int));
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    cudaEventRecord(start);
    initialise<<<numBlocks, blockSize>>>(n, src, ini_cost, wt, mask);
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);
    float tmp = 0;
    cudaEventElapsedTime(&tmp, start, stop);
    exec_time += tmp;
    *thrd = ini_cost;
    int numBlocksE = (v[n] + blockSize - 1) / blockSize;
    while (*thrd < 1000000000)
    {
        *thrd = 1000000000;
        cudaEventCreate(&start);
        cudaEventCreate(&stop);
        cudaEventRecord(start);
        threshold<<<numBlocks, blockSize>>>(n, v, wt, ea, ew, mask, thrd);
        cudaEventRecord(stop);
        cudaEventSynchronize(stop);
        tmp = 0;
        cudaEventElapsedTime(&tmp, start, stop);
        exec_time += tmp;
        //cout<<*thrd<<"\n";
        cudaEventCreate(&start);
        cudaEventCreate(&stop);
        cudaEventRecord(start);
        relax<<<numBlocks, blockSize>>>(n, v, wt, ea, ew, mask, thrd);
        cudaEventRecord(stop);
        cudaEventSynchronize(stop);
        tmp = 0;
        cudaEventElapsedTime(&tmp, start, stop);
        exec_time += tmp;
    }

    if (find_par)
    {
        cudaEventCreate(&start);
        cudaEventCreate(&stop);
        cudaEventRecord(start);
        find_p<<<numBlocksE, blockSize>>>(n, v, wt, ea, es, ew, p);
        cudaEventRecord(stop);
        cudaEventSynchronize(stop);
        tmp = 0;
        cudaEventElapsedTime(&tmp, start, stop);
        exec_time += tmp;
    }

    cudaFree(mask);
    cudaFree(thrd);
}

__global__ void update_v(int n, int l, int inc, int *v)
{
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    for (int i = index; i <= n; i += stride)
    {
        if (i > l)
            v[i] += inc;
    }
}

__global__ void initialise_arr(int n, int val, int *arr)
{
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    for (int i = index; i <= n; i += stride)
    {
        arr[i] = val;
    }
}

__global__ void update_wt(int n, int *wt, int *tmp_wt)
{
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    for (int i = index; i <= n; i += stride)
    {
        wt[i] = min(wt[i], tmp_wt[i]);
    }
}

__global__ void store_ea_es_and_ew(int n, int idx, int *v, int *ea, int *es, int *ew, int *tmp_ea, int *tmp_es, int *tmp_ew)
{
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    for (int i = index; i < v[n]; i += stride)
    {
        if (i > idx)
        {
            tmp_ea[i] = ea[i];
            tmp_es[i] = es[i];
            tmp_ew[i] = ew[i];
        }
    }
}

__global__ void update_ea_es_and_ew(int n, int idx, int gap, int *v, int *ea, int *es, int *ew, int *tmp_ea, int *tmp_es, int *tmp_ew)
{
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    for (int i = index; i < v[n]; i += stride)
    {
        if (i >= idx)
        {
            ea[i] = tmp_ea[i + gap];
            es[i] = tmp_es[i + gap];
            ew[i] = tmp_ew[i + gap];
        }
    }
}

__global__ void find_edge_index(int n, int l, int r, int *v, int *es, int *ea, int *edge_idx)
{
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    for (int i = index; i < v[n]; i += stride)
    {
        if (es[i] == l && ea[i] == r)
            *edge_idx = i;
    }
}

void update_graph(int n, int l, int r, int w, int *v, int *ea, int *es, int *ew, int *edge_idx, bool *dec)
{
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
    exec_time += tmp;
    int *tmp_es, *tmp_ea, *tmp_ew;
    cudaMallocManaged(&tmp_es, (v[n] + 1) * sizeof(int));
    cudaMallocManaged(&tmp_ea, (v[n] + 1) * sizeof(int));
    cudaMallocManaged(&tmp_ew, (v[n] + 1) * sizeof(int));
    int idx = *edge_idx;
    *dec = (idx != -1 && w != -1 && w < ew[idx]);
    if (idx != -1)
    {
        if (w != -1)
            ew[idx] = w;
        else
        {
            cudaEventCreate(&start);
            cudaEventCreate(&stop);
            cudaEventRecord(start);
            store_ea_es_and_ew<<<numBlocksE, blockSize>>>(n, idx, v, ea, es, ew, tmp_ea, tmp_es, tmp_ew);
            cudaEventRecord(stop);
            cudaEventSynchronize(stop);
            tmp = 0;
            cudaEventElapsedTime(&tmp, start, stop);
            exec_time += tmp;
            cudaEventCreate(&start);
            cudaEventCreate(&stop);
            cudaEventRecord(start);
            update_v<<<numBlocks + 1, blockSize>>>(n, l, -1, v);
            cudaEventRecord(stop);
            cudaEventSynchronize(stop);
            tmp = 0;
            cudaEventElapsedTime(&tmp, start, stop);
            exec_time += tmp;
            cudaEventCreate(&start);
            cudaEventCreate(&stop);
            cudaEventRecord(start);
            update_ea_es_and_ew<<<numBlocksE, blockSize>>>(n, idx, 1, v, ea, es, ew, tmp_ea, tmp_es, tmp_ew);
            cudaEventRecord(stop);
            cudaEventSynchronize(stop);
            tmp = 0;
            cudaEventElapsedTime(&tmp, start, stop);
            exec_time += tmp;
        }
    }
    else
    {
        numBlocksE = v[n] / blockSize + 1;
        cudaEventCreate(&start);
        cudaEventCreate(&stop);
        cudaEventRecord(start);
        store_ea_es_and_ew<<<numBlocksE, blockSize>>>(n, v[l + 1] - 1, v, ea, es, ew, tmp_ea, tmp_es, tmp_ew);
        cudaEventRecord(stop);
        cudaEventSynchronize(stop);
        tmp = 0;
        cudaEventElapsedTime(&tmp, start, stop);
        exec_time += tmp;
        es[v[l + 1]] = l;
        ea[v[l + 1]] = r;
        ew[v[l + 1]] = w;
        cudaEventCreate(&start);
        cudaEventCreate(&stop);
        cudaEventRecord(start);
        update_v<<<numBlocks + 1, blockSize>>>(n, l, 1, v);
        cudaEventRecord(stop);
        cudaEventSynchronize(stop);
        tmp = 0;
        cudaEventElapsedTime(&tmp, start, stop);
        exec_time += tmp;
        cudaEventCreate(&start);
        cudaEventCreate(&stop);
        cudaEventRecord(start);
        update_ea_es_and_ew<<<numBlocksE, blockSize>>>(n, v[l + 1], -1, v, ea, es, ew, tmp_ea, tmp_es, tmp_ew);
        cudaEventRecord(stop);
        cudaEventSynchronize(stop);
        tmp = 0;
        cudaEventElapsedTime(&tmp, start, stop);
        exec_time += tmp;
    }
    cudaFree(tmp_ea);
    cudaFree(tmp_es);
    cudaFree(tmp_ew);
}

__global__ void find_min_d(int n, int u, int *v, int *wt, int *ea, int *es, int *ew, int *min_d)
{
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    for (int i = index; i < v[n]; i += stride)
        if (ea[i] == u && *min_d > wt[es[i]] + ew[i])
        {
            atomicExch(min_d, wt[es[i]] + ew[i]);
        }
}

__global__ void find_best_pred(int n, int u, int *v, int *wt, int *ea, int *es, int *ew, int *best_pred, int *min_d)
{
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    for (int i = index; i < v[n]; i += stride)
        if (ea[i] == u && *min_d == wt[es[i]] + ew[i])
        {
            atomicExch(best_pred, es[i]);
        }
}

__global__ void bfs(int n, int step, int *v, int *ea, int *p, int *mark)
{
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    for (int i = index; i < n; i += stride)
        if (mark[i] == -step)
        {
            for (int j = v[i]; j < v[i + 1]; ++j)
                if (!mark[j] && p[ea[j]] == i)
                {
                    mark[ea[j]] = mark[i] - 1;
                    if (!mark[n + 1])
                        mark[n + 1] = 1;
                }
        }
}

__global__ void pool_mark(int n, int val, int *mark)
{
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    for (int i = index; i <= n; i += stride)
        if (mark[i] < 0)
        {
            mark[i] = val;
        }
}

void paint_tree(int n, int root, int val, int *v, int *ea, int *p, int *mark)
{
    cudaEvent_t start, stop;
    float tmp = 0;
    mark[root] = -1;
    int step = 1;
    while (!mark[n + 1])
    {
        cudaEventCreate(&start);
        cudaEventCreate(&stop);
        cudaEventRecord(start);
        bfs<<<numBlocks, blockSize>>>(n, step, v, ea, p, mark);
        cudaEventRecord(stop);
        cudaEventSynchronize(stop);
        tmp = 0;
        cudaEventElapsedTime(&tmp, start, stop);
        exec_time += tmp;
        mark[n + 1] ^= 1;
        step++;
    }
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    cudaEventRecord(start);
    pool_mark<<<numBlocks, blockSize>>>(n, val, mark);
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);
    tmp = 0;
    cudaEventElapsedTime(&tmp, start, stop);
    exec_time += tmp;
}

void gradual_algo(int n, int l, int r, int w, int idx, int *v, int *wt, int *ea, int *es, int *ew, int *p, bool *dec)
{
    cudaEvent_t start, stop;
    float tmp;
    if (idx == -1 || *dec)
    {
        if (wt[r] < wt[l] + w)
            return;
        int *tmp_wt;
        cudaMallocManaged(&tmp_wt, n * sizeof(int));
        cudaEventCreate(&start);
        cudaEventCreate(&stop);
        cudaEventRecord(start);
        initialise_arr<<<numBlocks, blockSize>>>(n, 1000000000, tmp_wt);
        cudaEventRecord(stop);
        cudaEventSynchronize(stop);
        tmp = 0;
        cudaEventElapsedTime(&tmp, start, stop);
        exec_time += tmp;
        dijkstra(n, v, tmp_wt, ea, es, ew, p, r, wt[l] + w, 0);
        //cout<<"hggg "<<w<<endl;
        //f(i,0,n)cout<<tmp_wt[i]<<" ";cout<<endl;
        cudaEventCreate(&start);
        cudaEventCreate(&stop);
        cudaEventRecord(start);
        update_wt<<<numBlocks, blockSize>>>(n, wt, tmp_wt);
        cudaEventRecord(stop);
        cudaEventSynchronize(stop);
        tmp = 0;
        cudaEventElapsedTime(&tmp, start, stop);
        exec_time += tmp;
        cudaFree(tmp_wt);
        //f(i,0,n)cout<<wt[i]<<" ";cout<<endl;
        int numBlocksE = (v[n] + blockSize - 1) / blockSize;
        cudaEventCreate(&start);
        cudaEventCreate(&stop);
        cudaEventRecord(start);
        find_p<<<numBlocksE, blockSize>>>(n, v, wt, ea, es, ew, p);
        cudaEventRecord(stop);
        cudaEventSynchronize(stop);
        tmp = 0;
        cudaEventElapsedTime(&tmp, start, stop);
        exec_time += tmp;
    }
    else
    {
        if (p[r] != l)
            return;
        int numBlocksE = (v[n] + blockSize - 1) / blockSize;
        int *best_pred, *min_d, *mark;
        cudaMallocManaged(&mark, (n + 1) * sizeof(int));
        cudaMallocManaged(&best_pred, sizeof(int));
        cudaMallocManaged(&min_d, sizeof(int));

        cudaEventCreate(&start);
        cudaEventCreate(&stop);
        cudaEventRecord(start);
        initialise_arr<<<numBlocks, blockSize>>>(n + 1, 0, mark);
        cudaEventRecord(stop);
        cudaEventSynchronize(stop);
        tmp = 0;
        cudaEventElapsedTime(&tmp, start, stop);
        exec_time += tmp;
        paint_tree(n, r, 1, v, ea, p, mark);

        priority_queue<pair<int, int>, vector<pair<int, int>>, std::greater<pair<int, int>>> H;
        H.push({wt[r], r});
        while (!H.empty())
        {
            int u = H.top().second;
            H.pop();
            int old_val = wt[u];
            wt[u] = 1e9;

            // find pred_min(u)
            *best_pred = -1;
            *min_d = 1e9;
            cudaEventCreate(&start);
            cudaEventCreate(&stop);
            cudaEventRecord(start);
            find_min_d<<<numBlocksE, blockSize>>>(n, u, v, wt, ea, es, ew, min_d);
            cudaEventRecord(stop);
            cudaEventSynchronize(stop);
            tmp = 0;
            cudaEventElapsedTime(&tmp, start, stop);
            exec_time += tmp;
            cudaEventCreate(&start);
            cudaEventCreate(&stop);
            cudaEventRecord(start);
            find_best_pred<<<numBlocksE, blockSize>>>(n, u, v, wt, ea, es, ew, best_pred, min_d);
            cudaEventRecord(stop);
            cudaEventSynchronize(stop);
            float tmp = 0;
            cudaEventElapsedTime(&tmp, start, stop);
            exec_time += tmp;
            if (*best_pred != -1)
            {
                if (mark[*best_pred])
                    wt[u] = 1e9, H.push({wt[u], u});
                else
                {
                    mark[u] = 0;
                    wt[u] = *min_d;
                }
            }

            if (wt[u] != old_val)
            {
                for (int j = v[u]; j < v[u + 1]; ++j)
                {
                    if (p[ea[j]] == u)
                        H.push({wt[ea[j]], ea[j]});
                    else if (wt[u] + ew[j] < wt[ea[j]])
                        H.push({wt[u] + ew[j], ea[j]});
                }
            }
            else
            {
                paint_tree(n, u, 0, v, ea, p, mark);
            }
        }
        cudaFree(mark);
        cudaFree(best_pred);
        cudaFree(min_d);
    }
}

void process_queries(int n, int q, int *v, int *wt, int *ea, int *es, int *ew, int *p)
{

    while (q--)
    {
        int e, l, r, w = -1;
        cin >> e >> l >> r;
        l--;
        r--;
        if (e)
            cin >> w;
        int *edge_idx;
        bool *dec;
        cudaMallocManaged(&edge_idx, sizeof(int));
        cudaMallocManaged(&dec, sizeof(bool));
        *edge_idx = -1;
        update_graph(n, l, r, w, v, ea, es, ew, edge_idx, dec);
        /*
        f(i,0,20)cout<<v[i]<<" ";cout<<"\n";
        f(i,0,20)cout<<es[i]<<" ";cout<<"\n";
        f(i,0,20)cout<<ea[i]<<" ";cout<<"\n";
        f(i,0,20)cout<<ew[i]<<" ";cout<<"\n";
        */
        int idx = *edge_idx;
        cudaFree(edge_idx);
        gradual_algo(n, l, r, w, idx, v, wt, ea, es, ew, p, dec);
        cudaFree(dec);
        f(i, 0, n) cout << wt[i] << " ";
        cout << "\n";
        //dijkstra(n, v, wt, ea, ew, mask, thrd);
    }
}

int main(void)
{
    ios_base::sync_with_stdio(false);
    cin.tie(0);
    cout.tie(0);
    int n, m, l, r, w, q;
    cin >> n >> m >> q;

    numBlocks = (n + blockSize - 1) / blockSize;

    vector<edge> edges;
    f(i, 0, m) cin >> l >> r >> w, edges.push_back({l - 1, r - 1, w});
    sort(edges.begin(), edges.end(), edgeComparator);

    int *wt, *p, *v, *es, *ea, *ew;

    // Allocate Unified Memory – accessible from CPU or GPU
    cudaMallocManaged(&wt, n * sizeof(int));
    cudaMallocManaged(&v, (n + 1) * sizeof(int));
    cudaMallocManaged(&p, (n + 1) * sizeof(int));
    cudaMallocManaged(&es, (m + q) * sizeof(int));
    cudaMallocManaged(&ea, (m + q) * sizeof(int));
    cudaMallocManaged(&ew, (m + q) * sizeof(int));

    int curv = 0;
    v[0] = 0;
    f(i, 0, m)
    {
        while (curv < edges[i].u)
            v[++curv] = i;
        ea[i] = edges[i].v;
        es[i] = edges[i].u;
        ew[i] = edges[i].w;
    }
    while (curv < n)
        v[++curv] = m;

    dijkstra(n, v, wt, ea, es, ew, p);
    f(i, 0, n) cout << wt[i] << " ";
    cout << endl;
    process_queries(n, q, v, wt, ea, es, ew, p);

    // Free memory
    cudaFree(wt);
    cudaFree(v);
    cudaFree(p);
    cudaFree(ea);
    cudaFree(es);
    cudaFree(ew);

    ofstream out("kernel_time.txt");
    out << exec_time;
    out.close();

    return 0;
}
