int :func factorial(int: n)
        if( n == 0 ) then 
            return 1;
        end
        int : i;
        i = factorial(n-1);
        return n * i;
    end

    begin
        int : n;
        read n;
        write factorial(n); 
    end