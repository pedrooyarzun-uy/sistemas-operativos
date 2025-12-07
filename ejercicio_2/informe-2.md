# Informe técnico ejercicio2.c

Desglose estructural
--------------------
`ejercicio_2/ejercicio2.c` arranca declarando tres constantes simbólicas para fijar el tamaño del problema: `PASAJEROS` (100 hilos lectores), `OFICINISTAS` (5 hilos escritores) y `CAMBIOS_POR_OFICINISTA` (3 escrituras consecutivas por oficinista). Estos valores definen los límites del sistema y evitan usar literales dispersos.

Sincronización del cartel
-------------------------
El tipo `bloqueo_cartel_t` encapsula el mutex y las dos variables de condición que modelan la política lectores-escritores:
- `mutex` protege todo el estado interno.
- `puede_leer` despierta lectores bloqueados cuando no hay escritores pendientes.
- `puede_escribir` despierta al escritor que sigue cuando el cartel queda libre.
- `lectores_activos`, `escritores_esperando` y `escritor_activo` guardan contadores/flags para decidir quién avanza.

Las funciones `comenzar_lectura`/`finalizar_lectura` y `comenzar_escritura`/`finalizar_escritura` operan exclusivamente sobre este tipo. En lectura, el bucle `while (escritor_activo || escritores_esperando > 0)` obliga a los pasajeros a esperar si hay un escritor ejecutando o en cola; ese segundo término otorga prioridad a los oficinistas para que no se queden esperando indefinidamente cuando haya un flujo constante de lectores. En escritura, `escritores_esperando` se incrementa antes de entrar al bucle de espera para que los lectores venideros respeten esa prioridad. Al terminar una escritura se decide a quién notificar: si queda otro escritor, se hace `pthread_cond_signal` sobre `puede_escribir`; si no, se libera a todos los lectores mediante `pthread_cond_broadcast`.

Datos de hilo
-------------
`datos_hilo_t` agrupa el `id` secuencial (se usa solo para los mensajes) y un puntero al único `bloqueo_cartel_t` del programa. Se pasa por dirección a cada `pthread_create`, así las rutinas pueden recuperar su identidad y el recurso compartido sin variables globales adicionales.

Rutinas de trabajo
------------------
- `rutina_pasajero`: invoca `comenzar_lectura`, imprime la observación y duerme entre 1 y 3 segundos (`demora_aleatoria(3)` devuelve un entero entre 1 y `max_segundos`, de ahí el `sleep`). Este delay se ejecuta mientras el lector mantiene su bloque compartido; luego llama `finalizar_lectura`.
- `rutina_oficinista`: usa un `for` de `CAMBIOS_POR_OFICINISTA` iteraciones. En cada vuelta toma la exclusión mutua con `comenzar_escritura`, imprime el cambio, demora hasta 5 segundos simulando la modificación, libera el bloqueo y finalmente duerme otro intervalo de hasta 5 segundos antes del próximo cambio. Esos dos `sleep` modelan el tiempo trabajando en el cartel y el tiempo preparando el siguiente aviso.

Función principal
-----------------
`main` crea una única instancia de `bloqueo_cartel_t`, la inicializa y siembra el generador con `srand(time(NULL))`. Luego declara los arreglos de `pthread_t` y `datos_hilo_t`. Los bucles de creación asignan `id = i + 1` a cada estructura de datos y pasan `&bloqueo` a todos los hilos: ese parámetro compartido es imprescindible porque las rutinas necesitan referenciar el mismo estado crítico.  
Tras lanzar a los 100 pasajeros y 5 oficinistas se procede a esperar con `pthread_join` en dos bucles separados para asegurar que todo el tráfico haya finalizado antes de destruir el bloqueo. El `return 0` confirma el fin exitoso del programa.

Ejecución recomendada
---------------------
```bash
cd ejercicio_2
gcc -pthread ejercicio2.c -o ejercicio2
./ejercicio2
```
La salida intercalará mensajes de pasajeros y oficinistas, pero gracias al protocolo lectores-escritores nunca se imprimirá una escritura mientras haya un lector activo, ni se permitirá que lectores nuevos entren si existen escritores pendientes. Al completarse las tres rondas de cada oficinista y tras la lectura de todos los pasajeros, el programa finaliza de forma limpia.
