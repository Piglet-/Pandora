fwd bool : func impar(int:n);

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
	int : c;
	c = 1;
	bool : b1;
	while (b1) do
		write "jugar(1) o salir(2) ?";
		read c;
		if (c == 1) then
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
		else
			b1 = false;
			write "fin del juego.";
		end
	end
end