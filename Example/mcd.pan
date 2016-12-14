int: func mcd(int : a, int :b)
    if (b == 0) then
        return a;
    end
    return mcd(b,a mod b);
end

begin
    int : n;
    int : m;
    read n;
    write mcd(n,m);
end