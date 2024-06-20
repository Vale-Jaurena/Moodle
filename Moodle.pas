program Moodle;
uses            
   crt, Dos, sysutils; 
Type
    S8=string[8];
    s30=string[30];
    tipo_dia_hora = string[22];
   
    tipo= (alumno,docente);
  
    PuntLis=^nodoVisitas;
   
    nodoVisitas=record
        Usuario:S8;
        Id_Act:integer;
        Fecha_hora:tipo_dia_hora;
        AntVisitUsuario:PuntLis;
        AntVisitAct:PuntLis;
    end;
    
    PuntAr=^nodoUsuarios;
    
    nodoUsuarios=record
        Usuario:S8;
        Clave:S8;
        ApellidoNombre:s30;
        Cargo:tipo;
        Visitas:PuntLis;
        menores:PuntAr;
        mayores:PuntAr;
    end;
    
    PuntLDV=^nodoActividades;
    
    nodoActividades= record
        Id_Act:integer;
        Titulo:s30;
        Descripcion:s30;
        Visitas:PuntLis;
        ant:PuntLDV;
        sig:PuntLDV;
    end;
    
    ArchUsuarios = record
        Usuario:S8;
        Clave:S8;
        ApellidoNombre:s30;
        Cargo:tipo;
    end;
    
    ArchActividades = record
        Id_Act:integer;
        Titulo:s30;
        Descripcion:s30;
    end;
    
    ArchVisitas = record
        Usuario:S8;
        Id_Act:integer;
        Fecha_hora:tipo_dia_hora;
    end;
    
    ArchUsu = file of ArchUsuarios;
    ArchAct = file of ArchActividades;
    ArchVisit = file of ArchVisitas;
function ahora_en_string():tipo_dia_hora;
var
    anio, mes, dia, diaSem, hora, minutos, segundos, centesimas : Word;
begin
    GetDate( anio, mes, dia, diaSem);
    GetTime(hora,minutos, segundos, centesimas);
    ahora_en_string := Format('%4.4d-%2.2d-%2.2d %2.2d:%2.2d:%2.2d %2.2d', [anio,mes,dia, hora, minutos, segundos, centesimas]);
end;
Function ExisteArchUsu (var RegistroUsuarios:ArchUsu): boolean;
Begin
      {$I-}
      reset(RegistroUsuarios);
      {$I+}
      ExisteArchUsu:=(IOResult = 0);
end;
Function ExisteArchAct (var RegistroAct:ArchAct): boolean;
Begin
      {$I-}
      reset(RegistroAct);
      {$I+}
      ExisteArchAct:=(IOResult = 0);
end;
Function ExisteArchVisit(var RegistroVisita:ArchVisit): boolean;
Begin
      {$I-}
      reset(RegistroVisita);
      {$I+}
      ExisteArchVisit:=(IOResult = 0);
End;
//Crea el nodo del arbol
Function NodoArbol (var AuxUsu:ArchUsuarios):PuntAr; 
Begin
    NodoArbol:=nil;
    new(NodoArbol);
    NodoArbol^.Usuario:= AuxUsu.Usuario;
    NodoArbol^.Clave:= AuxUsu.Clave;
    NodoArbol^.ApellidoNombre:= AuxUsu.ApellidoNombre;
    NodoArbol^.Cargo:= AuxUsu.Cargo;
    NodoArbol^.menores:= nil;
    NodoArbol^.mayores:= nil;
    NodoArbol^.Visitas:=nil;
end;

//Crea el nodo de la lista doble mente vinculada
Function NodoDoble (var AuxActividad:ArchActividades):PuntLDV;
Begin
    NodoDoble:=nil;
    new(NodoDoble);
    NodoDoble^.Id_Act:=AuxActividad.Id_Act;
    NodoDoble^.Titulo:= AuxActividad.Titulo;
    NodoDoble^.Descripcion:=AuxActividad.Descripcion;
    NodoDoble^.sig:=nil;
    NodoDoble^.ant:=nil;
    NodoDoble^.Visitas:=nil;
end;

//Crea nodo simple 
Function NodoSimple (var AuxVisita:ArchVisitas):PuntLis;
Begin
    NodoSimple:=nil;
    new(NodoSimple);
    NodoSimple^.Usuario:=AuxVisita.Usuario;
    NodoSimple^.Id_Act:=AuxVisita.Id_Act;
    NodoSimple^.Fecha_hora:=AuxVisita.Fecha_hora;
    NodoSimple^.AntVisitUsuario:=nil;
    NodoSimple^.AntVisitAct:=nil; 
end;
//Armo el arbol con los respectivos datos
Procedure ArmarArbol(Var Usuarios:PuntAr; NodoUsuario:PuntAr);
Begin
    If Usuarios = nil then
        Usuarios:=NodoUsuario
    Else
    Begin
        If (Usuarios^.Usuario > NodoUsuario^.Usuario) then
            ArmarArbol(Usuarios^.menores,NodoUsuario) //No contemplo Iguales ya que no hay dos usuarios iguales
        else
            ArmarArbol(Usuarios^.mayores,NodoUsuario);
    end;
end;
//Cargo las visitas en base a cada usuario 
Procedure VincularVisitasUsu(Var Visitas:PuntLis;cursor:PuntLis);
Begin
    cursor^.AntVisitUsuario:=Visitas;
    Visitas:=cursor;                      
End;
Procedure Recorrer_OrdenarVisitas(Var Visitas:PuntLis; cursor:PuntLis);
Begin
    If (Visitas = nil) or (Visitas^.Fecha_hora <= cursor^.Fecha_hora) then
    Begin
        cursor^.AntVisitAct:=Visitas;
        Visitas:=cursor;
    end
    else
         Recorrer_OrdenarVisitas(Visitas^.AntVisitAct,cursor);
End;
//Vinculo las visitas con cada Actividades
Procedure VincularVisitas_Act (Var Actividades:PuntLDV;cursor:PuntLis);
Begin
    If (Actividades <> nil) then
    Begin
        If (Actividades^.Id_Act = cursor^.Id_Act)  then
            Recorrer_OrdenarVisitas(Actividades^.Visitas,cursor)
        else
            VincularVisitas_Act (Actividades^.sig,cursor);//Cuando avanzo a la sig Actividades el nodo debe ser uno nuevo//ya que cambio de act
    End;
End;
//este solo sirve para el caso de que no haya visitas
Procedure CargarUsuarios(Var Usuarios:PuntAr; Var RegistroUsuarios:ArchUsu);
Var AuxUsu:ArchUsuarios; NodoUsuario:PuntAr;
Begin
    NodoUsuario:=nil;
    reset(RegistroUsuarios);
    While not (eof(RegistroUsuarios)) do
    Begin
        Read(RegistroUsuarios,AuxUsu);
        NodoUsuario:=NodoArbol(AuxUsu);
        ArmarArbol(Usuarios,NodoUsuario);
    End;
    close(RegistroUsuarios);
End;
Function DevolverUsuario(Usuarios:PuntAr; nombreBuscado:String ): PuntAr;
begin
    if (Usuarios<>nil) then 
    begin
        if(Usuarios^.Usuario = nombreBuscado) then 
            DevolverUsuario := Usuarios
        else 
        begin
            DevolverUsuario := DevolverUsuario(Usuarios^.menores, nombreBuscado);
            DevolverUsuario := DevolverUsuario(Usuarios^.mayores, nombreBuscado);
        end;
    end
    else
        DevolverUsuario:= nil;
end;
Procedure CargarVisitas (Var RegistroVisita:ArchVisit; Var Usuarios:PuntAr; Var Actividades:PuntLDV);
Var cursor:PuntLis; 
    AuxVisita:ArchVisitas;
    usuarioEncontrado: PuntAr;
Begin
    cursor:=nil;
    
    while not(eof(RegistroVisita)) do
    Begin
        read(RegistroVisita,AuxVisita);
        cursor:=NodoSimple(AuxVisita);
        usuarioEncontrado := DevolverUsuario(Usuarios, AuxVisita.Usuario);
        
        If (usuarioEncontrado<>nil) then
        Begin
            VincularVisitasUsu(usuarioEncontrado^.Visitas,cursor);
            VincularVisitas_Act(Actividades,cursor);
        end;
    end;
end;

//Esta lista se arma en base a como se guardo en el archivo, que fue desde el final al princio.
//Por eso siempre inserta en el principio
Procedure ArmarListaAct (Var Actividades:PuntLDV; Nodo:PuntLDV);
VAr Auxiliar:PuntLDV; 
Begin
    If (Actividades = nil) then
        Actividades:=Nodo
    Else
    Begin
        Auxiliar:=Actividades;
        Auxiliar^.Ant:=Nodo;
        Nodo^.sig:=Auxiliar;
        Actividades:=Nodo;
    End;
End;
//Leo Archivo y armo Lista Act.
Procedure CargarActividades(Var Actividades:PuntLDV;Var RegistroAct:ArchAct);
Var Nodo:PuntLDV;AuxActividad:ArchActividades; 
Begin
    reset(RegistroAct);
    
    While not (eof(RegistroAct)) do
    Begin
        Read(RegistroAct,AuxActividad);
        Nodo:=NodoDoble(AuxActividad);
        ArmarListaAct(Actividades,Nodo);
    end;
    close(RegistroAct);
End;
Procedure ArmarEstructura ( Var Usuarios:PuntAr; Var Actividades:PuntLDV;Var RegistroVisita:ArchVisit; Var RegistroAct:ArchAct; Var RegistroUsuarios:ArchUsu);
Begin
    Usuarios:=nil;
    Actividades:=nil;
    
    If (ExisteArchAct(RegistroAct)) and (ExisteArchUsu(RegistroUsuarios)) then
    Begin
        If (ExisteArchVisit(RegistroVisita)) then
        Begin
            Reset(RegistroVisita);
            CargarActividades(Actividades,RegistroAct);
            CargarUsuarios(Usuarios,RegistroUsuarios);
            CargarVisitas(RegistroVisita,Usuarios,Actividades);
            Close(RegistroVisita);
        end
        else
        Begin
            CargarActividades(Actividades,RegistroAct);
            CargarUsuarios(Usuarios,RegistroUsuarios);
        End;
    End
    Else
        If (ExisteArchUsu(RegistroUsuarios)) then
            CargarUsuarios(Usuarios,RegistroUsuarios);
    
End;
Procedure MostrarActividades (Actividades:PuntLDV; Numero:integer);
Begin
    If (Actividades <> nil) then
    Begin
        
        Writeln(Numero,'. ID: ',Actividades^.Id_Act,'.',Actividades^.Titulo);
        MostrarActividades(Actividades^.sig, Numero+1);
    End
    else
       Writeln('La lista de Actividades finalizo.');
       
End;
Procedure ImprimirDatos(Tipo:PuntAr; Actividades:PuntLDV);
Begin
    Writeln('Se ha ingresado correctamente, se mostraran sus datos:');
    Writeln(Tipo^.ApellidoNombre);
    Writeln('');
    Writeln('El perfil es: ', Tipo^.Cargo);
    Writeln('');
    Writeln(' ---- La lista de actividades ----  ');
    MostrarActividades(Actividades,1);
End;
Function BuscaAct ( Identificador:integer; Actividades:PuntLDV): PuntLDV;
Begin
    If (Actividades <> nil ) then
    Begin
        If (Actividades^.Id_Act = identificador ) then
            BuscaAct:=Actividades
        else
           BuscaAct:= BuscaAct(Identificador,Actividades^.sig);
    End
    Else
        BuscaAct:=nil;
End; 
Function NuevaVisita(Id_Act:Integer; Usuario:String):PuntLis;
Begin
    New(NuevaVisita);
    NuevaVisita^.Id_Act:=Id_Act;
    NuevaVisita^.Usuario:=Usuario;
    NuevaVisita^.Fecha_Hora:=ahora_en_string();
    NuevaVisita^.AntVisitUsuario:=nil;
    NuevaVisita^.AntVisitAct:=nil;
end;
//Opcion 1 del menu Alumno
Procedure VisitarActividades (Var Actividades:PuntLDV; Var Usuarios:PuntAr;cursor:PuntLis);
Var Identificador:Integer; NodoNuevoVisita:PuntLis; ActEncontrada:PuntLDV;
Begin
    NodoNuevoVisita:=nil;
    Writeln('Ingrese el id de la Actividades: ');
    Readln(Identificador);
    if (Identificador <> -1 ) then
    Begin
        ActEncontrada:=BuscaAct(Identificador,Actividades);
        If (ActEncontrada <> nil) Then
        Begin
            Writeln('La descripcion de dicha Actividades es: ');
            Writeln(ActEncontrada^.Descripcion);
            NodoNuevoVisita:=NuevaVisita(Identificador,Usuarios^.Usuario);
            VincularVisitasUsu(Usuarios^.Visitas,NodoNuevoVisita);
            VincularVisitas_Act (Actividades,NodoNuevoVisita);
            Writeln('Para confirmar y volver a las opciones del menu presione cualquier tecla: ');
            Readkey;
        End 
        else
        Begin
            Writeln('La Actividades No fue encontrada');
            Writeln('Si desea seguir cargando ingrese un nuevo id de Actividades,  ');
            Writeln('sino simplemente coloque -1:');
            writeln('');
            Readln(identificador);
        End;
    End;
End;
//Armar menu, nivel 2 
Procedure MenuAlumno ( Var Actividades:PuntLDV; Var Usuarios:PuntAr;cursor:PuntLis);
Var opcion:Integer;
Begin
    opcion:=1;
    While (opcion>= 1) and (opcion < 2) do
    Begin
       
        ImprimirDatos(Usuarios,Actividades);
        Writeln('Seleccione una opcion del menu:' );
        Writeln('1-Visitar una Actividades: ');
        Writeln('2-Finaliza La sesion y vuelve al menu anterior:');
        Readln(opcion);
    
        Case opcion of
       
            1:VisitarActividades(Actividades,Usuarios,cursor);
        End;
    End;
    
    If (opcion > 3) then
    Begin
        Writeln('La opcion es invalida, vuelva a ingresar:');
        Readln(opcion);
    End;    
        
End;
Function NuevoNodoLDV(Titulo,Descripcion:String):PUntLDV;
Begin
    NuevoNodoLDV:=nil;
    New(NuevoNodoLDV);
    NuevoNodoLDV^.Titulo:=Titulo;
    NuevoNodoLDV^.Descripcion:=Descripcion;
    NuevoNodoLDV^.Id_Act:=0;// aca queda cero,se modifica en IngresarActNueva
    NuevoNodoLDV^.sig:=nil;
    NuevoNodoLDV^.ant:=nil;
    NuevoNodoLDV^.Visitas:=nil;
End;
//Inserto una nueva act. al final
Procedure InsertarEnActividades(Var Actividades:PuntLDV; Ayudante:PuntLDV; Var Cant:Integer);
Begin
    If (Actividades <> nil) then
    Begin
        If (Actividades^.sig <> nil) then
        Begin
            Cant:=Cant + 1;
            InsertarEnActividades(Actividades^.sig,Ayudante,Cant);
        End
        Else
        Begin
            Cant:=Cant + 1;
            Actividades^.sig:=Ayudante;
            Ayudante^.ant:=Actividades;
        End;
    End
    else
        Actividades:=Ayudante;
End;       
//Creo nodo,asigno informacion y lo inserto. Opcion 1 docente
Procedure IngresarActNueva (Var Actividades:PuntLDV); 
Var Ayudante:PuntLDV; Titulo,Descripcion:string;Cant:Integer;
Begin
    Cant:=0;
    Writeln('Para el ingreso de una nueva Actividades se piden los siguientes datos: Titulo,Descripcion.  ');
    Writeln('Título: ');
    Readln(Titulo);
    Writeln('Descripción:');
    Readln(Descripcion);
    
    Ayudante:=NuevoNodoLDV(Titulo,Descripcion);
   
    InsertarEnActividades(Actividades,Ayudante,Cant);
    Ayudante^.Id_Act:=Cant + 1;
end;
//Opcion 2 de Docente
Procedure ModificarTitulo(var Actividades:PuntLDV);
Var identificador:Integer; NuevoT:string;NodoAux:PuntLDV;
Begin
    WriteLn('Igrese el id de la Actividades que desea Modificar: ');
    Readln(Identificador);
    NodoAux:=BuscaAct(Identificador,Actividades);
    If (NodoAux <> nil) Then
    Begin
        Writeln('Ingrese el Nuevo titulo:'); 
        Readln(NuevoT);
        NodoAux^.Titulo:=NuevoT;
        MostrarActividades(Actividades, 1); 
    end
    else
        writeln('El id de la act no fue encontrado:');
End;
//Opcion 3 del Docente
Procedure ModificarDescripcion(var Actividades:PuntLDV);
Var Identificador:integer; NuevaDes:String; NodoAux:PuntLDV;
Begin
    WriteLn('Igrese el id de la Actividades que desea Modificar: ');
    Readln(Identificador);
    NodoAux:=BuscaAct(Identificador,Actividades);
    If (NodoAux <> nil) Then
    Begin
        Writeln('Ingrese la Nuevo descripcion:'); 
        Readln(NuevaDes);
        NodoAux^.Descripcion:=NuevaDes; 
        MostrarActividades(Actividades,1); 
    end
    else
        writeln('El id de la act no fue encontrado:');
End;
//Desvincular El nodo que debo insertar
Procedure  DesvincularNodo (Var Actividades:PuntLDV; Var NodoDes:PuntLDV);
Begin

    If (Actividades^.Id_Act = NodoDes^.Id_Act) then
    Begin
        Actividades:=NodoDes^.sig;
        NodoDes^.sig:=nil;
    End
    else
        desvincularnodo (actividades^.sig,NodoDes);
End;
Procedure InsertarNodo (Var Actividades:PuntLDV; Pos:Integer; NodoDes:PuntLDV);
var aux:Integer; PunteroAux:PuntLDV;
Begin
    aux:=1;
    PunteroAux:=nil;
   
    If (1 <> Pos) then
   Begin
        PunteroAux:=Actividades;
        While (aux <> Pos) and (PunteroAux^.sig <> nil ) do
        Begin
            aux:=aux+1;
            PunteroAux:=PunteroAux^.sig;
        end;
        If (PunteroAux^.sig <> nil)  and (aux = pos) then //entra a esta condicion si laprimera se rompe
        Begin
            PunteroAux:=PunteroAux^.ant;
            NodoDes^.sig:=PunteroAux^.sig;
            NodoDes^.ant:=PunteroAux;
            PunteroAux^.sig:=NodoDes;
            NodoDes^.sig^.ant:=NodoDes;
        end
        else
        Begin
            If (PunteroAux^.sig = nil) then
            begin
                PunteroAux^.sig:=NodoDes;
                NodoDes^.ant:=PunteroAux;
            end;
            
        end;
    End
    else
     Begin
        NodoDes^.sig:=Actividades;
        NodoDes^.sig^.ant:=NodoDes;
        Actividades:= NodoDes;
    End;
end;    
Function EncontrarLaPosAct(Actividades:PuntLDV;NodoDes:PuntLDV):Integer;
Begin
   
    If (Actividades<> Nil ) then
    Begin
        If (Actividades^.Id_Act <> NodoDes^.Id_Act) then
            EncontrarLaPosAct:=1 + EncontrarLaPosAct(Actividades^.sig,NodoDes)
        else
            EncontrarLaPosAct:= 1;
    end;
end;
Procedure OrdenarActividades (Var Actividades:PuntLDV);
Var Identificador,Pos,PosDistinta:Integer; NodoDes:PuntLDV;
Begin
    Identificador:=0;
    Pos:=0;
    Writeln('Ingrese el id de la Actividades que desea cambiar la posicion y luego la posicion donde desea colocarla: ');
    Writeln('ID de la Act. que desea mover: ');
    Readln(Identificador);
    Writeln('Posicion donde desea moverla: ');
    Readln(Pos);
    NodoDes:=BuscaAct(Identificador, Actividades);
    
    PosDistinta:=EncontrarLaPosAct(Actividades,NodoDes) ;
    If (Pos <> PosDistinta) then
    Begin
        DesvincularNodo(Actividades,NodoDes);
        InsertarNodo(Actividades,Pos,NodoDes);
    end;
   
end;
// Mientras el puntero visitas no sea nil va a ir contando las visitas
Function CantVisitas (Visitas:PuntLis):Integer;
Begin
    If (Visitas = Nil) then
        CantVisitas:=0
    Else
        CantVisitas:= 1 + CantVisitas(Visitas^.AntVisitAct) 
End;
//Compara que Actividades tiene mas visitas
Procedure MayorVisitaAct(Actividades:PuntLDV; Var Aux:Integer;Var Puntero:PuntLDV);
Var Aux2:Integer;
Begin
    If (Actividades <> nil) Then
    Begin
        Aux2:=CantVisitas(Actividades^.Visitas);
        If (Aux2 >= Aux ) then//Los aux comparan cantidad, y el puntero me dice que act es
        Begin
           Aux:=Aux2;
           Puntero:=Actividades;
        End;
        
        MayorVisitaAct(Actividades^.sig,Aux,Puntero);  
    End;
   
 End;
Procedure MostrarVisitaDestacada (Var Actividades:PuntLDV);
Var Aux:Integer; Puntero:PuntLDV;
Begin
    IF (Actividades<> nil) then
        Aux:=CantVisitas(Actividades^.Visitas);
    Puntero:=nil;
    MayorVisitaAct(Actividades,Aux,Puntero);
 
    If (Puntero <> nil ) then
    Begin
        Writeln('La Actividades mas visitada fue: ',Puntero^.Titulo);
        Writeln('Y el total de visitas fue: ',Aux);
    End
    else 
        Writeln('La Actividad no existe');
End;
//Cuenta los nodos de visita
Function AlumnoDestacado (Visitas:PuntLis):Integer;
Begin
    If (Visitas = nil ) then
        AlumnoDestacado:=0
    Else
        AlumnoDestacado:= 1 + AlumnoDestacado(Visitas^.AntVisitUsuario);
End;
//Encuentro el alumno con mayor visitas
Procedure EncontrarAlumnoMayorVisitas (Usuarios:PuntAr;var Alumno:PuntAr;var TotalVisit:Integer);
Var AuxMen,AuxMay:Integer; AlumnoAuxMen,AlumnoAuxMay:PuntAr;
Begin
    
    If (Usuarios <> nil) then
    Begin
        If (Usuarios^.Cargo <>  docente ) then
        Begin
            EncontrarAlumnoMayorVisitas(Usuarios^.menores,AlumnoAuxMen,AuxMen);
            EncontrarAlumnoMayorVisitas(Usuarios^.mayores,AlumnoAuxMay,AuxMay);
            TotalVisit:=AlumnoDestacado(Usuarios^.Visitas);
            Alumno:=Usuarios;
            
            If (TotalVisit < AuxMen) then
            Begin
                TotalVisit:= AuxMen;
                Alumno:=AlumnoAuxMen;
            end;
            
            If(TotalVisit < AuxMay) then
            Begin
                TotalVisit:=AuxMay;
                Alumno:=AlumnoAuxMay;
            end;
        End
        Else
        Begin
            EncontrarAlumnoMayorVisitas(Usuarios^.menores,AlumnoAuxMen,AuxMen);
            EncontrarAlumnoMayorVisitas(Usuarios^.mayores,AlumnoAuxMay,AuxMay);
            If (AuxMay < AuxMen) then
            Begin
                Alumno:=AlumnoAuxMen;
                TotalVisit:= AuxMen;
            End
            else
            Begin
                TotalVisit:=AuxMay;
                Alumno:=AlumnoAuxMay;
            End;
        end;
    End
    Else
    Begin
        TotalVisit:=0;
        Alumno:=nil;
    End; 
end;
Procedure AlumnoMayorVisitas (Usuarios:PuntAr);
Var TotalVisit:Integer; Alumno:PuntAr;
Begin
    Alumno:=nil;
    If (Usuarios^.Visitas <> nil) then
    Begin
        EncontrarAlumnoMayorVisitas (Usuarios,Alumno,TotalVisit);
        Writeln('El alumno con mayor visitas fue: ', Alumno^.ApellidoNombre);
        Writeln('El total de visitas fue:', TotalVisit);
    End
    else
        Writeln('No existen Actividades.');
End;
//Armar menu Docente,nivel 2
Procedure MenuDocente(Var Actividades:PuntLDV; Var Usuarios:PuntAr);
Var opcion:Integer;
Begin
    opcion:=1;
    While (opcion>= 1) and (opcion< 7) do 
    Begin
        ImprimirDatos(Usuarios,Actividades);
        Writeln('Seleccione una opcion del menu: ');
        Writeln('1-Agregar Una Actividades Nueva: ');
        Writeln('2-Modificar el titulo de una Actividades: ');
        Writeln('3-Modificar descripcion de una Actividades:');
        Writeln('4-Ordenar una Actividades: ');
        Writeln('5-Mostrar la Actividades mas visitada: ');
        Writeln('6-Mostrar el alumno que mas visita las Actividades y en que cantidad:');
        Writeln('7-Vover al menu anterior:');
        ReadLn(opcion);
        Clrscr;
        Case opcion of
       
            1:IngresarActNueva(Actividades);
            2:ModificarTitulo(Actividades);
            3:ModificarDescripcion(Actividades);
            4:OrdenarActividades(Actividades);
            5:MostrarVisitaDestacada (Actividades);
            6:AlumnoMayorVisitas(Usuarios);
        End;
    End;
    
    If (opcion < 1) or (opcion > 7) then
    Begin
        Writeln('La respuesta seleccionada es incorrecta, selecciones una nueva:');
        Readln(opcion);
    End;
end;
Function VerificacionUsuario(Usuarios:PuntAr; Perfil:string): PuntAr;
Begin
    If(Usuarios <> nil) then
    Begin
        If (Usuarios^.Usuario = Perfil ) then
            VerificacionUsuario:= Usuarios
        else
        Begin
            If (Usuarios^.Usuario < Perfil) then
                VerificacionUsuario:=VerificacionUsuario(Usuarios^.mayores,Perfil)
            Else
                VerificacionUsuario:=VerificacionUsuario(Usuarios^.menores,Perfil);
        End;
    End
    Else
        VerificacionUsuario:=nil;
End;
Function ClaveCorrecta(Tipo:PuntAr; Password:String):PuntAr;
Var  Cant:integer;
Begin
    ClaveCorrecta:=nil;
    Cant:=0;
   if (Tipo <> nil) then
    Begin
        Cant:=Cant + 1;
        If (Tipo^.Clave = Password) then
            ClaveCorrecta:=Tipo
        Else
        Begin
            Writeln('La clave fue incorrecta,ingrese una nueva');
            Readln(Password);
            Cant:=Cant + 1;
            If (Tipo^.Clave = Password) then
            ClaveCorrecta:=Tipo;
        End;
       
    End;
    If (Cant = 2) and (ClaveCorrecta(Tipo,Password) = nil) then
        write('La clave se ingreso 2 veces, el cual es el tope. Debe volver a menu principal.')
end;
//El usuario se ingresa con su nombre y clave            
Procedure IngresarUsuario (var Actividades:PuntLDV; VAr Usuarios:PuntAr;cursor:PuntLis);
Var Perfil:string;Password, continuar:S8; UsuarioCorrecto:PuntAr; passwordCorrecta, verifica:boolean;
Begin
    verifica := false;
    continuar := 's';
    while ((verifica=false) and (continuar = 's'))  do begin
        Writeln('Ingrese el usuario: ');
        Readln(Perfil);
        UsuarioCorrecto :=VerificacionUsuario(Usuarios,Perfil);
        Writeln('Ingrese la clave: ');
        Readln(Password);
        passwordCorrecta := ClaveCorrecta(UsuarioCorrecto,Password)<>nil;
        
        if((UsuarioCorrecto<>nil) and (passwordCorrecta)) then begin
            If (UsuarioCorrecto^.Cargo = alumno) then
                MenuAlumno(Actividades,UsuarioCorrecto,cursor)
            Else
                MenuDocente(Actividades,UsuarioCorrecto);
            verifica:= true;
        end
        else begin
            if (UsuarioCorrecto = nil) then begin
                Writeln('El usuario ingresado es incorrecto,ingrese nuevamente. :');
            end;
            if (passwordCorrecta = false) then 
                Writeln('La clave es incorrecta, ingrese nuevamente. :');
                
            Writeln('Quiere volver a ingresarse? S/N');
            readln(continuar);
        end;
    end;        
    Clrscr;
 End;
//Creo el nodo y directamente pido los datos aca mismo
Function NuevoUsuario (NuevoUsu,NuevaClave:string):PuntAr;
Var ApellidoNombre:string; aux:tipo;  
Begin
    NuevoUsuario:=nil;
    New(NuevoUsuario);
    NuevoUsuario^.Usuario:=NuevoUsu;
    NuevoUsuario^.Clave:=NuevaClave;
    NuevoUsuario^.menores:=nil;
    NuevoUsuario^.mayores:=nil;
    NuevoUsuario^.Visitas:=nil;
    
    Writeln('Ingrese Apellido,Nombre: ');
    Readln(ApellidoNombre);
    NuevoUsuario^.ApellidoNombre:=ApellidoNombre;
    
    Writeln('Ingrese que tipo de perfil es docente o alumno: ');
    Readln(aux);
    If (aux = tipo(docente)) or (aux = tipo(alumno)) then 
        NuevoUsuario^.Cargo:=aux
    Else
    Begin
        Writeln('El perfil es incorrecto vuelva a ingresarlo:');
        Readln(aux);
    End;
End;
//Inserto al nuevo alumno, el ArmarArbol no puedo usarlo ya que depende del registro
Procedure InsertarEnArbol( Var Usuarios:PuntAr;Nuevo:PuntAr);
Begin
    If (Usuarios = nil) then
        Usuarios:=Nuevo
    Else
    Begin
        If (Usuarios^.Usuario < Nuevo^.Usuario) then
            InsertarEnArbol(Usuarios^.mayores,Nuevo)
        Else
            InsertarEnArbol(Usuarios^.menores,Nuevo);
    End;
End;
Procedure IngresarNuevoUsuario(Var Usuarios:PuntAr);
Var NuevoUsu,NuevaClave:S8; Nuevo:PuntAr;
Begin
    Nuevo:=nil;
    Writeln('Ingrese su nuevo nombre de usuario:');
    Readln(NuevoUsu);
    If (VerificacionUsuario(Usuarios,NuevoUsu) <> nil) then
    Begin
        Writeln('El usuario ingresado ya existe,por favor presiona cualquier tecla para volver al menu:');
        Readkey;
    End
    Else
    Begin
        Writeln('Ingrese una clave:');
        Readln(NuevaClave);
        Nuevo:=NuevoUsuario(NuevoUsu,NuevaClave);
        InsertarEnArbol(Usuarios,Nuevo);
       
    End;
End;
//Paso las visitas por alumno con todas sus respectivas  visitas a las Actividades
Procedure PasarListaSimple_Archivo (Var Visitas:PuntLis;Var RegistroVisita:ArchVisit);
Var auxiliar:ArchVisitas;
Begin
    If (Visitas <> nil ) then
    Begin
        PasarListaSimple_Archivo(Visitas^.AntVisitUsuario,RegistroVisita);
        auxiliar.Usuario:=Visitas^.Usuario;
        auxiliar.Id_Act:=Visitas^.Id_Act;
        auxiliar.Fecha_hora:=Visitas^.Fecha_hora;
        Write(RegistroVisita,auxiliar);
    End;

End;
//Guardo la lista del final al principio en el archivo
Procedure PasarListaLDV_Archivo (Var Actividades:PuntLDV; Var RegistroAct:ArchAct);
Var auxiliar:ArchActividades;
Begin
    If (Actividades <> nil) then
    Begin
        PasarListaLDV_Archivo(Actividades^.sig,RegistroAct);
        auxiliar.Id_Act:= Actividades^.Id_Act;
        auxiliar.Titulo:=Actividades^.Titulo;
        auxiliar.Descripcion:=Actividades^.Descripcion;
        Write(RegistroAct,auxiliar);
     End;
End;
Procedure PasarArbol_Archivo(Var Usuarios:PuntAr; Var RegistroUsuarios:ArchUsu; Var RegistroVisita:ArchVisit);
Var auxiliar:ArchUsuarios;
Begin
    If (Usuarios <> nil) then
    Begin
        auxiliar.Usuario:=Usuarios^.Usuario;
        auxiliar.Clave:=Usuarios^.Clave;
        auxiliar.ApellidoNombre:=Usuarios^.ApellidoNombre;
        auxiliar.Cargo:=Usuarios^.Cargo;
        Write(RegistroUsuarios,auxiliar);
        PasarListaSimple_Archivo(Usuarios^.Visitas,RegistroVisita);
        PasarArbol_Archivo(Usuarios^.menores,RegistroUsuarios,RegistroVisita);
        PasarArbol_Archivo(Usuarios^.mayores,RegistroUsuarios,RegistroVisita);
    End;
End;
Procedure PasarEstructuras_Archivos(Var Usuarios:PuntAr;Var Actividades:PuntLDV;Var RegistroVisita:ArchVisit;var RegistroAct:ArchAct;var RegistroUsuarios:ArchUsu );
Begin
   If (Actividades <> nil) and (Usuarios <> nil)    then
   Begin
        Rewrite(RegistroAct);
        Rewrite(RegistroUsuarios);
        Rewrite(RegistroVisita);
       
        PasarListaLDV_Archivo(Actividades,RegistroAct);
        PasarArbol_Archivo(Usuarios,RegistroUsuarios,RegistroVisita);
       
        Close(RegistroUsuarios);
        Close(RegistroVisita);
        Close(RegistroAct);
    End
    Else
    Begin
        If (Usuarios <> nil) then
        Begin
            Rewrite(RegistroUsuarios);
            PasarArbol_Archivo(Usuarios,RegistroUsuarios,RegistroVisita);
            Close(RegistroUsuarios);
        End;
    End;
    Writeln('El programa finalizo.😊');
End;
//Menu 1
Procedure MenuPrincipal (Var Usuarios:PuntAr; Var Actividades:PuntLDV;Var RegistroVisita:ArchVisit; Var RegistroAct:ArchAct; Var RegistroUsuarios:ArchUsu);
Var cursor:PuntLis;opcion:integer; 
Begin   
    cursor:=nil;
    opcion:=1;
    While ( opcion >= 1) and (opcion < 3) do 
    Begin
        writeln('Seleccione una opcion del menu: ');
        Writeln ('1-🏆Login:');
        Writeln('2-🎡Registrarse: ');
        Writeln('3-💙Salir del programa: ');
        Readln(opcion);
        Clrscr;
        Case opcion of 
            
            1:IngresarUsuario(Actividades,Usuarios,cursor);
            2:IngresarNuevoUsuario(Usuarios);
            3:PasarEstructuras_Archivos(Usuarios,Actividades,RegistroVisita,RegistroAct,RegistroUsuarios)
            else
                 Writeln('La opcion ingresada fue incorrecta, vuelva ingresar una nueva:');
        end;
    end;

End;
//Prog.Principal
Var Usuarios:PuntAr; Actividades:PuntLDV; RegistroVisita:ArchVisit;RegistroAct:ArchAct;RegistroUsuarios:ArchUsu; 
Begin
    assign(RegistroUsuarios,'/work/ValeriaJaurenaUsuarios111.Moodle.dat');
    assign(RegistroAct,'/work/ValeriaJaurenaActividades111.Moodle.dat');
    assign(RegistroVisita,'/work/ValeriaJaurenaVisitas111.Moodle.dat');
    ArmarEstructura(Usuarios, Actividades, RegistroVisita,RegistroAct,RegistroUsuarios);
    MenuPrincipal(Usuarios, Actividades, RegistroVisita,RegistroAct,RegistroUsuarios);
End.
