volatile int a = 3;

int main()
{
  for(int i = 0; i < 5; i++){
    a += 4;
  }
  return a;
}
