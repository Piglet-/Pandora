int: func sumArray(array of int[10] : n, array of int[10] : m) 
        int : a,b;
        b = 0;
        for(i from 1 to 10 with i+1) do 
            a = n[i] + m[i] ;
            b = b +a;
        end
        return b;
    end

    begin
        array of int[10] : n;
        array of int[10] : m;
        int : x;
        x = sumArray(n,m);
        write x;
    end