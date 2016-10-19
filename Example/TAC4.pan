int : func cualquiera(int : a, bool : b)
	    int : c;
	    c = a + 1;
	    a = 1;
        bool : n;
        while ((c>2) and (5>c) or (a<=5) or (not b)) do
            if (4<c) then
                a = 2;
            end
            if (n) then
                a = 1;
            end
            else
                a = 4;
            end
            a = a+1;
        end
    return c;
end

begin
    bool : n;
	int: a;
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