
struct persona has
    int: nombre;
    int: cedula;
    bool : mujer;
end

struct animal has
	int: name;
	int: ced;
	persona: type;
end


begin 
    persona : p;
    animal: a;
    int : n,m;
    p.cedula = 2;
    n = a.type.cedula;
end


