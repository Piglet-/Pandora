func factorial(n : int) : int
        f : int; 
        f = 1;
        for(i from 1 to n with i+1) do 
            f = f * i;
        end
        return f;
    end

    begin
        n : int;
        m : int;
        read n;
        m = factorial(n);
        write m;
    end