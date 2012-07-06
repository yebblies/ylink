
class Module
{
    string name;
    this(string name)
    {
        this.name = name;
    }
}

class DllModule : Module
{
    this(string name)
    {
        super(name);
    }
}
