volatile int a = 5;
volatile int b = 12;

int main()
{
  for(int i=b; i>=5; i--)
  {
    a--;
  }
  return a;
}
