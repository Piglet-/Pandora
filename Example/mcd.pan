func mcd(a:int , b : int) : int
        i : int;
        if (b == 0) then
            return a;
        end
        i = mcd(b,a mod b);
        return i;
    end

    begin
        n: int;
        m : int;
        r : int;
        read n;
        read m;
        r = mcd(n,m);
        write r;
    end