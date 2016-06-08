int : func cualquiera(int : a, bool : b)
    int : c;
    c = a + 1;
end

struct persona has
    string: nombre;
    int: cedula;
end

struct otraPersona has
    persona *p;
    persona : p1;
end

union cosa like
    float: peso;
    array of int[2]: otrascCosas;
end 
  	
begin
    int **w;
    cosa : c;
    c.peso = "hoal ke ase";
    int : n;
    array of int[10][20] : a;
    n = 6;
end

