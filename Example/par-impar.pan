fwd int : func impar(int:n);

int : func par(int: n)
	if (n == 0) then 
		return 1;
	end
	else
		if (n == 1) then
			return 0;
		end
		else
			return impar(n-1);
		end
	end
end

int : func impar(int:n)
	if (n == 0) then 
		return 0;
	end
	else
		if (n == 1) then 
			return 1;
		end
		else
			return par(n-1);
		end
	end
end

begin
	int : c;
	c = 1;
	int : p;
	p = 1;
	while (p == 1) do
		write "jugar(1) o salir(2) ?";
		read c;
		if (c == 1) then
			int : i;
			int : b;
			write "inserte un número entero:";
			read i;
			b = impar(i);
			if (b == 1) then
				write "El numero es impar\n";
			end
			if (b == 0) then
				write "El numero es par\n";
			end
		end
		if (c == 2) then
			p = 0;
			write "fin del juego.";
		end
	end
end