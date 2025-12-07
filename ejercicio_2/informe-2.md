# Informe ejercicio2.c

Desglose estructural
--------------------
`ejercicio_2/ejercicio2_v2.c` define cuatro constantes para parametrizar la simulación: `CANT_PASAJEROS` y `CANT_OFICINISTAS` determinan cuántos hilos de cada tipo se lanzan, `LECTURAS_POR_PASAJERO` fija cuántas veces un mismo pasajero vuelve al cartel y `CAMBIOS_POR_OFICINISTA` establece cuántas publicaciones hace cada oficinista. La rutina auxiliar `esperar_aleatorio(maximo)` encapsula los `sleep` pseudo-aleatorios y al recibir 0 evita bloqueos innecesarios.

Sincronización y estado compartido
----------------------------------
La lógica de concurrencia se apoya en tres contadores globales (`lectores_actuales`, `escritor_activo` y `escritores_esperando`) protegidos por un único `pthread_mutex_t` (`mutex_control`) y una condición (`cond_sin_escritor`). Con estos elementos se implementa una variante del clásico protocolo lectores-escritores con prioridad a escritores:
- `inicio_lectura` espera mientras haya un escritor trabajando o en cola; una vez que ingresa incrementa `lectores_actuales`.
- `fin_lectura` decrementa el contador y, si es el último lector, hace `pthread_cond_broadcast` para liberar a escritores pendientes.
- `inicio_escritura` incrementa `escritores_esperando`, bloquea hasta que no haya lectores ni otro escritor, marca `escritor_activo = 1` y libera el mutex.
- `fin_escritura` deja `escritor_activo = 0` y emite un `broadcast` que permite tanto al próximo escritor como a todos los lectores competir nuevamente bajo las reglas anteriores.

La política "escritor preferido" garantiza que los oficinistas no se queden eternamente esperando cuando el cartel recibe un flujo constante de pasajeros, a costa de que los lectores puedan ver un retardo si se acumulan escrituras.

Rutinas de trabajo
------------------
Cada `rutina_pasajero` recibe un `hilo_info_t` con su `id` y ejecuta un bucle de `LECTURAS_POR_PASAJERO` iteraciones. En cada vuelta espera hasta 3 segundos, entra en la sección crítica de lectura, imprime el mensaje, mantiene la lectura otro intervalo aleatorio y libera el recurso. Así se modela un pasajero que hace varias consultas intercaladas.

`rutina_oficinista` sigue un patrón similar pero con `CAMBIOS_POR_OFICINISTA` iteraciones: se demora hasta 5 segundos fuera del cartel, toma la escritura exclusiva, anuncia el cambio, mantiene el bloqueo mientras trabaja y luego lo libera antes de volver a preparar el próximo aviso.

Función principal
-----------------
`main` inicializa el generador pseudoaleatorio, el mutex y la condición, y después crea los hilos de pasajeros y oficinistas cargando el número identificatorio correspondiente en arreglos de `hilo_info_t`. Los `pthread_join` aseguran que todo lector/escritor termine antes de destruir los objetos de sincronización, evitando carreras al finalizar el programa.

Analogía lectores-escritores
----------------------------
El cartel actúa como el recurso compartido del problema readers-writers clásico. Los pasajeros representan lectores: cualquier cantidad puede "mirar" simultáneamente mientras nadie escribe. Los oficinistas son los escritores: necesitan exclusión mutua porque alteran el contenido. La condición `cond_sin_escritor` hace de semáforo que solo se abre cuando no queda un escritor activo, y el contador `escritores_esperando` otorga prioridad a los escritores pendientes, equivalente a permitir que el "turno" de escritura se mantenga hasta que la cola quede vacía. De esta forma se asegura que la información publicada sea consistente y ningún pasajero lea un mensaje a medio actualizar.

Ejecución sugerida
------------------
```bash
cd ejercicio_2
gcc -pthread ejercicio2.c -o ejercicio2
./ejercicio2
```
La salida intercala los mensajes de 100 pasajeros y 5 oficinistas. Gracias al protocolo lectores-escritores empleado, nunca coinciden escrituras con lecturas activas y, cuando hay escritores esperando, los lectores ven bloqueada su entrada hasta mantener la coherencia del cartel.
