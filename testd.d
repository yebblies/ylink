
__gshared int global_shared;
int global_tls;

void main()
{
    __gshared int static_shared;
    static int static_tls;
}
