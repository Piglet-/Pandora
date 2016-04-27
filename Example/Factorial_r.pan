-- Factorial recursivo

func factorial(n : int) : int
    if( n == 0 ) then 
        return 1;
    end
    return n * factorial(n-1);
end

begin
    int n;
    read n;
    write factorial(n);
end
