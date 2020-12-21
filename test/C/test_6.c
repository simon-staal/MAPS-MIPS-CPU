volatile int array[5] = {3, 4, 7, 2, 1};

int main()
{
    int maximum = array[0];
    for( int i=1;i<5;i++ )
    if( array[i] > maximum )
    {
      maximum = array[i];
      return maximum;
    }
}
