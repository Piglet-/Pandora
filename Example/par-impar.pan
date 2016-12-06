bool : func impar(int:n);

bool : func par(int: n)
	if (n == 0) then 
		return true;
	end
	else
		if (n == 1) then
			return false;
		end
		else
			return impar(n-1);
		end
	end
end

bool : func impar(int:n)
	if (n == 0) then 
		return false;
	end
	else
		if (n == 1) then 
			return true;
		end
		else
			return par(n-1);
		end
	end
end

begin
	char : c;
	c = 'j';
	while (c == 'j') do
		write "jugar(j) o salir(s) ?";
		read c;
		if (c == 'j') then
			int : i;
			bool : b;
			write "inserte un número entero:";
			read i;
			b = impar(i);
			if (b) then
				write "El numero es impar";
			end
			else
				write "El numero es impar";
			end
		end
	end
	write "fin del juego.";
end