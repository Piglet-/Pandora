-- Factorial recursivo de cola

func factorial(n : int, a : int) : int
    if( n == 0 ) then 
        return a;
    end
    return factorial(n-1, n * a);
end

begin
    int n;
    read n;
    write factorial(n,1); 
end