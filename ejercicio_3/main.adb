with Ada.Text_IO; use Ada.Text_IO;
with Ada.Numerics.Float_Random; use Ada.Numerics.Float_Random;

procedure Main is
   task type semaforo is
      entry inicializar (capacidad : Integer);
      entry p;
      entry v;
   end semaforo;

   task body semaforo is
      en_el_recurso : Integer := 0;
      cap_maxima    : Integer := 0;
   begin
      accept inicializar (capacidad : Integer) do
         cap_maxima := capacidad;
      end inicializar;

      loop
         select
            when en_el_recurso < cap_maxima =>
               accept p do
                  en_el_recurso := en_el_recurso + 1;
               end p;
         or
               accept v do
                  en_el_recurso := en_el_recurso - 1;
               end v;
         end select;
      end loop;
   end semaforo;

   sem_ordenie    : semaforo;
   sem_vacunacion : semaforo;
   sem_pasillo    : semaforo;
   sem_camiones   : semaforo;

   cant_camion1 : Integer := 0;
   cant_camion2 : Integer := 0;

   subtype id_vaca is Integer range 1 .. 100;

   task type vaca is
      entry iniciar (id : id_vaca);
   end vaca;

   task body vaca is
      mi_id : id_vaca;

      generador_vaca       : Generator;
      probabilidad_ordenie : Float;
      probabilidad_camion  : Float;

      procedure espera_aleatoria (max_seg : Duration) is
         factor_tiempo : Float;
      begin
         factor_tiempo := Random (generador_vaca);
         delay Duration (Float (max_seg) * factor_tiempo);
      end espera_aleatoria;

      procedure ordeniar is
      begin
         sem_ordenie.p;
         Put_Line ("La vaca" & id_vaca'Image (mi_id) &
                   " esta entrando al area de ordenie");
         espera_aleatoria (3.0);  -- hasta 3 segundos
         Put_Line ("La vaca" & id_vaca'Image (mi_id) &
                   " esta saliendo del area de ordenie");
         sem_ordenie.v;
      end ordeniar;

      procedure vacunar is
      begin
         sem_vacunacion.p;

         sem_pasillo.p;
         Put_Line ("La vaca" & id_vaca'Image (mi_id) &
                   " esta entrando al area de vacunacion");
         sem_pasillo.v;

         espera_aleatoria (2.0);

         sem_pasillo.p;
         Put_Line ("La vaca" & id_vaca'Image (mi_id) &
                   " esta saliendo del area de vacunacion");
         sem_pasillo.v;

         sem_vacunacion.v;
      end vacunar;

      procedure subir_camion is
      begin
         sem_camiones.p;

         probabilidad_camion := Random (generador_vaca);

         if (cant_camion1 < 50) and (cant_camion2 < 50) then
            if probabilidad_camion < 0.5 then
               cant_camion1 := cant_camion1 + 1;
               Put_Line ("La vaca" & id_vaca'Image (mi_id) &
                         " esta entrando al Camion 1");
            else
               cant_camion2 := cant_camion2 + 1;
               Put_Line ("La vaca" & id_vaca'Image (mi_id) &
                         " esta entrando al Camion 2");
            end if;
         elsif cant_camion1 < 50 then
            cant_camion1 := cant_camion1 + 1;
            Put_Line ("La vaca" & id_vaca'Image (mi_id) &
                      " esta entrando al Camion 1");
         else
            cant_camion2 := cant_camion2 + 1;
            Put_Line ("La vaca" & id_vaca'Image (mi_id) &
                      " esta entrando al Camion 2");
         end if;

         sem_camiones.v;
      end subir_camion;

      primero_ordenie : Boolean;
   begin
      accept iniciar (id : id_vaca) do
         mi_id := id;
      end iniciar;

      reset (generador_vaca, Integer (mi_id));

      probabilidad_ordenie := Random (generador_vaca);
      primero_ordenie := probabilidad_ordenie < 0.5;

      if primero_ordenie then
         ordeniar;
         vacunar;
      else
         vacunar;
         ordeniar;
      end if;

      subir_camion;
   end vaca;
   vacas : array (id_vaca) of vaca;

begin
   sem_ordenie.inicializar    (15);
   sem_vacunacion.inicializar (5);
   sem_pasillo.inicializar    (1);
   sem_camiones.inicializar   (1);


   for i in vacas'Range loop
      vacas (i).iniciar (i);
   end loop;

   null;
end Main;
