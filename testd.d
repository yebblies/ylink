
__gshared int global_shared;
int global_tls;
extern int global_extern;

extern(C) extern int _imp__blah();

public void func()
{
}

int main()
{
    __gshared int static_shared;
    static int static_tls;
    global_shared = global_tls + static_shared + static_tls;
    func();
    auto a = 1;
    auto b = a + 1;
    auto c = a + b + 1;
    _imp__blah();
    return c;
}
