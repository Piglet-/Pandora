fwd int : func factorialr(int: n, int:j, int: a);

int : func factoriali(int: n) 
    int : f, g, h, l, d, e; 
    f = 1;
    for(i from 1 to n with i+1) do 
        f = f * i;
    end
    return f;
end

int : func factorialr(int: n, int: j, int: a)
    int : i;
    if( n == 0 ) then 
        return a;
    end
    return factorialr(n-1, 1, n * a);
end

begin
    int : c;
    c = 1;
    bool : b;
    b = true;
    while (b) do
        write "recursivo(1), iterativo(2) o salir(3) ?";
        read c;
        if (c == 1) then
            int : i;
            int : f;
            write "inserte un número entero:";
            read i;
            f = factorialr(i,1,2);
            write "el factorial es: ";
            write f;
        end
        if (c == 2) then
            int : i;
            int : f;
            write "inserte un numero entero:";
            read i;
            f = factoriali(i);
            write "el factorial es: ";
            write f;
        end
        if (c==3) then
            write "fin del juego.";
            b = false;
        end
    end
    
end