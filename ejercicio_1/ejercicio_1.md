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

vender producto
si el archivo está vacío informamos que no hay stock.
mapfile -t lee todas las líneas del archivo en un array lista_productos (una por índice).
IFS=' - ' read -r ... permite separar cada parte del string en variables (codigo, tipo, modelo, descripción, cantidad y precio).
usamos arreglos para preservar cada columna y poder recalcularlas al final.
for ... printf lista cada producto con su número (idx + 1), tipo, modelo, precio y stock.
guardamos la compra en un diccionario (declare -A carrito) donde la clave es el índice del producto y el valor la cantidad pedida.
Parámetros de la interacción:
- Número de producto: se valida que sea entero positivo dentro del rango y permite Enter para terminar la selección.
- Cantidad a comprar: debe ser entero > 0 y no puede superar el stock aún disponible (stock original menos lo ya agregado al carrito).
finalizada la carga, recorremos el carrito para calcular el subtotal (cantidad * precio), mostrar el resumen (tipo – modelo – cantidad – total) y acumular el total general.
actualizamos el archivo productos.txt reemplazando la cantidad con la nueva cantidad (stock actual menos lo vendido).
