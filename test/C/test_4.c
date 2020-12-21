volatile int j = 5225;
volatile int n = 0;

int main()
{
    for (int m = 0; m <= 5; m++)
    {
        int n = j >> m;
    }
    return n;
}
