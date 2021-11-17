from random import randint
from collections import defaultdict

n, m = input().split()
n, m = int(n), int(m)
print(n, m)
mp=defaultdict(int)
for i in range(1,n):
    mp[(i, i+1)]=1
    print(i, i+1, randint(1,20))
for i in range(m-n+1):
    u=randint(1,n)
    v=randint(1,n)
    if u==v or mp[(u, v)]==1:
        i-=1
        continue
    mp[(u, v)]=1
    print(u, v, randint(1,20))
