int : func cualquiera(int : a, bool : b)
    int : c;
    c = a + 1;
    a = 1;
    return c;
end

struct persona has
    string: nombre;
    int: cedula;
    bool : mujer;
end

struct otraPersona has
    persona @p;
    persona : p1;
end

union cosa like
    float: peso;
    array of int[2]: otrascCosas;
    otraPersona : persona;
end 
  	
begin
    int : @@w;
    int : m;
    @@w = 12;
    cosa : c;
    c.persona.p1.cedula = 20;
    persona : per;
    per.mujer = true;
    int : n;
    array of int[10][20][3] : a;
    bool : b1,b2;
    n = 3;
    c.peso = intToFloat(2);
    a[2][8][1+n] = 9;

    repeat 
        n = n +1;
        n = 2;
    until true
    
    n = cualquiera(n+1, false);
    b1 = (n > 5) and (n < 10);
    b2 = true;

    if ((true and b2) or b1)
        then
            int : g;
            g = n+1;
            repeat
                g = g+1;
            until per.mujer
        end
        else
            float : f;
            f = 2.0;
        end

    for (i from 0 to 4 with i+1) do 
        int : y;
        y = 9*3;
        y = i +y;
    end
end

