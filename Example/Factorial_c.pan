func factorial(n : int, a : int) : int
        i : int;
        if( n == 0 ) then 
            return a;
        end
        i = factorial(n-1, n * a);
        return i;
    end

    begin
        n : int;
        m : int;
        read n;
        m = factorial(n,1);
        write m; 
    end