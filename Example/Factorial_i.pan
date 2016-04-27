-- Factorial iterativo

func factorial(n : int) : int
    f : int; 
    f = 1;
    for(i from 1 to n with i+1) do 
        f = f * i;
    end
    return f;
    end
end

begin
    n : int;
    read n;
    write factorial(n);
end