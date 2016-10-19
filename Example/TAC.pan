int : func fu(var int: a, var int: b)
	int : t;
	t = a;
	a =b;
	b = t;
end

begin
   int : x;
   int : y;
   x = fu(x,y); 
end