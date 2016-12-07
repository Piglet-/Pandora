int: func f1(int:a, bool:b);

int: func f2(int:a)
	int: b,c;
	b = a +2;
	c = f1(a,true);
	return c;
end

int: func f1(int:a, bool:b)
	return (a < 3);
end

begin
	int : a,r;
	r = f2(a);
    write "hola mundo";
    write "hola mundo";
    write "ola k ase";
end
    