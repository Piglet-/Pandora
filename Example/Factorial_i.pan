int : func factorial(int: n) 
        int : f, g; 
        f = 1;
        for(i from 1 to n with i+1) do 
            f = f * i;
        end
        return f;
    end

    begin
        int : n;
        read n;
        write factorial(n);
    end