func factorial(n : int, a : int) : int
        i : int;
        if( n == 0 ) then 
            return a;
        end
        return factorial(n-1, n * a);
end

begin
		n : int;
        m : int;
        read n;
        write factorial(n,1); 
end
