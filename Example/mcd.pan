-- Algoritmo de euclides

func mcd(a : int, b : int) : int
    if (b == 0) then
        return a;
    end
    return mcd(b,a mod b);
end

begin
    n : int;
    m : int;
    read n;
    read m;
    write mcd(n,m);
end
