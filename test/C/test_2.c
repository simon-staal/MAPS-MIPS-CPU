volatile int a = 2;

int main()
{
  for(int i = 0; i < 23; i+=2){
    a += 2*i;
  }
  return a;
}
