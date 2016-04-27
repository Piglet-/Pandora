-- Fibonacci

    func fibonacci(n : int) : int
        if (n == 0) then
            return 0;
        end
        if (n == 1) then 
            return 1;
        end
        return fibonacci(n-1) + fibonacci(n-2);
    end

    begin
        n : int;
        read n;
        write fibonacci(n);
    end
