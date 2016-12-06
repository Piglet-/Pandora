int : func factorialr(int: n, int: a);

int : func factoriali(int: n) 
    int : f, g; 
    f = 1;
    for(i from 1 to n with i+1) do 
        f = f * i;
    end
    return f;
end

int : func factorialr(int: n, int: a)
    int : i;
    if( n == 0 ) then 
        return a;
    end
    return factorialr(n-1, n * a);
end

begin
    char : c;
    c = 'r';
    while ((c == 'r') or (c == 'i')) do
        write "recursivo(r), iterativo(i) o salir(s) ?";
        read c;
        if (c /= 's') then
            int : i;
            int : f;
            write "inserte un número entero:";
            read i;
            if (c == 'r') then
                f = factorialr(i,1);
            end
            else
                f = factoriali(i);
            end
            write "el factorial es: ";
            write f;
        end
    end
    write "fin del juego.";
end