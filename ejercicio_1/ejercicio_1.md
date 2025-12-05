Creamos un loop infinito para mostrar el menu de opciones. 

crear usuario
guardamos el archivo usuarios.txt en la variable usuarios.
si el archivo no existe creamos el usuario admin por default
-f pregunta si el archivo exist y es un archivo (-e solo si existe)
-z verifica si una cadena está vacía
como usamos : para separar el nombre de la contraseña verificamos que el usuario no tenga :
verificamos que no exista el usuario
(-q de quiet, para que no imprima por pantalla las cosas que coincidan) ^ coincidencia al principio de la linea, el nuevo_usuario y los : para que sea commpleta (lucia: y no luciana)
```
echo "${nuevo_usuario}:${nueva_pass}" >> "$usuarios"
```
lo agrega al final del archivo

cambiar contraseña
verifica que el usuario exista
```
pass_actual=$(grep "^${usuario}:" "$usuarios" | cut -d':' -f2)
```
cut -> divide una linea en campos 
-d':' delimitador :
-f2 mostrame el segundo campo
si son diferentes no hago nada
verifico que no sea vacia
sed significa Stream EDitor.
-i viene de in-place (modificar el archivo directamente)
s/patrón_a_buscar/texto_de_reemplazo/


====== INGRESAR PRODUCTOS ========
```
if ! [[ "$cantidad" =~ ^[0-9]+$ ]]; then
```
=~ para comparar una cadena con una expresión regular
el + es por una o más repeticiones
$para que sean digitos hasta el final

```
codigo=$(echo "$tipo" | awk '{print toupper(substr($0,1,3))}')
```
awk sirve para recorrer archivos o cadenas y operar sobre líneas, columnas o texto.
substr($0,1,3) toma los primeros 3 caracteres de la línea.
toupper(...) los convierte a mayúsculas.

====== FILTRAR PRODUCTOS ======
```
if [ ! -s "$productos" ]; then
```
-s valida que exista y no esté vacío para evitar recorrer archivos vacíos.
`read -p "Ingrese tipo para filtrar (Enter para todos): "` permite ingresar el filtro opcional.
```
filtro_normalizado=$(echo "$filtro_tipo" | tr '[:upper:]' '[:lower:]')
```
con `tr` llevamos el texto a minúsculas y así comparamos sin depender de mayúsculas/minúsculas.
```
while IFS=' - ' read -r codigo tipo modelo descripcion cantidad resto
```
ajustamos `IFS` para separar cada columna según el formato de guardado y obtener cada campo con `read`.
`resto#\$ ` elimina el prefijo `$ `, dejando solo el valor del precio.
Si hay filtro, se compara la versión en minúsculas (`tipo_normalizado`) y se imprime con `printf` cada producto que coincide.
Cuando no encuentra coincidencias informa si no hay productos o si el tipo especificado no existe.

====== VENDER PRODUCTOS ======
si el archivo está vacío informamos que no hay stock.
```
while IFS= read -r linea; do ... lista_productos+=("$linea"); done < "$productos"
```
con este `while` cargamos cada línea en un array sin depender de `mapfile`, compatible con la versión de Bash 3.2 de macOS.
IFS=' - ' read -r ... permite separar cada parte del string en variables (codigo, tipo, modelo, descripción, cantidad y precio).
usamos arreglos para preservar cada columna y poder recalcularlas al final.
for ... printf lista cada producto con su número (idx + 1), tipo, modelo, precio y stock.
guardamos la compra en un array `carrito` donde el índice numérico coincide con el número de producto seleccionado y el valor es la cantidad pedida (compatible con Bash 3.2 sin arreglos asociativos).
Parámetros de la interacción:
- Número de producto: se valida que sea entero positivo dentro del rango y permite Enter para terminar la selección.
- Cantidad a comprar: debe ser entero > 0 y no puede superar el stock aún disponible (stock original menos lo ya agregado al carrito).
finalizada la carga, recorremos el carrito para calcular el subtotal (cantidad * precio), mostrar el resumen (tipo – modelo – cantidad – total) y acumular el total general.
actualizamos el archivo productos.txt reemplazando la cantidad con la nueva cantidad (stock actual menos lo vendido).

====== REPORTE CSV ======
```
mkdir -p "$datos_dir"
```
`-p` crea la carpeta Datos en el mismo directorio que el script (sin fallar si ya existe).
`echo "codigo,..." > "$datos_reporte"` pisa el archivo `Datos/datos.CSV` y escribe la fila de encabezados en formato CSV.
Volvemos a iterar el archivo con `while IFS=' - ' read -r ...` para recuperar cada campo y agregar todas las líneas del inventario al CSV.
```
printf "%s,%s,%s,%s,%s,%s\n" ... >> "$datos_reporte"
```
genera cada fila del CSV con código, tipo, modelo, descripción, stock y precio sin el símbolo `$`.
Si no se encontraron productos (p.ej. archivo vacío), queda solo el encabezado y se aclara en pantalla.
