with Ada.Text_IO;         use Ada.Text_IO;
with Ada.Calendar;        use Ada.Calendar;
with Ada.Numerics.Float_Random;
with Ada.Strings.Fixed;   use Ada.Strings.Fixed;

procedure Tambo is
   --  Generador de numeros aleatorios usado por todas las vacas.
   package Random_Float is new Ada.Numerics.Float_Random;

   --  Convierte el Id a texto sin espacios iniciales.
   function Texto_Id (Valor : Integer) return String is
     (Trim (Integer'Image (Valor), Ada.Strings.Fixed.Both));

   --  Objeto protegido que serializa el acceso al generador aleatorio.
   protected Randomes is
      function Aleatorio return Float;
   private
      Gen : Random_Float.Generator;
   end Randomes;

   protected body Randomes is
      function Aleatorio return Float is
      begin
         return Random_Float.Random (Gen);
      end Aleatorio;
   begin
      Random_Float.Reset (Gen, Integer (Seconds (Clock)) mod 10_000);
   end Randomes;

   --  Sala de ordene con capacidad maxima de 15 vacas a la vez.
   protected Sala_Ordene is
      entry Entrar_Ordene (Id : Integer);
      entry Salir_Ordene (Id : Integer);
   private
      En_Sala : Integer := 0;
   end Sala_Ordene;

   protected body Sala_Ordene is
      entry Entrar_Ordene (Id : Integer) when En_Sala < 15 is
      begin
         En_Sala := En_Sala + 1;
         Put_Line ("La vaca " & Texto_Id (Id) & " esta entrando al area de ordene");
      end Entrar_Ordene;

      entry Salir_Ordene (Id : Integer) when En_Sala > 0 is
      begin
         En_Sala := En_Sala - 1;
         Put_Line ("La vaca " & Texto_Id (Id) & " esta saliendo del area de ordene");
      end Salir_Ordene;
   end Sala_Ordene;

   --  Area de vacunacion: controla pasillo (capacidad 1) y cinco mangas FIFO.
   protected Area_Vacunacion is
      entry Entrar_Pasillo (Id : Integer; Token : out Integer);
      entry Salir_Manga (Id : Integer; Token : Integer);
   private
      Dentro_Mangas  : Integer := 0;
      Pasillo_Libre  : Boolean := True;
      Siguiente_Token : Integer := 1;
      Turno_Salida    : Integer := 1;
   end Area_Vacunacion;

   protected body Area_Vacunacion is
      entry Entrar_Pasillo (Id : Integer; Token : out Integer)
        when Pasillo_Libre and Dentro_Mangas < 5 is
      begin
         Pasillo_Libre := False;
         Token := Siguiente_Token;
         Siguiente_Token := Siguiente_Token + 1;
         Put_Line ("La vaca " & Texto_Id (Id) & " esta entrando al area de vacunacion");
         Dentro_Mangas := Dentro_Mangas + 1;
         Pasillo_Libre := True;
      end Entrar_Pasillo;

      entry Salir_Manga (Id : Integer; Token : Integer)
        when Pasillo_Libre and Token = Turno_Salida is
      begin
         Pasillo_Libre := False;
         Dentro_Mangas := Dentro_Mangas - 1;
         Turno_Salida := Turno_Salida + 1;
         Put_Line ("La vaca " & Texto_Id (Id) & " esta saliendo del area de vacunacion");
         Pasillo_Libre := True;
      end Salir_Manga;
   end Area_Vacunacion;

   --  Camiones: administra las dos unidades con 50 lugares cada una.
   protected Camiones is
      entry Subir (Id : Integer; Camion : out Integer);
   private
      Carga_1 : Integer := 0;
      Carga_2 : Integer := 0;
   end Camiones;

   protected body Camiones is
      entry Subir (Id : Integer; Camion : out Integer)
        when Carga_1 + Carga_2 < 100 is
      begin
         if Carga_1 < 50 then
            Carga_1 := Carga_1 + 1;
            Camion := 1;
         else
            Carga_2 := Carga_2 + 1;
            Camion := 2;
         end if;

         Put_Line
           ("La vaca " & Texto_Id (Id) &
            " esta entrando al Camion " & Texto_Id (Camion));
      end Subir;
   end Camiones;

   --  Cada vaca es una tarea que decide el orden de ordene/vacunacion y luego sube a un camion.
   task type Vaca (Id : Positive);

   task body Vaca is
      Primero_Ordene : constant Boolean := Randomes.Aleatorio < 0.5;

      --  Gestion del ingreso completo a la sala de ordene.
      procedure Ir_A_Ordene is
      begin
         Sala_Ordene.Entrar_Ordene (Id);
         delay Duration (Randomes.Aleatorio * 3.0);
         Sala_Ordene.Salir_Ordene (Id);
      end Ir_A_Ordene;

      --  Gestion de la vacunacion respetando tokens y pasillo comun.
      procedure Ir_A_Vacunacion is
         Token : Integer;
      begin
         Area_Vacunacion.Entrar_Pasillo (Id, Token);
         delay Duration (Randomes.Aleatorio * 2.0);
         Area_Vacunacion.Salir_Manga (Id, Token);
      end Ir_A_Vacunacion;
   begin
      if Primero_Ordene then
         Ir_A_Ordene;
         Ir_A_Vacunacion;
      else
         Ir_A_Vacunacion;
         Ir_A_Ordene;
      end if;

      declare
         Camion_Asignado : Integer;
      begin
         Camiones.Subir (Id, Camion_Asignado);
      end;
   end Vaca;

   type Vaca_Ref is access Vaca;
   type Arreglo_Vacas is array (Positive range <>) of Vaca_Ref;
   Vacas : Arreglo_Vacas (1 .. 100);

begin
   --  Creacion de las 100 tareas Vaca, una por cada identificador.
   for I in Vacas'Range loop
      Vacas (I) := new Vaca (I);
   end loop;
end Tambo;
