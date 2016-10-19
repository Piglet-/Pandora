int : func cualquiera(int : a, bool : b)
	    int : c;
	    c = a + 1;
	    a = 1;
    return c;
end
begin

	int: a;
    bool : n;
    n = (7>2) and (5>6) or (7<=5) or (not true);
    if (4<3) then
    	a = 2;
    end
    if (n) then
    	a = 1;
    end
    else
    	a = 4;
    end

    while (n) do
    	a = a+1;
    end

    int: f;
    f = 3;

    repeat
    	f = a+1;
    until (5>4)

    for(i from 1 to f with i+1) do 
            f = f * i;
    end
    a = cualquiera( cualquiera(8,n), n);

end