volatile int a = 5;
volatile int b = 12;

int main()
{
  while(a > 0){
    a -= 1;
    if(b>=a){
      b += a;
    }
  }
  return b;
}
