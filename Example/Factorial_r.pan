func factorial(n : int) : int
        if( n == 0 ) then 
            return 1;
        end
        i = factorial(n-1);
        return n * i;
    end

    begin
        n : int;
        read n;
        write factorial(n); 
    end