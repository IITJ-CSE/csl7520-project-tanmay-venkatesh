import argparse
import os
import  subprocess

DEFAULT_ALGO = 2

algo_names = dict([
 (1,"Static Dijkstra"),
 (2,"Dynamic Dijkstra"),
 (3,"Static Belman-Ford"),
 (4,"Dynamic Belman-Ford"),
 (5,"Gradual Dynamic Algorithm")
])

def get_arguments():
   parser = argparse.ArgumentParser(usage='Profiles algorithm in terms of runtime on GPU and CPU againts test parameters')
   parser.add_argument('--algo',type= int ,default=DEFAULT_ALGO,help="ID of the algorithm to profile \n 1 -> Static Dijkstra \n 2 -> Dynamic Dijkstra\n 3 -> Static Belman-Ford\n 4 -> Dynamic Belman-Ford\n 5 -> Gradual Dynamic Algorithm")
   parser.add_argument('-n',type= int,help= 'Number of vertices in testcase (maximum 10^5)' )
   parser.add_argument('-m',type= int, help= 'Number of edges in testcase (maximum 5*10^5 , not more that n*n)')
   parser.add_argument('-q',type= int, help= "Number of queries (in case of a dynamic algorithm)",default=0)

   return parser

def prepare_testcase(n,m,q):
  print(n,m,q)
  #ps = subprocess.Popen(('ps', '-A'), stdout=subprocess.PIPE)
  #output = subprocess.check_output(('grep', 'process_name'), stdin=ps.stdout)
  #ps.wait()
  if not q:
     ps=subprocess.run([f'echo "{n} {m}" | ./build/tc_stat >./tc.txt'],shell=True,stderr=subprocess.DEVNULL)
     ps.check_returncode()
  else:
     ps=subprocess.run([f'echo "{n} {m} {q}" | ./build/tc_dyn >./tc.txt'],shell=True,stderr=subprocess.DEVNULL)
     ps.check_returncode()
     #ps=subprocess.run(["echo",f'{n} {m} {q}',"|","./build/tc_dyn",">./tc.txt"],shell=True) #,stderr=subprocess.DEVNULL)
     #print(ps.returncode,ps.stdout,ps.stderr)
     #ps.check_returncode()

def profile_cpu_version(algo):
  print(algo)
  print(f'./build/{algo}_CPU')
  ps = subprocess.run([f'./build/{algo}_CPU <tc.txt'],shell=True,stderr=subprocess.DEVNULL,stdout=subprocess.DEVNULL)
  ps.check_returncode()
  f= open('cpu_perf.txt','r')
  cputime= f.readline().split()
  cputime=''.join(cputime)
  cputime=float(cputime)
  f.close()
  return cputime

def profile_gpu_version(algo):
  ps = subprocess.run([f'./build/{algo}_GPU <tc.txt'],shell=True,stderr=subprocess.DEVNULL,stdout=subprocess.DEVNULL)
  ps.check_returncode()
  f= open('gpu_perf.txt','r')
  gputime= f.readline().split()
  gputime=''.join(gputime)
  gputime=float(gputime)
  f.close()
  return gputime


def compare_cpu_gpu(algo):
  cputime = profile_cpu_version(algo)
  gputime = profile_gpu_version(algo)
  return cputime,gputime

def check_opt(opt):
     assert opt.algo>=1 and opt.algo <=5
     assert opt.n <= 100000 and opt.n >= 0
     assert opt.m <= 500000 and opt.m >= 0
     assert opt.m >= opt.n-1 
     assert opt.m <= opt.n*opt.n
     assert opt.q <= 100 and opt.q >=0
     if (opt.algo ==3 or opt.algo==1) and (opt.q >0):
       print(f'{algo_names[opt.algo]} is a static algorithm, queries (-q) value will be ignored')
       opt.q = 0

if __name__ == '__main__':
   parser = get_arguments()
   opt = parser.parse_args()
   check_opt(opt)
   prepare_testcase(opt.n,opt.m,opt.q)
   algo= algo_names[opt.algo].split()
   algo=''.join(algo)
   cputime,gputime = compare_cpu_gpu(algo)
   #cleanup()
   print(algo_names[opt.algo]," performance comparison,")
   print(f'CPU Implementation : {cputime}')
   print(f'GPU Implementation : {gputime}')
