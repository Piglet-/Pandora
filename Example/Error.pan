int : func factorial(int: n) 
        int : f, g; 
        f = 1;
        for(i from 1 to n with i+1) do 
            f = f * i;
            i = f + 1;
        end
        int : f;
        void : a;
        return f;
    end

    begin
        int : n;
        read m;
        write "hola mundo";
        write "hola mundo";
        write "ola k ase";
        write factorial(n);
    end