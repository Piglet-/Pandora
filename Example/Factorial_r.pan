func factorial(n : int) : int
        i : int;
        if( n == 0 ) then 
            return 1;
        end
        i = factorial(n-1);
        return n * i;
    end

    begin
        n : int;
        m : int;
        read n;
        m = factorial(n);
        write m;
    end