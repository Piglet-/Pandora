int : func factorial(int: n, int: a)
        int : i;
        if( n == 0 ) then 
            return a;
        end
        return factorial(n-1, n * a);
end

begin
		int : n,m;
        read n;
        write factorial(n,1); 
end
