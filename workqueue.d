
class WorkQueue(T)
{
    T[] files;

    bool empty()
    {
        return files.length == 0;
    }
    T pop()
    {
        auto r = files[0];
        files = files[1..$];
        return r;
    }
    void append(T filename)
    {
        files ~= filename;
    }
}
