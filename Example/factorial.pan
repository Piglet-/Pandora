fwd int : func factorialr(int: n);

int : func factoriali(int: n) 
    int : f;
    int : i;
    i = 1;
    f = 1;
    while(i <= n) do 
        f = f * i;
        i = i + 1;
    end
    return f;
end

int : func factorialr(int: n)
    int : i;
    if( n == 0 ) then 
        return 1;
    end
    i = factorialr(n-1);
    return n * i;
end

begin
    int : c;
    c = 1;
    int : b;
    b = 1;
    while (b == 1) do
        write "recursivo(1), iterativo(2) o salir(3) ? \n";
        read c;
        if (c == 1) then
            int : i;
            int : f;
            write "inserte un numero entero: \n";
            read i;
            f = factorialr(i);
            write "el factorial es: ";
            write f;
            write "\n";
        end
        if (c == 2) then
            int : i;
            int : f;
            write "inserte un numero entero: \n";
            read i;
            f = factoriali(i);
            write "el factorial es: ";
            write f;
            write "\n";
        end
        if (c==3) then
            write "fin del juego.";
            b = 2;
        end
    end
    
end