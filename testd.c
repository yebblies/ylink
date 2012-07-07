
extern int global_shared;
int global_tls;

int main()
{
    static int static_shared;
    __tls static int static_tls;
    return 0;
}
