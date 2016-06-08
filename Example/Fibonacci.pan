int : func fibonacci(int: n)
        int : i, j;
        if (n == 0) then
            return 0;
        end
        if (n == 1) then 
            return 1;
        end
        i = fibonacci(n-1);
        j = fibonacci(n-2);
        return i +j; 
    end

    begin
        int: n;
        read n;
        write fibonacci(n);
    end